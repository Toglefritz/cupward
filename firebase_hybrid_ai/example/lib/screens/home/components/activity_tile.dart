import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import '../models/activity_entry.dart';
import 'status_dot.dart';

/// One row of the activity log: a status dot, the message, and the time.
class ActivityTile extends StatelessWidget {
  /// Creates a row for [entry].
  const new({required this.entry, super.key});

  /// The entry shown.
  final ActivityEntry entry;

  /// Formats [time] as a 24-hour clock with seconds, such as "10:24:31".
  static String formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = entry.isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: StatusDot(color: color, size: Insets.xSmall),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.small),
              child: SelectableText(
                entry.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: entry.isError ? color : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.micro),
            child: Text(
              formatTime(entry.time),
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
