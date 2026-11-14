import 'package:flutter/foundation.dart';

/// One measurement report from a BOOKOO scale.
///
/// The scale sends a report roughly ten times per second while connected. Each
/// report is self-contained, so listeners can use the latest value without
/// tracking earlier ones.
@immutable
class BookooScaleReading {
  /// Creates a reading.
  const new({
    required this.elapsed,
    required this.weightGrams,
    required this.flowRateGramsPerSecond,
    required this.batteryPercent,
    required this.standbyTime,
    required this.beepLevel,
    required this.flowSmoothingEnabled,
  });

  /// The scale's timer value.
  ///
  /// This is the scale's own clock, which only advances while its timer runs.
  /// It is not wall-clock time.
  final Duration elapsed;

  /// The weight on the platter in grams, after tare.
  ///
  /// Negative when weight has been removed since the last tare.
  final double weightGrams;

  /// The rate of change of weight in grams per second.
  ///
  /// Negative when weight is decreasing. The scale applies smoothing when
  /// [flowSmoothingEnabled] is true.
  final double flowRateGramsPerSecond;

  /// The remaining battery charge from 0 to 100.
  final int batteryPercent;

  /// The standby time value the scale reports.
  ///
  /// The protocol documents this only as "standby time", so its relationship
  /// to the configured auto-off duration is unconfirmed.
  final Duration standbyTime;

  /// The beeper volume setting. 0 is muted.
  final int beepLevel;

  /// Whether the scale is smoothing the flow rate it reports.
  final bool flowSmoothingEnabled;

  @override
  bool operator ==(Object other) {
    return other is BookooScaleReading &&
        other.elapsed == elapsed &&
        other.weightGrams == weightGrams &&
        other.flowRateGramsPerSecond == flowRateGramsPerSecond &&
        other.batteryPercent == batteryPercent &&
        other.standbyTime == standbyTime &&
        other.beepLevel == beepLevel &&
        other.flowSmoothingEnabled == flowSmoothingEnabled;
  }

  @override
  int get hashCode => Object.hash(
    elapsed,
    weightGrams,
    flowRateGramsPerSecond,
    batteryPercent,
    standbyTime,
    beepLevel,
    flowSmoothingEnabled,
  );

  @override
  String toString() =>
      'BookooScaleReading(elapsed: $elapsed, weightGrams: $weightGrams, '
      'flowRateGramsPerSecond: $flowRateGramsPerSecond, batteryPercent: $batteryPercent, '
      'standbyTime: $standbyTime, beepLevel: $beepLevel, flowSmoothingEnabled: $flowSmoothingEnabled)';
}
