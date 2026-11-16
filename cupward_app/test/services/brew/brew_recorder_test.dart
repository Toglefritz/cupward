import 'package:cupward/models/brews/brew_phase_record.dart';
import 'package:cupward/models/brews/brew_record.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/services/brew/brew_recorder.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';

/// A reading of [grams] with the given [flow] in grams per second.
BookooScaleReading _reading(double grams, {double flow = 0}) => BookooScaleReading(
      elapsed: Duration.zero,
      weightGrams: grams,
      flowRateGramsPerSecond: flow,
      batteryPercent: 80,
      standbyTime: const Duration(minutes: 5),
      beepLevel: 3,
      flowSmoothingEnabled: false,
    );

/// Verifies that the recorder times phases and readings from the start of the brew.
void main() {
  final DateTime start = DateTime(2026, 11, 15, 8, 30);
  late BrewRecorder recorder;

  setUp(() => recorder = BrewRecorder(recipe: BuiltInRecipes.defaultRecipe));

  group('BrewRecorder', () {
    /// Readings during preparation, such as while taring, are not part of the brew.
    test('ignores readings and phases before the brew starts', () {
      // Act
      recorder
        ..addReading(_reading(400), start)
        ..markPhase(BuiltInRecipes.defaultRecipe.phases[1], start);

      // Assert
      expect(recorder.isRecording, isFalse);
      final BrewRecord record = recorder.finish(start);
      expect(record.samples, isEmpty);
      expect(record.phases.single.phaseId, 'prepare');
    });

    /// Times are measured from the start of the brew, so the summary can lay them out on one axis.
    test('times phases and readings from the start', () {
      // Act
      recorder
        ..start(start, BuiltInRecipes.defaultRecipe.phases[1])
        ..addReading(_reading(30, flow: 5), start.add(const Duration(seconds: 6)), scaleName: 'BOOKOO_SC_U 1')
        ..markPhase(BuiltInRecipes.defaultRecipe.phases[2], start.add(const Duration(seconds: 50)));
      final BrewRecord record = recorder.finish(start.add(const Duration(seconds: 80)));

      // Assert
      expect(record.startedAt, start);
      expect(record.totalTime, const Duration(seconds: 80));
      expect(record.scaleName, 'BOOKOO_SC_U 1');
      expect(record.phases, const <BrewPhaseRecord>[
        BrewPhaseRecord(phaseId: 'bloom', startedAt: Duration.zero),
        BrewPhaseRecord(phaseId: 'pour-1', startedAt: Duration(seconds: 50)),
      ]);
      expect(record.samples.single.elapsed, const Duration(seconds: 6));
      expect(record.samples.single.weightGrams, 30);
      expect(record.samples.single.flowGramsPerSecond, 5);
    });

    /// The scale service repeats its latest reading with every change it announces, which must not double the data.
    test('records a repeated reading once', () {
      // Arrange
      final BookooScaleReading reading = _reading(30);

      // Act
      recorder
        ..start(start, BuiltInRecipes.defaultRecipe.phases[1])
        ..addReading(reading, start.add(const Duration(seconds: 1)))
        ..addReading(reading, start.add(const Duration(seconds: 2)));

      // Assert
      expect(recorder.finish(start.add(const Duration(seconds: 3))).samples, hasLength(1));
    });

    /// Starting twice, as when a later phase change also looks like a start, must not reset the brew.
    test('keeps the first start', () {
      // Act
      recorder
        ..start(start, BuiltInRecipes.defaultRecipe.phases[1])
        ..start(start.add(const Duration(seconds: 10)), BuiltInRecipes.defaultRecipe.phases[2]);

      // Assert
      final BrewRecord record = recorder.finish(start.add(const Duration(seconds: 20)));
      expect(record.startedAt, start);
      expect(record.phases, hasLength(1));
    });
  });
}
