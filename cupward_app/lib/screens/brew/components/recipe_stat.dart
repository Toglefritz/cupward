import 'package:material_ui/material_ui.dart';

import '../../../theme/app_icon.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// One target of a recipe, such as its coffee dose: an icon above the value, with a caption below.
///
/// Screen readers announce the value and caption together, for example "20.0 g, Coffee". The icon only illustrates
/// the caption, so it is left out of the announcement.
class RecipeStat extends StatelessWidget {
  /// Creates a stat that shows [value] under [icon], captioned with [label].
  const RecipeStat({required this.icon, required this.value, required this.label, super.key});

  /// The icon above the value.
  final AppIcon icon;

  /// The formatted value, such as "20.0 g".
  final String value;

  /// What the value is, such as "Coffee".
  final String label;

  /// The size of the icon, in logical pixels.
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(icon.path, width: _iconSize, height: _iconSize, excludeFromSemantics: true),
          Padding(
            padding: const EdgeInsets.only(top: Insets.xSmall),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child:
                  Text(value, maxLines: 1, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
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
        ],
      ),
    );
  }
}
