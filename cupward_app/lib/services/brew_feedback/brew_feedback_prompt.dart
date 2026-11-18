import 'dart:convert';

import '../../models/brews/brew_phase_record.dart';
import '../../models/brews/brew_record.dart';
import '../../models/brews/brew_sample.dart';
import '../../models/brews/tasting_notes.dart';
import '../../models/recipes/brew_phase.dart';
import '../../models/recipes/brew_recipe.dart';

/// Builds the prompt that asks the AI model for feedback on a brew.
///
/// The prompt has two parts: instructions on how to coach, and the brew data as compact JSON. The data summarizes the
/// scale's readings rather than listing them, because on-device models accept only about 4,000 tokens per request and
/// a brew records about ten readings a second. Each step is described by its time, the weight at its end against its
/// target, the water poured, and the average pour rate, and the weight is added every [seriesInterval] to show the
/// shape of the brew.
///
/// The instructions ask for one small change at a time. Changing one variable per brew lets the user taste what it did,
/// and small steps keep a good cup from being overshot.
abstract final class BrewFeedbackPrompt {
  /// How far apart the points of the weight series are.
  static const Duration seriesInterval = Duration(seconds: 10);

  /// The flow, in grams per second, above which water counts as being poured when averaging the pour rate.
  static const double pouringFlowThreshold = 0.5;

  /// The coaching instructions that come before the brew data.
  static const String instructions = '''
You are a coffee brewing coach. Review one brew and recommend what to change in the next one.

Rules:
- Recommend exactly one primary change: the single variable most likely to move the cup toward what the user wants. One change at a time lets the user taste its effect.
- Keep changes small, such as 1 g of coffee, 10 to 20 g of water, one or two grinder steps, 2 to 3 degrees C, or 10 to 15 seconds.
- Offer at most two other ideas for later brews, each a single change to a different variable.
- Base every rationale on the brew data and tasting notes. Sour, weak, or thin cups usually mean under-extraction. Bitter, harsh, or drying cups usually mean over-extraction.
- Ratings run from 1 (none or very little) to 5 (a lot). For overall, 1 means disliked and 5 means loved. Unrated attributes are left out.
- For a recipe with a steep step, change how long it steeps with steepTime. bloomTime and bloomWater apply only to a recipe with a bloom step.
- If the goal is given, aim for it.
- Write for a home brewer, in plain and friendly language.''';

  /// Returns the prompt for [record] with the user's [notes].
  static String build(BrewRecord record, TastingNotes notes) {
    return '$instructions\n\nBrew data (JSON):\n${jsonEncode(data(record, notes))}';
  }

  /// Returns the brew data that the prompt includes, as a JSON-encodable map.
  static Map<String, Object?> data(BrewRecord record, TastingNotes notes) {
    return <String, Object?>{
      'recipe': _recipe(record.recipe),
      'brew': _brew(record),
      'tasting': notes.toJson(),
    };
  }

  /// Describes the recipe's targets.
  static Map<String, Object?> _recipe(BrewRecipe recipe) {
    return <String, Object?>{
      'name': recipe.name,
      'method': recipe.method.name,
      'coffeeGrams': _round(recipe.coffeeGrams),
      'waterGrams': _round(recipe.waterGrams),
      'ratio': '1:${_formatRatio(recipe.waterGrams / recipe.coffeeGrams)}',
      'targetBrewTimeSeconds': recipe.brewTime.inSeconds,
      'steps': <Map<String, Object?>>[
        for (final BrewPhase phase in recipe.phases)
          <String, Object?>{
            'step': phase.id,
            'kind': phase.kind.name,
            if (phase.targetWeightGrams != null) 'targetWeightGrams': _round(phase.targetWeightGrams!),
            if (phase.duration != null) 'restSeconds': phase.duration!.inSeconds,
          },
      ],
    };
  }

  /// Describes what happened in the brew.
  static Map<String, Object?> _brew(BrewRecord record) {
    final bool hasReadings = record.hasScaleReadings;

    return <String, Object?>{
      'totalTimeSeconds': record.totalTime.inSeconds,
      'scaleUsed': hasReadings,
      if (hasReadings) 'finalWaterGrams': _round(record.finalWeightGrams!),
      if (hasReadings) 'peakFlowGramsPerSecond': _round(record.peakFlowGramsPerSecond!),
      'steps': <Map<String, Object?>>[
        for (int index = 0; index < record.phases.length; index++) _step(record, index),
      ],
      if (hasReadings) 'weightGramsEvery${seriesInterval.inSeconds}Seconds': _series(record),
    };
  }

  /// Describes the recorded phase at [index].
  static Map<String, Object?> _step(BrewRecord record, int index) {
    final BrewPhaseRecord phase = record.phases[index];
    final Duration start = phase.startedAt;
    final Duration end = record.endOfPhase(index);
    final double? endWeight = record.weightAtEndOfPhase(index);
    final double? startWeight = index == 0 ? 0 : record.weightAtEndOfPhase(index - 1);

    final List<double> pouring = <double>[
      for (final BrewSample sample in record.samples)
        if (sample.elapsed > start && sample.elapsed <= end && sample.flowGramsPerSecond > pouringFlowThreshold)
          sample.flowGramsPerSecond,
    ];

    return <String, Object?>{
      'step': phase.phaseId,
      'durationSeconds': record.durationOfPhase(index).inSeconds,
      if (endWeight != null) 'endWeightGrams': _round(endWeight),
      if (endWeight != null && startWeight != null) 'pouredGrams': _round(endWeight - startWeight),
      if (pouring.isNotEmpty)
        'averagePourRateGramsPerSecond': _round(pouring.reduce((double a, double b) => a + b) / pouring.length),
    };
  }

  /// The weight at every [seriesInterval], from the start of the brew to its end.
  static List<double> _series(BrewRecord record) {
    final List<double> series = <double>[];
    int sampleIndex = 0;
    double weight = 0;

    for (Duration time = seriesInterval; time <= record.totalTime; time += seriesInterval) {
      while (sampleIndex < record.samples.length && record.samples[sampleIndex].elapsed <= time) {
        weight = record.samples[sampleIndex].weightGrams;
        sampleIndex++;
      }
      series.add(_round(weight));
    }
    return series;
  }

  /// Formats a water-to-coffee [ratio], such as "16" or "15.5", without a trailing ".0".
  static String _formatRatio(double ratio) {
    final double rounded = _round(ratio);
    return rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toString();
  }

  /// Rounds [value] to one decimal place, which is the scale's precision and keeps the prompt short.
  static double _round(double value) => (value * 10).roundToDouble() / 10;
}
