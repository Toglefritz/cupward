import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import 'status_dot.dart';

/// The state of the work the app is doing, such as a status check or a model download.
///
/// This describes the operation, not the model. The model's availability is shown by the figure below it.
class CheckStatusRow extends StatelessWidget {
  /// Creates the row.
  const new({required this.isBusy, required this.busyLabel, required this.hasFailed, super.key});

  /// The height of the row, which keeps the content below from shifting when the label changes.
  static const double _rowHeight = 40;

  /// Whether an operation is running.
  final bool isBusy;

  /// The label shown while [isBusy], such as "Checking" or "Downloading".
  final String busyLabel;

  /// Whether the most recent operation failed.
  final bool hasFailed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color dotColor;
    final String label;
    if (isBusy) {
      dotColor = colors.tertiary;
      label = busyLabel;
    } else if (hasFailed) {
      dotColor = colors.error;
      label = 'Failed';
    } else {
      dotColor = colors.primary;
      label = 'Ready';
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
