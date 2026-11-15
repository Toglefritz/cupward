import 'package:flutter/foundation.dart';

/// What a `PhaseAdvanceTracker` concludes about the current phase after a reading or a tick of the clock.
@immutable
class PhaseAdvanceProgress {
  /// Creates a result. [isReady] says the phase's end condition holds, and [restRemaining] is the time left in the
  /// phase's rest, or null when the phase is not resting.
  const PhaseAdvanceProgress({required this.isReady, this.restRemaining});

  /// Progress for a phase that has not reached its end condition and is not resting.
  static const PhaseAdvanceProgress waiting = PhaseAdvanceProgress(isReady: false);

  /// Whether the phase's end condition holds, so the brew can move to the next phase.
  ///
  /// For a pour this is true while the weight is at the target and the flow has stopped. For a phase with a duration,
  /// such as the bloom, it is true once the rest after reaching the target weight is over.
  final bool isReady;

  /// The time left in the phase's rest, such as the wait after the bloom water is added, or null if the phase is not
  /// resting. It is [Duration.zero] when the rest is over.
  final Duration? restRemaining;

  @override
  bool operator ==(Object other) =>
      other is PhaseAdvanceProgress && other.isReady == isReady && other.restRemaining == restRemaining;

  @override
  int get hashCode => Object.hash(isReady, restRemaining);

  @override
  String toString() => 'PhaseAdvanceProgress(isReady: $isReady, restRemaining: $restRemaining)';
}
