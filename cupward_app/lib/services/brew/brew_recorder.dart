import 'package:flutter_bookoo/flutter_bookoo.dart';

import '../../models/brews/brew_phase_record.dart';
import '../../models/brews/brew_record.dart';
import '../../models/brews/brew_sample.dart';
import '../../models/recipes/brew_phase.dart';
import '../../models/recipes/brew_recipe.dart';

/// Collects what happens during a brew into a [BrewRecord].
///
/// The brewing screen owns one recorder per brew. It calls [start] when the user leaves the preparation step, which is
/// right after the scale is tared, then [markPhase] each time the brew moves to a new phase, [addReading] for each
/// scale reading, and [finish] when the brew is done.
///
/// Like `PhaseAdvanceTracker`, the recorder takes the current time as an argument rather than reading a clock, so it
/// can be tested without waiting.
class BrewRecorder {
  /// Creates a recorder for a brew of [recipe].
  BrewRecorder({required this.recipe});

  /// The recipe being brewed.
  final BrewRecipe recipe;

  /// When the brew started, or null before [start].
  DateTime? _startedAt;

  /// The phases begun so far.
  final List<BrewPhaseRecord> _phases = <BrewPhaseRecord>[];

  /// The readings recorded so far.
  final List<BrewSample> _samples = <BrewSample>[];

  /// The last reading recorded, so that a reading reported twice is only recorded once.
  BookooScaleReading? _lastReading;

  /// The name of the scale that took the readings, or null if none has.
  String? _scaleName;

  /// Whether [start] has been called.
  bool get isRecording => _startedAt != null;

  /// Starts the brew at [now], in the phase [firstPhase]. Later calls are ignored.
  void start(DateTime now, BrewPhase firstPhase) {
    if (_startedAt != null) {
      return;
    }
    _startedAt = now;
    _phases.add(BrewPhaseRecord(phaseId: firstPhase.id, startedAt: Duration.zero));
  }

  /// Records that the brew moved to [phase] at [now]. Ignored before [start].
  void markPhase(BrewPhase phase, DateTime now) {
    final Duration? elapsed = _elapsed(now);
    if (elapsed == null) {
      return;
    }
    _phases.add(BrewPhaseRecord(phaseId: phase.id, startedAt: elapsed));
  }

  /// Records [reading] from the scale named [scaleName], taken at [now].
  ///
  /// Ignored before [start], and when [reading] is the same object as the previous one. The scale service reports its
  /// latest reading with every change it announces, including ones that are not new readings.
  void addReading(BookooScaleReading reading, DateTime now, {String? scaleName}) {
    final Duration? elapsed = _elapsed(now);
    if (elapsed == null || identical(reading, _lastReading)) {
      return;
    }
    _lastReading = reading;
    _scaleName ??= scaleName;
    _samples.add(
      BrewSample(
        elapsed: elapsed,
        weightGrams: reading.weightGrams,
        flowGramsPerSecond: reading.flowRateGramsPerSecond,
      ),
    );
  }

  /// Ends the brew at [now] and returns its record.
  ///
  /// If [start] was never called, the brew is treated as having started at [now], in the recipe's first phase.
  BrewRecord finish(DateTime now) {
    start(now, recipe.phases.first);

    return BrewRecord(
      recipe: recipe,
      startedAt: _startedAt!,
      totalTime: _elapsed(now)!,
      phases: List<BrewPhaseRecord>.unmodifiable(_phases),
      samples: List<BrewSample>.unmodifiable(_samples),
      scaleName: _scaleName,
    );
  }

  /// The time from the start of the brew to [now], or null before [start]. Never negative.
  Duration? _elapsed(DateTime now) {
    final DateTime? startedAt = _startedAt;
    if (startedAt == null) {
      return null;
    }
    final Duration elapsed = now.difference(startedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }
}
