import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/brews/brew_sample.dart';
import 'brew_weight_target.dart';

/// Paints the water weight of a brew over time, with each phase's target and the boundaries between phases.
///
/// Time runs left to right from the start of the brew to [totalTime], and weight runs bottom to top from zero to a
/// little above the larger of the heaviest reading and the highest target. The weight is a solid line with a faint fill
/// below it. Each target is a dashed line across its phase, and each phase boundary is a faint vertical rule. The top
/// weight and the two ends of the time axis are labeled.
class BrewWeightChartPainter extends CustomPainter {
  /// Creates a painter for [samples] over a brew of [totalTime].
  BrewWeightChartPainter({
    required this.samples,
    required this.totalTime,
    required this.phaseStarts,
    required this.targets,
    required this.lineColor,
    required this.targetColor,
    required this.ruleColor,
    required this.labelStyle,
    required this.formatWeight,
    required this.formatTime,
  });

  /// The scale's readings, in order.
  final List<BrewSample> samples;

  /// How long the brew took, which is the right edge of the chart.
  final Duration totalTime;

  /// When each phase after the first began, drawn as boundaries.
  final List<Duration> phaseStarts;

  /// The recipe's target weights, one per phase that has one.
  final List<BrewWeightTarget> targets;

  /// The color of the weight line.
  final Color lineColor;

  /// The color of the target lines.
  final Color targetColor;

  /// The color of the phase boundaries and the baseline.
  final Color ruleColor;

  /// The style of the axis labels.
  final TextStyle labelStyle;

  /// Formats a weight for the top of the weight axis, such as "350 g".
  final String Function(double grams) formatWeight;

  /// Formats a time for the time axis, such as "3:12".
  final String Function(Duration time) formatTime;

  /// The room left below the plot for the time labels.
  static const double _bottomLabelSpace = 18;

  /// The room left above the plot for the weight label.
  static const double _topLabelSpace = 16;

  /// How much higher than the heaviest value the weight axis reaches, so the line does not touch the top.
  static const double _headroom = 1.1;

  /// The length of each dash in a target line, and of each gap.
  static const double _dashLength = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = Rect.fromLTRB(0, _topLabelSpace, size.width, size.height - _bottomLabelSpace);
    final double maxWeight = _maxWeight();
    final double totalMilliseconds = math.max(totalTime.inMilliseconds, 1).toDouble();

    double xFor(Duration time) => plot.left + plot.width * (time.inMilliseconds / totalMilliseconds).clamp(0, 1);
    double yFor(double grams) => plot.bottom - plot.height * (grams / maxWeight).clamp(0, 1);

    final Paint rule = Paint()
      ..color = ruleColor
      ..strokeWidth = 1;

    canvas.drawLine(plot.bottomLeft, plot.bottomRight, rule);
    for (final Duration start in phaseStarts) {
      final double x = xFor(start);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), rule);
    }

    final Paint targetPaint = Paint()
      ..color = targetColor
      ..strokeWidth = 1.5;
    for (final BrewWeightTarget target in targets) {
      _drawDashedLine(canvas, Offset(xFor(target.start), yFor(target.grams)), xFor(target.end), targetPaint);
    }

    if (samples.isNotEmpty) {
      final Path line = Path()..moveTo(xFor(samples.first.elapsed), yFor(samples.first.weightGrams));
      for (final BrewSample sample in samples.skip(1)) {
        line.lineTo(xFor(sample.elapsed), yFor(sample.weightGrams));
      }

      final Path fill = Path.from(line)
        ..lineTo(xFor(samples.last.elapsed), plot.bottom)
        ..lineTo(xFor(samples.first.elapsed), plot.bottom)
        ..close();
      canvas
        ..drawPath(fill, Paint()..color = lineColor.withValues(alpha: 0.08))
        ..drawPath(
          line,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round,
        );
    }

    _drawLabel(canvas, formatWeight(maxWeight / _headroom), Offset(plot.left, 0));
    _drawLabel(canvas, formatTime(Duration.zero), Offset(plot.left, plot.bottom + 2));
    _drawLabel(canvas, formatTime(totalTime), Offset(plot.right, plot.bottom + 2), alignRight: true);
  }

  /// The top of the weight axis: the larger of the heaviest reading and the highest target, with some headroom.
  double _maxWeight() {
    double top = 0;
    for (final BrewSample sample in samples) {
      top = math.max(top, sample.weightGrams);
    }
    for (final BrewWeightTarget target in targets) {
      top = math.max(top, target.grams);
    }
    return math.max(top, 1) * _headroom;
  }

  /// Draws a horizontal dashed line from [start] to the x position [endX].
  void _drawDashedLine(Canvas canvas, Offset start, double endX, Paint paint) {
    for (double x = start.dx; x < endX; x += _dashLength * 2) {
      canvas.drawLine(Offset(x, start.dy), Offset(math.min(x + _dashLength, endX), start.dy), paint);
    }
  }

  /// Draws [text] with its top-left corner at [position], or its top-right corner when [alignRight] is true.
  void _drawLabel(Canvas canvas, String text, Offset position, {bool alignRight = false}) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, alignRight ? position - Offset(painter.width, 0) : position);
    painter.dispose();
  }

  @override
  bool shouldRepaint(BrewWeightChartPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.totalTime != totalTime ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.targetColor != targetColor ||
      oldDelegate.ruleColor != ruleColor ||
      oldDelegate.labelStyle != labelStyle;
}
