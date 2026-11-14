import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// Example prompts that fill the prompt field when tapped.
///
/// Each one is short enough to fit within the on-device model's limits and has a self-contained answer, so it works
/// as a quick check that a model is responding.
class SamplePrompts extends StatelessWidget {
  /// Creates the list. [onSelected] receives the text of the prompt that the user taps, or is null to disable them.
  const new({required this.onSelected, super.key});

  /// The prompts offered, in display order.
  static const List<String> prompts = <String>[
    'What is the airspeed velocity of an unladen swallow?',
    'Explain how magnets work in two sentences.',
    'Write a haiku about the time travel.',
  ];

  /// Called with a prompt when the user taps it, or null while the prompts are disabled.
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Wrap(
      spacing: Insets.xSmall,
      runSpacing: Insets.xSmall,
      children: <Widget>[
        for (final String prompt in prompts)
          ActionChip(
            label: Text(prompt),
            onPressed: onSelected == null ? null : () => onSelected!(prompt),
            backgroundColor: colors.surface,
            side: BorderSide(color: colors.outlineVariant),
            labelStyle: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}
