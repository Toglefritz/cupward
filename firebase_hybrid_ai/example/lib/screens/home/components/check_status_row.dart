import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import 'status_dot.dart';

/// The state of the status check itself.
///
/// This describes the check, not the model. The model's availability is shown by the figure below it.
class CheckStatusRow extends StatelessWidget {
  /// Creates the row.
  const new({required this.isChecking, required this.hasFailed, super.key});

  /// The height of the row, which keeps the content below from shifting when the label changes.
  static const double _rowHeight = 40;

  /// Whether a check is running.
  final bool isChecking;

  /// Whether the most recent check failed.
  final bool hasFailed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color dotColor;
    final String label;
    if (isChecking) {
      dotColor = colors.tertiary;
      label = 'Checking';
    } else if (hasFailed) {
      dotColor = colors.error;
      label = 'Check failed';
    } else {
      dotColor = colors.primary;
      label = 'Checked';
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowHeight),
      child: Row(
        children: <Widget>[
          StatusDot(color: dotColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: Insets.small),
              child: Text(label, style: theme.textTheme.titleMedium),
            ),
          ),
        ],
      ),
    );
  }
}
