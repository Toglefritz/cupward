import 'dart:math';

import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/services/brew/phase_advance_progress.dart';
import 'package:cupward/services/brew/phase_advance_tracker.dart';
import 'package:cupward/services/scale/demo_scale_simulator.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';

/// A French press recipe: one pour of all the water, then a four-minute steep.
final BrewRecipe _press = BuiltInRecipes.v60PourOver.copyWith(
  phases: const <BrewPhase>[
    BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
    BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 320),
    BrewPhase(id: 'steep', kind: BrewPhaseKind.steep, duration: Duration(minutes: 4)),
    BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
  ],
);

/// What a simulated brew did: when each phase ended, and every reading after the tare.
typedef _Run = ({List<Duration> phaseEnds, List<BookooScaleReading> readings});

/// Brews [recipe] with the simulator, following each phase with a [PhaseAdvanceTracker] the way the brewing screen
/// does, and returns what happened. The user taps Continue [prepareTime] after the brew starts.
_Run _brew(BrewRecipe recipe, {required int seed, Duration prepareTime = const Duration(seconds: 3)}) {
  const Duration step = Duration(milliseconds: 100);
  const Duration window = Duration(seconds: 3);
  final DemoScaleSimulator simulator = DemoScaleSimulator(random: Random(seed))..reset();
  final DateTime start = DateTime(2026);
  final List<Duration> phaseEnds = <Duration>[];
  final List<BookooScaleReading> readings = <BookooScaleReading>[];
  Duration time = Duration.zero;
  // Preparation ends with the user's tap, which tares the scale.
  while (time < prepareTime) {
    time += step;
    simulator.advance(step);
  }
  simulator.tare();
  phaseEnds.add(time);
  for (int index = 1; index < recipe.phases.length - 1; index++) {
    final BrewPhase phase = recipe.phases[index];
    simulator.pourTo(phase.targetWeightGrams);
    final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: phase);
    DateTime? windowEnds;
    while (true) {
      time += step;
      if (time > const Duration(minutes: 15)) {
        fail('Phase ${phase.id} never finished.');
      }
      final BookooScaleReading reading = simulator.advance(step);
      readings.add(reading);
      final DateTime now = start.add(time);
      final PhaseAdvanceProgress progress = tracker.update(now, reading: reading);
      if (!progress.isReady) {
        windowEnds = null;
      } else if (windowEnds == null) {
        windowEnds = now.add(window);
      } else if (!now.isBefore(windowEnds)) {
        break;
      }
    }
    phaseEnds.add(time);
  }
  return (phaseEnds: phaseEnds, readings: readings);
}

/// Verifies that the simulated scale brews a recipe the way a person would, so the brewing screen follows a demo
/// exactly as it follows a real scale.
void main() {
  group('DemoScaleSimulator', () {
    /// The brewer is set down shortly after the start, and the tare zeroes it.
    test('sets the brewer down, then tares to zero', () {
      // Arrange
      final DemoScaleSimulator simulator = DemoScaleSimulator(random: Random(1))..reset();
      // Act
      final double empty = simulator.advance(const Duration(milliseconds: 500)).weightGrams;
      simulator.advance(const Duration(seconds: 3));
      final double placed = simulator.advance(const Duration(milliseconds: 100)).weightGrams;
      simulator.tare();
      final double tared = simulator.advance(const Duration(milliseconds: 100)).weightGrams;
      // Assert
      expect(empty, 0);
      expect(placed, DemoScaleSimulator.brewerGrams);
      expect(tared, 0);
    });

    /// Taring before the brewer is down sets it down first, so the water is all the weight counts.
    test('sets the brewer down when tared early', () {
      final DemoScaleSimulator simulator = DemoScaleSimulator(random: Random(1))
        ..reset()
        ..tare();
      for (int i = 0; i < 40; i++) {
        expect(simulator.advance(const Duration(milliseconds: 100)).weightGrams, 0);
      }
    });

    /// Every phase of the built-in pour over ends by itself, with realistic pours, for any run of the randomness.
    test('brews the pour over to the end with realistic readings', () {
      for (int seed = 0; seed < 20; seed++) {
        // Act
        final _Run run = _brew(BuiltInRecipes.v60PourOver, seed: seed);
        // Assert
        const BrewRecipe recipe = BuiltInRecipes.v60PourOver;
        expect(run.phaseEnds, hasLength(recipe.phases.length - 1), reason: 'seed $seed');
        final double last = run.readings.last.weightGrams;
        expect(last, closeTo(recipe.waterGrams, 1.5), reason: 'seed $seed');
        final double peakFlow = run.readings.map((BookooScaleReading r) => r.flowRateGramsPerSecond).reduce(max);
        expect(peakFlow, inInclusiveRange(4, 9), reason: 'seed $seed');
        for (int i = 1; i < run.readings.length; i++) {
          expect(run.readings[i].weightGrams, greaterThanOrEqualTo(run.readings[i - 1].weightGrams));
        }
        // The bloom rests 45 s and three pours follow, so the brew takes a few minutes, as a real one does.
        final Duration total = run.phaseEnds.last;
        expect(total >= const Duration(minutes: 1) && total <= const Duration(minutes: 3), isTrue, reason: '$total');
      }
    });

    /// An immersion brew pours once and then holds its weight through the steep.
    test('brews an immersion recipe through its steep', () {
      // Act
      final _Run run = _brew(_press, seed: 7);
      // Assert
      expect(run.phaseEnds, hasLength(3));
      final Duration steep = run.phaseEnds[2] - run.phaseEnds[1];
      expect(steep, greaterThanOrEqualTo(const Duration(minutes: 4)));
      expect(run.readings.last.weightGrams, closeTo(320, 1.5));
      expect(run.readings.last.flowRateGramsPerSecond, 0);
    });

    /// A reset starts the scene over for the next brew.
    test('empties the platter on reset', () {
      final DemoScaleSimulator simulator = DemoScaleSimulator(random: Random(2))
        ..reset()
        ..advance(const Duration(seconds: 3))
        ..tare()
        ..pourTo(100);
      for (int i = 0; i < 400; i++) {
        simulator.advance(const Duration(milliseconds: 100));
      }
      simulator.reset();
      final BookooScaleReading reading = simulator.advance(const Duration(milliseconds: 100));
      expect(reading.weightGrams, 0);
      expect(simulator.isPouring, isFalse);
    });
  });
}
