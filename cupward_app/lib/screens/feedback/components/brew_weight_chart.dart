import 'package:material_ui/material_ui.dart';

import '../../../components/recipe_stats_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/brews/brew_phase_record.dart';
import '../../../models/brews/brew_record.dart';
import '../../../models/recipes/brew_phase.dart';
import '../../../theme/context_theme_extension.dart';
import 'brew_phase_table.dart';
import 'brew_weight_chart_painter.dart';
import 'brew_weight_target.dart';

/// A chart of the water weight during a brew, against the recipe's target for each phase.
///
/// The weight line uses the theme's green, the targets the copper accent, and the phase boundaries the cards' hairline
/// color, so the chart reads as part of the card it sits in. Screen readers announce a one-line summary of the chart,
/// with the final weight and the total time, since the shape of the line cannot be read aloud.
class BrewWeightChart extends StatelessWidget {
  /// Creates a chart of the readings in [record].
  const BrewWeightChart({required this.record, super.key});

  /// The brew whose readings are shown.
  final BrewRecord record;

  /// The height of the chart, including its labels.
  static const double _height = 180;

  /// Returns the target weight for each recorded phase that has one, spanning the time that phase lasted.
  static List<BrewWeightTarget> targetsFor(BrewRecord record) {
    final List<BrewWeightTarget> targets = <BrewWeightTarget>[];
    for (int index = 0; index < record.phases.length; index++) {
      final BrewPhaseRecord phaseRecord = record.phases[index];
      final double? grams = _phaseWithId(record, phaseRecord.phaseId)?.targetWeightGrams;
      if (grams != null) {
        targets.add(BrewWeightTarget(start: phaseRecord.startedAt, end: record.endOfPhase(index), grams: grams));
      }
    }
    return targets;
  }

  /// Returns the recipe's phase with [id], or null if the recipe has none.
  static BrewPhase? _phaseWithId(BrewRecord record, String id) {
    for (final BrewPhase phase in record.recipe.phases) {
      if (phase.id == id) {
        return phase;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final String locale = strings.localeName;
    final double finalWeight = record.finalWeightGrams ?? 0;

    String formatWeight(double grams) => strings.recipeGrams(BrewPhaseTable.formatWholeGrams(grams, locale));

    // The chart is its own node, announced as an image, so its summary is not merged into the card's heading.
    return Semantics(
      container: true,
      image: true,
      label: strings.brewSummaryChartSemantics(
        formatWeight(finalWeight),
        RecipeStatsRow.formatBrewTime(record.totalTime),
      ),
      excludeSemantics: true,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: CustomPaint(
          painter: BrewWeightChartPainter(
            samples: record.samples,
            totalTime: record.totalTime,
            phaseStarts: record.phases.skip(1).map((BrewPhaseRecord phase) => phase.startedAt).toList(),
            targets: targetsFor(record),
            lineColor: theme.colorScheme.primary,
            targetColor: context.cupwardColors.accent,
            ruleColor: context.cupwardColors.cardBorder,
            labelStyle: theme.textTheme.labelSmall ?? const TextStyle(fontSize: 12),
            formatWeight: formatWeight,
            formatTime: RecipeStatsRow.formatBrewTime,
          ),
        ),
      ),
    );
  }
}
