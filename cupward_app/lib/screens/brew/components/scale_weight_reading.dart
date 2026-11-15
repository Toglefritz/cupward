import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';

/// The scale's live weight, the main figure of the scale panel, such as "18.4 g".
///
/// It uses the theme's serif display face, scaled down to fit the panel, with tabular figures so the number does not
/// shift as the digits change. A dash stands in for the weight when there is no reading.
///
/// The weight changes about ten times a second, so it is not marked as a live region. Screen readers read it when the
/// user moves to it rather than announcing every change.
class ScaleWeightReading extends StatelessWidget {
  /// Creates a reading that shows [grams], or a dash when it is null.
  const ScaleWeightReading({required this.grams, super.key});

  /// The weight on the scale, or null when there is no reading.
  final double? grams;

  /// The largest size of the figure. It shrinks below this when the panel is narrow.
  static const double _fontSize = 44;

  /// Formats a weight with one decimal place, such as "18.4". The scale measures to a tenth of a gram.
  static String formatGrams(double grams, String locale) => NumberFormat('0.0', locale).format(grams);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final double? weight = grams;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        weight == null ? strings.scaleNoReading : strings.scaleGrams(formatGrams(weight, strings.localeName)),
        maxLines: 1,
        style: theme.textTheme.displayLarge?.copyWith(fontSize: _fontSize),
      ),
    );
  }
}
