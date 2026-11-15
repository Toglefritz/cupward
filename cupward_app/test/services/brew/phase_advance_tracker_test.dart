// Repeated calls on the tracker read more clearly as a sequence of readings than as one cascade.
// ignore_for_file: cascade_invocations

import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/services/brew/phase_advance_progress.dart';
import 'package:cupward/services/brew/phase_advance_tracker.dart';
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

/// The start of every test, from which times are offset.
final DateTime _t0 = DateTime(2025);

/// Returns [_t0] plus [seconds].
DateTime _at(double seconds) => _t0.add(Duration(milliseconds: (seconds * 1000).round()));

/// Verifies when a [PhaseAdvanceTracker] decides a phase is finished, using made-up readings and times instead of a
/// scale and a clock.
void main() {
  const BrewPhase pour = BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 160);
  const BrewPhase bloom = BrewPhase(
    id: 'bloom',
    kind: BrewPhaseKind.bloom,
    targetWeightGrams: 60,
    duration: Duration(seconds: 45),
  );

  group('a pour with a target weight', () {
    /// The user stops by hand near the target, so the pour is finished once the weight and flow hold for the settle
    /// time, and not before.
    test('is ready after the weight and flow settle at the target', () {
      // Arrange
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: pour);

      // Act
      tracker.update(_at(0), reading: _reading(60));
      final PhaseAdvanceProgress pouring = tracker.update(_at(1), reading: _reading(120, flow: 5));
      final PhaseAdvanceProgress justArrived = tracker.update(_at(2), reading: _reading(159));
      final PhaseAdvanceProgress settled = tracker.update(_at(3.2), reading: _reading(159.5));

      // Assert
      expect(pouring.isReady, isFalse);
      expect(justArrived.isReady, isFalse);
      expect(settled.isReady, isTrue);
    });

    /// Splashes or a bumped kettle can flicker the flow, which must restart the settle time instead of ending the
    /// phase early.
    test('restarts the settle time when the flow picks up again', () {
      // Arrange
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: pour);
      tracker.update(_at(0), reading: _reading(60));
      tracker.update(_at(1), reading: _reading(160));

      // Act
      tracker.update(_at(1.8), reading: _reading(161, flow: 2));
      final PhaseAdvanceProgress afterBlip = tracker.update(_at(2.2), reading: _reading(161));

      // Assert
      expect(afterBlip.isReady, isFalse);
      expect(tracker.update(_at(3.4), reading: _reading(161)).isReady, isTrue);
    });

    /// The pour is not remembered as finished, so a user who keeps pouring after the countdown opens takes the phase
    /// back.
    test('stops being ready when pouring resumes', () {
      // Arrange
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: pour);
      tracker.update(_at(0), reading: _reading(60));
      tracker.update(_at(1), reading: _reading(160));
      expect(tracker.update(_at(2.5), reading: _reading(160)).isReady, isTrue);

      // Act
      final PhaseAdvanceProgress resumed = tracker.update(_at(3), reading: _reading(170, flow: 4));

      // Assert
      expect(resumed.isReady, isFalse);
    });

    /// A weight short of the target by more than the tolerance means the user is not done pouring.
    test('is not ready below the tolerance, however still the scale is', () {
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: pour);
      tracker.update(_at(0), reading: _reading(60));
      tracker.update(_at(1), reading: _reading(150));

      expect(tracker.update(_at(5), reading: _reading(150)).isReady, isFalse);
    });

    /// The weight left by the previous phase can already be at the next target, for example in a recipe whose targets
    /// are close together. Without the minimum rise the new phase would end at once.
    test('needs weight to be added during the phase', () {
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: pour);
      tracker.update(_at(0), reading: _reading(160));

      expect(tracker.update(_at(5), reading: _reading(160)).isReady, isFalse);
    });

    /// Time can pass between readings, and the settle time must still be able to finish then.
    test('can become ready on a tick without a new reading', () {
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: pour);
      tracker.update(_at(0), reading: _reading(60));
      tracker.update(_at(1), reading: _reading(160));

      expect(tracker.update(_at(2.2)).isReady, isTrue);
    });
  });

  group('a bloom with a target weight and a duration', () {
    /// The rest starts when the water is in and lasts the phase's duration, after which the phase is ready.
    test('rests for its duration after reaching the target, then is ready', () {
      // Arrange
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: bloom);
      tracker.update(_at(0), reading: _reading(0));
      final PhaseAdvanceProgress pouring = tracker.update(_at(2), reading: _reading(40, flow: 4));

      // Act
      tracker.update(_at(5), reading: _reading(60));
      final PhaseAdvanceProgress resting = tracker.update(_at(6.5), reading: _reading(60));
      final PhaseAdvanceProgress almost = tracker.update(_at(49));
      final PhaseAdvanceProgress done = tracker.update(_at(51.5));

      // Assert
      expect(pouring.restRemaining, isNull);
      expect(resting.isReady, isFalse);
      expect(resting.restRemaining, const Duration(seconds: 43, milliseconds: 500));
      expect(almost.isReady, isFalse);
      expect(done.isReady, isTrue);
      expect(done.restRemaining, Duration.zero);
    });

    /// Once the water is in, the rest is time, so disturbing the scale during it must not restart or cancel it.
    test('keeps resting if the weight changes during the rest', () {
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(phase: bloom);
      tracker.update(_at(0), reading: _reading(0));
      tracker.update(_at(2), reading: _reading(60));
      tracker.update(_at(3.2), reading: _reading(60));

      expect(tracker.update(_at(10), reading: _reading(20, flow: -3)).restRemaining, isNotNull);
      expect(tracker.update(_at(49), reading: _reading(60)).isReady, isTrue);
    });
  });

  group('phases without targets', () {
    /// Preparation and completion have nothing to measure, so only the button moves the brew on.
    test('never become ready', () {
      final PhaseAdvanceTracker tracker = PhaseAdvanceTracker(
        phase: const BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
      );

      expect(tracker.canAutoAdvance, isFalse);
      expect(tracker.update(_at(0), reading: _reading(500)).isReady, isFalse);
      expect(tracker.update(_at(100), reading: _reading(500)).isReady, isFalse);
    });
  });
}
