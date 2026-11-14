import 'package:material_ui/material_ui.dart';

/// A labeled switch that chooses between a streamed response and one that arrives all at once.
class StreamToggle extends StatelessWidget {
  /// Creates the toggle showing [value]. [onChanged] is null while the toggle is disabled.
  const new({required this.value, required this.onChanged, super.key});

  /// Whether the response is streamed.
  final bool value;

  /// Called with the new value when the user flips the switch, or null to disable it.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(child: Text('Stream the response', style: theme.textTheme.titleMedium)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
