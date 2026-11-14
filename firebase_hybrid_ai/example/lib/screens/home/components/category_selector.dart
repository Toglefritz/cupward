import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';

/// A three-way control for choosing which Gemini Nano release to check and download.
class CategorySelector extends StatelessWidget {
  /// Creates the selector showing [selected].
  ///
  /// [onSelected] is null while an operation is running, which disables the control.
  const new({required this.selected, required this.onSelected, super.key});

  /// The release that is currently chosen.
  final OnDeviceModelCategory selected;

  /// Called with the new release when the user picks one, or null to disable the control.
  final ValueChanged<OnDeviceModelCategory>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Gemini Nano release', style: theme.textTheme.bodyMedium),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xSmall),
          child: SegmentedButton<OnDeviceModelCategory>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<OnDeviceModelCategory>>[
              ButtonSegment<OnDeviceModelCategory>(value: OnDeviceModelCategory.stable, label: Text('Stable')),
              ButtonSegment<OnDeviceModelCategory>(value: OnDeviceModelCategory.preview, label: Text('Preview')),
              ButtonSegment<OnDeviceModelCategory>(value: OnDeviceModelCategory.previewFast, label: Text('Fast')),
            ],
            selected: <OnDeviceModelCategory>{selected},
            onSelectionChanged: onSelected == null
                ? null
                : (Set<OnDeviceModelCategory> values) => onSelected!(values.first),
            style: SegmentedButton.styleFrom(
              foregroundColor: colors.onSurface,
              selectedBackgroundColor: colors.primary,
              selectedForegroundColor: colors.onPrimary,
              side: BorderSide(color: colors.outline),
              textStyle: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
