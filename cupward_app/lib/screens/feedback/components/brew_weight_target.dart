import 'package:flutter/foundation.dart';

/// A recipe's target weight for one stretch of a brew, drawn as a dashed line across that stretch of the chart.
@immutable
class BrewWeightTarget {
  /// Creates a target of [grams] from [start] to [end], measured from the start of the brew.
  const BrewWeightTarget({required this.start, required this.end, required this.grams});

  /// When the stretch begins.
  final Duration start;

  /// When the stretch ends.
  final Duration end;

  /// The target weight, in grams.
  final double grams;
}
