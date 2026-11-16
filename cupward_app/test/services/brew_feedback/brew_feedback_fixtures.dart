import 'dart:async';

import 'package:cupward/models/brews/brew_phase_record.dart';
import 'package:cupward/models/brews/brew_record.dart';
import 'package:cupward/models/brews/brew_sample.dart';
import 'package:cupward/models/brews/taste_attribute.dart';
import 'package:cupward/models/brews/tasting_notes.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';

/// Shared test data for brew feedback: a brew, tasting notes, a valid AI answer, and a fake plugin.
abstract final class BrewFeedbackFixtures {
  /// A full brew of the default recipe with readings ten times a second, as a real scale reports them.
  static BrewRecord brew() {
    const List<List<double>> pours = <List<double>>[
      <double>[0, 10, 0, 62],
      <double>[50, 68, 62, 161],
      <double>[80, 96, 161, 242],
      <double>[110, 128, 242, 318.4],
    ];
    final List<BrewSample> samples = <BrewSample>[];
    for (int milliseconds = 100; milliseconds <= 192000; milliseconds += 100) {
      final double seconds = milliseconds / 1000;
      double weight = 0;
      double flow = 0;
      for (final List<double> pour in pours) {
        if (seconds >= pour[1]) {
          weight = pour[3];
        } else if (seconds >= pour[0]) {
          weight = pour[2] + (pour[3] - pour[2]) * (seconds - pour[0]) / (pour[1] - pour[0]);
          flow = (pour[3] - pour[2]) / (pour[1] - pour[0]);
          break;
        } else {
          break;
        }
      }
      samples.add(
        BrewSample(elapsed: Duration(milliseconds: milliseconds), weightGrams: weight, flowGramsPerSecond: flow),
      );
    }

    return BrewRecord(
      recipe: BuiltInRecipes.defaultRecipe,
      startedAt: DateTime(2026, 11, 15, 8, 30),
      totalTime: const Duration(seconds: 192),
      scaleName: 'BOOKOO_SC_U 1234',
      phases: const <BrewPhaseRecord>[
        BrewPhaseRecord(phaseId: 'bloom', startedAt: Duration.zero),
        BrewPhaseRecord(phaseId: 'pour-1', startedAt: Duration(seconds: 50)),
        BrewPhaseRecord(phaseId: 'pour-2', startedAt: Duration(seconds: 80)),
        BrewPhaseRecord(phaseId: 'pour-3', startedAt: Duration(seconds: 110)),
        BrewPhaseRecord(phaseId: 'complete', startedAt: Duration(seconds: 140)),
      ],
      samples: samples,
    );
  }

  /// Notes for a cup that was a little sour and weak.
  static TastingNotes notes() => TastingNotes(
        ratings: const <TasteAttribute, int>{
          TasteAttribute.intensity: 2,
          TasteAttribute.acidity: 4,
          TasteAttribute.overall: 3,
        },
        goal: 'Sweeter and fuller.',
      );

  /// A suggestion in the shape of the schema.
  static Map<String, dynamic> suggestion({
    String parameter = 'coffeeDose',
    String direction = 'increase',
    double? suggestedValue = 21,
  }) {
    return <String, dynamic>{
      'parameter': parameter,
      'direction': direction,
      'title': 'Add a gram of coffee',
      'change': 'Use 21 g of coffee',
      if (suggestedValue != null) 'suggestedValue': suggestedValue,
      'rationale': 'The cup was weak and sour, which points to under-extraction.',
      'expectedEffect': 'A fuller, sweeter cup.',
    };
  }

  /// An answer in the shape of the schema.
  static Map<String, dynamic> answer() {
    return <String, dynamic>{
      'summary': 'The brew ran a little long, but the cup tasted weak and sour.',
      'primarySuggestion': suggestion(),
      'otherIdeas': <Map<String, dynamic>>[
        suggestion(parameter: 'grindSize', suggestedValue: null),
        suggestion(parameter: 'waterTemperature', suggestedValue: null),
      ],
    };
  }

  /// A result from the plugin with [data], from [source], with [violations].
  static StructuredGenerationResult result(
    Object? data, {
    InferenceSource source = InferenceSource.onDevice,
    List<String> violations = const <String>[],
  }) {
    return StructuredGenerationResult(
      text: '',
      data: data,
      source: source,
      isSchemaEnforced: source == InferenceSource.inCloud,
      violations: violations,
    );
  }
}

/// A stand-in for the plugin that answers structured requests with results, or errors, that a test queues.
class FakeStructuredHybridAi implements FirebaseHybridAi {
  /// The results to return, in order. An [Exception] in the list is thrown instead.
  final List<Object> responses = <Object>[];

  /// The mode of each request, in order.
  final List<InferenceMode> modes = <InferenceMode>[];

  /// The prompt of each request, in order.
  final List<String> prompts = <String>[];

  /// When set, requests wait for it to complete before answering, so a test can see the screen while it waits.
  Completer<void>? gate;

  @override
  Future<StructuredGenerationResult> generateStructured(
    String prompt, {
    required ResponseSchema schema,
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) async {
    prompts.add(prompt);
    modes.add(mode);
    await gate?.future;
    final Object response = responses.removeAt(0);
    if (response is Exception) {
      throw response;
    }
    return response as StructuredGenerationResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
