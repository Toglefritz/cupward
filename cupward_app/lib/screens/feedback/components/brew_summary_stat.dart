import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// One measured result of a brew, such as its total time: the value, a caption, and the recipe's target below.
///
/// It follows the recipe card's stats, without an icon, so the measured value reads against the target the user aimed
/// for. Screen readers announce the three lines together, for example "3:12, Time, Target 3:00".
class BrewSummaryStat extends StatelessWidget {
  /// Creates a stat that shows [value] captioned with [label], and [target] below when there is one.
  const BrewSummaryStat({required this.value, required this.label, this.target, super.key});

  /// The formatted measured value, such as "318 g".
  final String value;

  /// What the value is, such as "Water".
  final String label;

  /// The formatted recipe target, such as "Target 320 g", or null if the value has no target.
  final String? target;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final String? targetText = target;

    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.micro),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (targetText != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.micro),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  targetText,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: context.cupwardColors.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
