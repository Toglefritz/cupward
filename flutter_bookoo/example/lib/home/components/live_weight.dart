import 'package:material_ui/material_ui.dart';

/// The current weight as a large figure with its unit.
class LiveWeight extends StatelessWidget {
  /// Creates the display for [grams], or a placeholder when it is null.
  const LiveWeight({required this.grams, super.key});

  /// The weight in grams, or null before the first reading.
  final double? grams;

  /// Formats [value] to the scale's display resolution of 0.1 g.
  ///
  /// Values that round to zero are shown without a sign, so a freshly tared
  /// scale reads "0.0" rather than "-0.0".
  static String format(double? value) {
    if (value == null) {
      return '–';
    }
    final String fixed = value.toStringAsFixed(1);
    return fixed == '-0.0' ? '0.0' : fixed;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Live weight', style: text.titleMedium),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(format(grams), style: text.displayLarge),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text('g', style: text.headlineMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
