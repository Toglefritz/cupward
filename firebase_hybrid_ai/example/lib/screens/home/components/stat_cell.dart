import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// A caption above a monospaced value, used in `StatusStats`.
class StatCell extends StatelessWidget {
  /// Creates a cell showing [value] under [label].
  const new({required this.label, required this.value, super.key});

  /// What the value measures, such as "Platform".
  final String label;

  /// The formatted value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xxSmall, vertical: Insets.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: text.bodyMedium),
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: text.headlineSmall, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}
