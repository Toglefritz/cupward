import 'package:flutter_bookoo/flutter_bookoo.dart';

import '../../models/recipes/brew_phase.dart';
import 'phase_advance_progress.dart';

/// Decides from scale readings when the current phase of a brew is finished.
///
/// A tracker follows one phase and is replaced when the brew moves to the next. It knows nothing about the screen or
/// the scale connection: callers pass in each reading and the current time, which keeps it testable without hardware
/// or real clocks.
///
/// The end condition depends on the targets the [phase] has:
///
/// * With a target weight only, such as a pour, the phase is ready while the weight is within [tolerance] of the
///   target and the flow has stayed near zero for [settleTime]. The state is not remembered, so if the user starts
///   pouring again the phase stops being ready.
/// * With a target weight and a duration, such as the bloom, the phase first needs the target weight to be reached the
///   same way. That starts a rest of the phase's duration, and the phase is ready when the rest is over.
/// * With a duration only, the rest starts with the first update.
/// * With neither, the phase never becomes ready, and the user moves on with the button.
///
/// A rise of at least [minimumRise] from the weight at the phase's first reading is required before the target can be
/// reached. Without it, a phase would end at once if the previous phase left the weight at or above its target.
///
/// The thresholds are named parameters so they can be tuned against a real scale.
class PhaseAdvanceTracker {
  /// Creates a tracker for [phase].
  ///
  /// [tolerance] is how many grams below the target still counts as reaching it, since the user stops the pour by
  /// hand. [maxFlowGramsPerSecond] is the largest flow, in either direction, that counts as stopped. [settleTime] is
  /// how long the weight and flow conditions must hold without a break, which ignores splashes and a bump of the
  /// kettle. [minimumRise] is the least weight in grams that must be added during the phase.
  PhaseAdvanceTracker({
    required this.phase,
    this.tolerance = 2.0,
    this.maxFlowGramsPerSecond = 0.5,
    this.settleTime = const Duration(seconds: 1),
    this.minimumRise = 5.0,
  });

  /// The phase being followed.
  final BrewPhase phase;

  /// How many grams below the target weight still counts as reaching it.
  final double tolerance;

  /// The largest flow in grams per second, in either direction, that counts as stopped.
  final double maxFlowGramsPerSecond;

  /// How long the weight and flow conditions must hold without a break.
  final Duration settleTime;

  /// The least weight in grams that must be added during the phase before the target can count as reached.
  final double minimumRise;

  /// The weight at the first reading of the phase, which the rise is measured from.
  double? _startWeight;

  /// When the weight and flow conditions last became true without a break, or null while they do not hold.
  DateTime? _settledSince;

  /// When the rest began, or null if it has not.
  DateTime? _restStartedAt;

  /// Whether the phase has anything to end it, which is false for phases with neither a target weight nor a duration.
  bool get canAutoAdvance => phase.targetWeightGrams != null || phase.duration != null;

  /// Updates the tracker and returns where the phase stands.
  ///
  /// [now] is the current time. [reading] is a new reading from the scale, or null when only time has passed, which
  /// lets a rest finish when no new reading arrives.
  PhaseAdvanceProgress update(DateTime now, {BookooScaleReading? reading}) {
    if (!canAutoAdvance) {
      return PhaseAdvanceProgress.waiting;
    }

    final double? target = phase.targetWeightGrams;
    final Duration? duration = phase.duration;

    if (reading != null && target != null) {
      _trackWeight(reading, target, now);
    }

    // A rest with no target weight starts with the phase. One with a target starts from the moment the weight began
    // to settle, not from when the settle time was confirmed, so the user sees the full duration they were told.
    if (duration != null && _restStartedAt == null) {
      if (target == null) {
        _restStartedAt = now;
      } else if (_hasSettled(now)) {
        _restStartedAt = _settledSince;
      }
    }

    if (duration != null) {
      final DateTime? startedAt = _restStartedAt;
      if (startedAt == null) {
        return PhaseAdvanceProgress.waiting;
      }
      final Duration remaining = duration - now.difference(startedAt);
      final Duration clamped = remaining.isNegative ? Duration.zero : remaining;
      return PhaseAdvanceProgress(isReady: clamped == Duration.zero, restRemaining: clamped);
    }

    return PhaseAdvanceProgress(isReady: _hasSettled(now));
  }

  /// Records whether the weight and flow in [reading] satisfy the end condition for [target] at [now].
  void _trackWeight(BookooScaleReading reading, double target, DateTime now) {
    final double startWeight = _startWeight ??= reading.weightGrams;
    final bool risen = reading.weightGrams - startWeight >= minimumRise;
    final bool atTarget = reading.weightGrams >= target - tolerance;
    final bool stopped = reading.flowRateGramsPerSecond.abs() <= maxFlowGramsPerSecond;

    if (risen && atTarget && stopped) {
      _settledSince ??= now;
    } else {
      _settledSince = null;
    }
  }

  /// Whether the weight and flow conditions have held for [settleTime] as of [now].
  bool _hasSettled(DateTime now) {
    final DateTime? since = _settledSince;
    return since != null && now.difference(since) >= settleTime;
  }
}
