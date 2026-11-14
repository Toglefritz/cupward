import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the latest [BookooScaleReading], or a waiting message before the
/// first one arrives.
class ReadingPanel extends StatelessWidget {
  /// Creates a panel for [reading].
  const ReadingPanel({required this.reading, super.key});

  /// The latest reading, or null when none has arrived yet.
  final BookooScaleReading? reading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BookooScaleReading? current = reading;

    if (current == null) {
      return Text('Waiting for readings...', style: theme.textTheme.bodyMedium);
    }

    final double seconds = current.elapsed.inMilliseconds / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${current.weightGrams.toStringAsFixed(2)} g',
          style: theme.textTheme.displaySmall,
        ),
        Text(
          'Flow ${current.flowRateGramsPerSecond.toStringAsFixed(2)} g/s'
          '   Timer ${seconds.toStringAsFixed(1)} s'
          '   Battery ${current.batteryPercent}%',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
