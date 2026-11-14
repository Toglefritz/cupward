import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// A row of single-choice chips, used to pick one value from a short list.
///
/// The selected chip is filled with the primary color. The generic type [T] is the value that each chip stands for.
class OptionChips<T> extends StatelessWidget {
  /// Creates chips for each entry of [options], with [selected] highlighted.
  ///
  /// [onSelected] is null while the control is disabled.
  const new({required this.options, required this.selected, required this.onSelected, super.key});

  /// The chip labels, keyed by the value each chip selects, in display order.
  final Map<T, String> options;

  /// The value whose chip is highlighted.
  final T selected;

  /// Called with the value of the chip that the user taps, or null to disable the chips.
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Wrap(
      spacing: Insets.xSmall,
      runSpacing: Insets.xSmall,
      children: <Widget>[
        for (final MapEntry<T, String> option in options.entries)
          ChoiceChip(
            label: Text(option.value),
            selected: option.key == selected,
            showCheckmark: false,
            onSelected: onSelected == null ? null : (bool isSelected) => onSelected!(option.key),
            backgroundColor: colors.surface,
            selectedColor: colors.primary,
            disabledColor: colors.surface,
            side: BorderSide(color: option.key == selected ? colors.primary : colors.outline),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: option.key == selected ? colors.onPrimary : colors.onSurface,
            ),
          ),
      ],
    );
  }
}
