import 'package:flutter/foundation.dart';

/// One reading from the scale during a brew: the weight and flow rate at a moment.
///
/// [elapsed] is measured from the start of the brew, when the user left the preparation step, rather than from the
/// scale's own timer, which the user can stop and reset. Weights count water only, because the scale is tared with the
/// brewer and coffee on it before the brew starts.
///
/// The JSON form is below.
///
/// ```json
/// { "elapsedMilliseconds": 12400, "weightGrams": 58.2, "flowGramsPerSecond": 3.4 }
/// ```
@immutable
class BrewSample {
  /// Creates a sample of [weightGrams] and [flowGramsPerSecond] taken [elapsed] after the brew started.
  const BrewSample({required this.elapsed, required this.weightGrams, required this.flowGramsPerSecond});

  /// Creates a sample from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or has the wrong type.
  factory BrewSample.fromJson(Map<String, dynamic> json) {
    try {
      return BrewSample(
        elapsed: Duration(milliseconds: (json['elapsedMilliseconds'] as num).round()),
        weightGrams: (json['weightGrams'] as num).toDouble(),
        flowGramsPerSecond: (json['flowGramsPerSecond'] as num).toDouble(),
      );
    } catch (e) {
      throw FormatException('Failed to parse BrewSample from JSON: $e');
    }
  }

  /// How long after the start of the brew the sample was taken.
  final Duration elapsed;

  /// The weight of water on the scale, in grams.
  final double weightGrams;

  /// How fast the weight was changing, in grams per second, as the scale reported it.
  final double flowGramsPerSecond;

  /// Converts the sample to its JSON form, described on the class.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'elapsedMilliseconds': elapsed.inMilliseconds,
        'weightGrams': weightGrams,
        'flowGramsPerSecond': flowGramsPerSecond,
      };

  @override
  bool operator ==(Object other) =>
      other is BrewSample &&
      other.elapsed == elapsed &&
      other.weightGrams == weightGrams &&
      other.flowGramsPerSecond == flowGramsPerSecond;

  @override
  int get hashCode => Object.hash(elapsed, weightGrams, flowGramsPerSecond);

  @override
  String toString() => 'BrewSample(${elapsed.inMilliseconds} ms, $weightGrams g, $flowGramsPerSecond g/s)';
}
