import 'package:flutter/foundation.dart';

import '../recipes/brew_recipe.dart';
import 'brew_phase_record.dart';
import 'brew_sample.dart';

/// What happened during one brew: the recipe that was followed, when each phase began, and the scale's readings.
///
/// This is the record that the feedback screen summarizes and that brew feedback is based on, so it holds everything
/// needed to compare the brew with its recipe. The recipe is stored in full, rather than by ID, so the record still
/// describes the brew if the recipe is later changed.
///
/// Times are measured from the start of the brew, which is when the user left the preparation step and the scale had
/// just been tared. Brews made without a scale have phase timings but no [samples].
///
/// The JSON form is below, with the recipe, phases, and samples in their own JSON forms.
///
/// ```json
/// {
///   "recipe": { ... },
///   "startedAt": "2026-11-15T08:30:00.000",
///   "totalMilliseconds": 192000,
///   "scaleName": "BOOKOO_SC_U 1234",
///   "phases": [ { "phaseId": "bloom", "startedAtMilliseconds": 0 }, ... ],
///   "samples": [ { "elapsedMilliseconds": 100, "weightGrams": 0.0, "flowGramsPerSecond": 0.0 }, ... ]
/// }
/// ```
@immutable
class BrewRecord {
  /// Creates a record of a brew of [recipe] that began at [startedAt] and lasted [totalTime].
  const BrewRecord({
    required this.recipe,
    required this.startedAt,
    required this.totalTime,
    required this.phases,
    required this.samples,
    this.scaleName,
  });

  /// Creates a record from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or has the wrong type.
  factory BrewRecord.fromJson(Map<String, dynamic> json) {
    try {
      return BrewRecord(
        recipe: BrewRecipe.fromJson(json['recipe'] as Map<String, dynamic>),
        startedAt: DateTime.parse(json['startedAt'] as String),
        totalTime: Duration(milliseconds: (json['totalMilliseconds'] as num).round()),
        scaleName: json['scaleName'] as String?,
        phases: (json['phases'] as List<dynamic>)
            .map((dynamic phase) => BrewPhaseRecord.fromJson(phase as Map<String, dynamic>))
            .toList(),
        samples: (json['samples'] as List<dynamic>)
            .map((dynamic sample) => BrewSample.fromJson(sample as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw FormatException('Failed to parse BrewRecord from JSON: $e');
    }
  }

  /// The recipe that was followed.
  final BrewRecipe recipe;

  /// When the brew began, in local time.
  final DateTime startedAt;

  /// How long the brew took, from leaving the preparation step to finishing.
  final Duration totalTime;

  /// When each phase after preparation began, in order.
  final List<BrewPhaseRecord> phases;

  /// The scale's readings, in order, or an empty list if no scale was connected.
  final List<BrewSample> samples;

  /// The name of the scale that took the readings, or null if no scale was connected.
  final String? scaleName;

  /// Whether the brew has scale readings.
  bool get hasScaleReadings => samples.isNotEmpty;

  /// The water weight at the end of the brew, or null without scale readings.
  double? get finalWeightGrams => samples.isEmpty ? null : samples.last.weightGrams;

  /// The fastest the water was poured, in grams per second, or null without scale readings.
  double? get peakFlowGramsPerSecond {
    if (samples.isEmpty) {
      return null;
    }
    return samples.map((BrewSample sample) => sample.flowGramsPerSecond).reduce((double a, double b) => a > b ? a : b);
  }

  /// When the phase at [index] in [phases] ended, which is when the next one began, or the end of the brew for the
  /// last one.
  Duration endOfPhase(int index) => index + 1 < phases.length ? phases[index + 1].startedAt : totalTime;

  /// How long the phase at [index] in [phases] lasted.
  Duration durationOfPhase(int index) => endOfPhase(index) - phases[index].startedAt;

  /// The water weight when the phase at [index] in [phases] ended, or null if no reading came before then.
  double? weightAtEndOfPhase(int index) {
    final Duration end = endOfPhase(index);
    BrewSample? last;
    for (final BrewSample sample in samples) {
      if (sample.elapsed > end) {
        break;
      }
      last = sample;
    }
    return last?.weightGrams;
  }

  /// Converts the record to its JSON form, described on the class.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'recipe': recipe.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'totalMilliseconds': totalTime.inMilliseconds,
        if (scaleName != null) 'scaleName': scaleName,
        'phases': phases.map((BrewPhaseRecord phase) => phase.toJson()).toList(),
        'samples': samples.map((BrewSample sample) => sample.toJson()).toList(),
      };

  @override
  String toString() =>
      'BrewRecord(${recipe.id}, ${totalTime.inSeconds} s, ${phases.length} phases, ${samples.length} samples)';
}
