import 'package:material_ui/material_ui.dart';

/// A scrollable, selectable, monospaced list of log lines.
class LogPanel extends StatelessWidget {
  /// Creates a panel showing [lines].
  const LogPanel({required this.lines, super.key});

  /// The lines to show, oldest first.
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          reverse: true,
          child: SizedBox(
            width: double.infinity,
            child: SelectableText(
              lines.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
