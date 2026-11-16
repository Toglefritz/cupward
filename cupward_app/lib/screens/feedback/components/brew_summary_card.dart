import 'package:material_ui/material_ui.dart';

import '../../../components/recipe_stats_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/brews/brew_record.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import '../../brew/components/scale_flow_reading.dart';
import 'brew_phase_table.dart';
import 'brew_summary_stat.dart';
import 'brew_weight_chart.dart';

/// A card that summarizes a finished brew against its recipe.
///
/// Under a "Your brew" heading, a row of results compares the brew with the recipe's targets: the total time, the
/// water weight, and the fastest pour. A chart of the weight over time follows, and then a table of the steps. Without
/// scale readings, the weight results and the chart are replaced by a short note, and the table lists step times only.
///
/// The card matches the recipe card above it: a cream surface with a hairline border, rounded corners, and rules
/// between the results.
class BrewSummaryCard extends StatelessWidget {
  /// Creates a summary of [record].
  const BrewSummaryCard({required this.record, super.key});

  /// The brew summarized.
  final BrewRecord record;

  /// The corner radius of the card, matching the recipe card.
  static const double _cornerRadius = 16;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final String locale = strings.localeName;
    final Color ruleColor = context.cupwardColors.cardBorder;
    final double? finalWeight = record.finalWeightGrams;
    final double? peakFlow = record.peakFlowGramsPerSecond;

    final List<Widget> stats = <Widget>[
      BrewSummaryStat(
        value: RecipeStatsRow.formatBrewTime(record.totalTime),
        label: strings.recipeBrewTimeLabel,
        target: strings.brewSummaryTarget(RecipeStatsRow.formatBrewTime(record.recipe.brewTime)),
      ),
      BrewSummaryStat(
        value: finalWeight == null
            ? strings.scaleNoReading
            : strings.recipeGrams(RecipeStatsRow.formatWaterGrams(_toTenth(finalWeight), locale)),
        label: strings.recipeWaterLabel,
        target: strings.brewSummaryTarget(
          strings.recipeGrams(RecipeStatsRow.formatWaterGrams(record.recipe.waterGrams, locale)),
        ),
      ),
      BrewSummaryStat(
        value: peakFlow == null
            ? strings.scaleNoReading
            : strings.scaleFlowRate(ScaleFlowReading.formatRate(peakFlow, locale)),
        label: strings.brewSummaryPeakFlowLabel,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cupwardColors.cardSurface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: ruleColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.medium, vertical: Insets.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(strings.brewSummaryTitle, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.small),
              child: Divider(color: ruleColor),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int index = 0; index < stats.length; index++) ...<Widget>[
                    if (index > 0) VerticalDivider(width: 1, color: ruleColor),
                    Expanded(child: Center(child: stats[index])),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.medium),
              child: record.hasScaleReadings
                  ? BrewWeightChart(record: record)
                  : Text(
                      strings.brewSummaryNoReadings,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.small),
              child: BrewPhaseTable(record: record),
            ),
          ],
        ),
      ),
    );
  }

  /// Rounds [grams] to the nearest tenth, the precision of the scale.
  static double _toTenth(double grams) => (grams * 10).roundToDouble() / 10;
}
