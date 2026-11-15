import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// How fast water is being poured, such as "3.2 g/s", with a "Flow" caption below it.
///
/// It takes the place of the tare button while water is poured, when the rate matters more than zeroing the scale. The
/// figure uses the theme's monospace face for secondary live values. Screen readers announce the figure and caption
/// together.
class ScaleFlowReading extends StatelessWidget {
  /// Creates a reading that shows [gramsPerSecond], or a dash when it is null.
  const ScaleFlowReading({required this.gramsPerSecond, super.key});

  /// The rate at which the weight is rising, or null when there is no reading.
  final double? gramsPerSecond;

  /// The size of the figure.
  static const double _fontSize = 20;

  /// Formats a rate with one decimal place, such as "3.2".
  static String formatRate(double gramsPerSecond, String locale) => NumberFormat('0.0', locale).format(gramsPerSecond);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final double? rate = gramsPerSecond;

    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rate == null ? strings.scaleNoReading : strings.scaleFlowRate(formatRate(rate, strings.localeName)),
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: _fontSize),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Insets.micro),
            child: Text(
              strings.scaleFlowLabel,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
