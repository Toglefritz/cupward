import 'package:cupward/models/brews/brew_phase_record.dart';
import 'package:cupward/models/brews/brew_record.dart';
import 'package:cupward/models/brews/brew_sample.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the brew record's JSON form and the values the feedback screen derives from it.
void main() {
  /// A short brew of the default recipe: a bloom, then a pour, with four readings.
  final BrewRecord record = BrewRecord(
    recipe: BuiltInRecipes.defaultRecipe,
    startedAt: DateTime(2026, 11, 15, 8, 30),
    totalTime: const Duration(seconds: 90),
    scaleName: 'BOOKOO_SC_U 1234',
    phases: const <BrewPhaseRecord>[
      BrewPhaseRecord(phaseId: 'bloom', startedAt: Duration.zero),
      BrewPhaseRecord(phaseId: 'pour-1', startedAt: Duration(seconds: 50)),
    ],
    samples: const <BrewSample>[
      BrewSample(elapsed: Duration(seconds: 5), weightGrams: 30, flowGramsPerSecond: 6),
      BrewSample(elapsed: Duration(seconds: 50), weightGrams: 61, flowGramsPerSecond: 0),
      BrewSample(elapsed: Duration(seconds: 70), weightGrams: 120, flowGramsPerSecond: 7.5),
      BrewSample(elapsed: Duration(seconds: 90), weightGrams: 158.4, flowGramsPerSecond: 0.2),
    ],
  );

  group('BrewRecord', () {
    /// The record is what brew feedback is based on, so it must survive conversion to JSON and back unchanged.
    test('converts to JSON and back', () {
      // Act
      final BrewRecord copy = BrewRecord.fromJson(record.toJson());

      // Assert
      expect(copy.recipe, record.recipe);
      expect(copy.startedAt, record.startedAt);
      expect(copy.totalTime, record.totalTime);
      expect(copy.scaleName, record.scaleName);
      expect(copy.phases, record.phases);
      expect(copy.samples, record.samples);
    });

    /// Data from an older or damaged source must fail clearly rather than produce a partial record.
    test('rejects JSON with a missing field', () {
      final Map<String, dynamic> json = record.toJson()..remove('totalMilliseconds');

      expect(() => BrewRecord.fromJson(json), throwsFormatException);
    });

    /// A phase ends where the next begins, and the last one ends with the brew.
    test('works out how long each phase lasted', () {
      expect(record.durationOfPhase(0), const Duration(seconds: 50));
      expect(record.durationOfPhase(1), const Duration(seconds: 40));
    });

    /// The table compares the weight at the end of each phase with its target.
    test('finds the weight at the end of each phase', () {
      expect(record.weightAtEndOfPhase(0), 61);
      expect(record.weightAtEndOfPhase(1), 158.4);
    });

    /// The summary's results come from the readings.
    test('reports the final weight and the peak flow', () {
      expect(record.finalWeightGrams, 158.4);
      expect(record.peakFlowGramsPerSecond, 7.5);
      expect(record.hasScaleReadings, isTrue);
    });

    /// A brew without a scale has no weights to report.
    test('reports no weights without readings', () {
      // Arrange
      final BrewRecord withoutScale = BrewRecord(
        recipe: record.recipe,
        startedAt: record.startedAt,
        totalTime: record.totalTime,
        phases: record.phases,
        samples: const <BrewSample>[],
      );

      // Assert
      expect(withoutScale.hasScaleReadings, isFalse);
      expect(withoutScale.finalWeightGrams, isNull);
      expect(withoutScale.peakFlowGramsPerSecond, isNull);
      expect(withoutScale.weightAtEndOfPhase(0), isNull);
      expect(withoutScale.toJson().containsKey('scaleName'), isFalse);
    });
  });
}
