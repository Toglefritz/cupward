import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import 'column_rule.dart';
import 'stat_cell.dart';

/// Flow rate, scale timer, and battery from the latest reading, in three
/// columns separated by rules.
class ReadingStats extends StatelessWidget {
  /// Creates the row for [reading], showing placeholders when it is null.
  const ReadingStats({required this.reading, super.key});

  /// The latest reading, or null before the first.
  final BookooScaleReading? reading;

  /// Placeholder shown before the first reading.
  static const String _empty = '–';

  /// Formats [elapsed] as minutes and seconds, such as "01:05".
  static String formatTimer(Duration elapsed) {
    final String minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final BookooScaleReading? current = reading;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: StatCell(
              label: 'Flow',
              value: current == null
                  ? _empty
                  : '${current.flowRateGramsPerSecond.toStringAsFixed(1)} g/s',
            ),
          ),
          const ColumnRule(),
          Expanded(
            child: StatCell(
              label: 'Scale timer',
              value: current == null ? _empty : formatTimer(current.elapsed),
            ),
          ),
          const ColumnRule(),
          Expanded(
            child: StatCell(
              label: 'Battery',
              value: current == null ? _empty : '${current.batteryPercent}%',
            ),
          ),
        ],
      ),
    );
  }
}
