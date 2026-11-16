import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

import '../../models/brews/brew_record.dart';
import '../../models/brews/tasting_notes.dart';
import '../../models/feedback/brew_feedback.dart';
import 'brew_feedback_exception.dart';
import 'brew_feedback_failure.dart';
import 'brew_feedback_parser.dart';
import 'brew_feedback_prompt.dart';
import 'brew_feedback_schema.dart';

/// Asks the hybrid AI system for feedback on a brew, in the shape of `BrewFeedbackSchema`.
///
/// The request prefers the on-device model, so the brew data stays on the device when it can, and falls back to the
/// cloud model otherwise. On Android the on-device model cannot be held to a schema, only told about it, so its answer
/// may not match. When an on-device answer does not match, the request is repeated once with the cloud model, which is
/// held to the schema on every platform.
///
/// Hybrid inference runs on Android and in the browser. On other platforms the plugin does not support it, so
/// [isSupported] is false there and every request fails with [BrewFeedbackFailure.unsupported].
class BrewFeedbackService {
  /// Creates a service.
  ///
  /// [hybridAi] defaults to a real `FirebaseHybridAi`, and [isSupported] to whether the app runs on Android or in a
  /// browser. Tests supply both.
  BrewFeedbackService({FirebaseHybridAi? hybridAi, bool? isSupported})
      : _hybridAi = hybridAi ?? FirebaseHybridAi(),
        isSupported = isSupported ?? (kIsWeb || defaultTargetPlatform == TargetPlatform.android);

  /// The plugin that runs the requests.
  final FirebaseHybridAi _hybridAi;

  /// Whether the platform can run hybrid inference.
  final bool isSupported;

  /// Returns feedback on [record], informed by the user's [notes].
  ///
  /// Throws a [BrewFeedbackException] if the feedback cannot be produced.
  Future<BrewFeedback> requestFeedback(BrewRecord record, TastingNotes notes) async {
    if (!isSupported) {
      throw const BrewFeedbackException(BrewFeedbackFailure.unsupported);
    }

    final String prompt = BrewFeedbackPrompt.build(record, notes);

    StructuredGenerationResult result = await _generate(prompt, InferenceMode.preferOnDevice);
    if (!result.conformsToSchema && result.source == InferenceSource.onDevice) {
      debugPrint('On-device brew feedback did not match the schema, so the cloud model is asked: ${result.violations}');
      result = await _generate(prompt, InferenceMode.onlyInCloud);
    }

    if (!result.conformsToSchema) {
      debugPrint('Brew feedback did not match the schema: ${result.violations}');
      throw const BrewFeedbackException(BrewFeedbackFailure.invalidResponse);
    }

    try {
      return BrewFeedbackParser.parse(result.data, recipe: record.recipe, source: result.source);
    } on FormatException catch (error) {
      debugPrint('Brew feedback could not be read: $error');
      throw const BrewFeedbackException(BrewFeedbackFailure.invalidResponse);
    }
  }

  /// Sends [prompt] with the schema in [mode], and turns plugin failures into [BrewFeedbackException]s.
  Future<StructuredGenerationResult> _generate(String prompt, InferenceMode mode) async {
    try {
      return await _hybridAi.generateStructured(prompt, schema: BrewFeedbackSchema.schema, mode: mode);
    } on HybridAiNotSupportedException catch (error) {
      debugPrint('Brew feedback is not supported here: $error');
      throw const BrewFeedbackException(BrewFeedbackFailure.unsupported);
    } on Object catch (error) {
      debugPrint('Brew feedback request failed: $error');
      throw const BrewFeedbackException(BrewFeedbackFailure.requestFailed);
    }
  }
}
