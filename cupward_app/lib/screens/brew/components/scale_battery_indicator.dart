import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A small battery icon with the scale's remaining charge beside it, such as "82%".
///
/// The icon fills in steps with the charge. Below [lowPercent] it turns to a warning icon in the error color, so a scale
/// about to run out is noticed before the brew starts. Screen readers announce the level as a phrase, such as "Scale
/// battery 82 percent".
class ScaleBatteryIndicator extends StatelessWidget {
  /// Creates an indicator for a charge of [percent], from 0 to 100.
  const ScaleBatteryIndicator({required this.percent, super.key});

  /// The remaining charge, from 0 to 100.
  final int percent;

  /// The charge below which the battery is shown as low.
  static const int lowPercent = 15;

  /// The size of the icon.
  static const double _iconSize = 16;

  /// Returns the battery icon for a charge of [percent].
  ///
  /// Material's battery icons have seven bars plus a full icon, so the charge is divided into eighths.
  static IconData iconFor(int percent) {
    if (percent < lowPercent) {
      return Icons.battery_alert;
    }

    const List<IconData> levels = <IconData>[
      Icons.battery_0_bar,
      Icons.battery_1_bar,
      Icons.battery_2_bar,
      Icons.battery_3_bar,
      Icons.battery_4_bar,
      Icons.battery_5_bar,
      Icons.battery_6_bar,
      Icons.battery_full,
    ];

    final int level = (percent.clamp(0, 100) * (levels.length - 1) / 100).round();

    return levels[level];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final Color color = percent < lowPercent ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: strings.scaleBatterySemantics(percent),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The icons are drawn upright, so they are turned to lie on their side like a battery on a status bar.
          RotatedBox(
            quarterTurns: 1,
            child: Icon(iconFor(percent), size: _iconSize, color: color),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Insets.xxSmall),
            child: Text(strings.scaleBattery(percent), style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
