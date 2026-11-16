import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/recipe_stats_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/brews/brew_record.dart';
import '../../../models/recipes/brew_phase.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import '../../brew/components/brew_phase_labels.dart';

/// A table of the steps of a brew: how long each took and, with scale readings, the weight at its end against the
/// recipe's target.
///
/// Each row is one recorded phase, named as in the brewing screen's phase indicator, such as "Pour 2". Without scale
/// readings, the weight columns are left out. Rows are separated by the cards' hairline rules.
class BrewPhaseTable extends StatelessWidget {
  /// Creates a table of the phases in [record].
  const BrewPhaseTable({required this.record, super.key});

  /// The brew whose phases are listed.
  final BrewRecord record;

  /// Formats a weight as whole grams, such as "318". The table compares steps, where tenths of a gram do not matter.
  static String formatWholeGrams(double grams, String locale) => NumberFormat('#,##0', locale).format(grams);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final String locale = strings.localeName;
    final bool showWeights = record.hasScaleReadings;
    final List<BrewPhase> recipePhases = record.recipe.phases;

    final TextStyle? headerStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final TextStyle? cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final TextStyle? targetStyle = cellStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    String grams(double? value) =>
        value == null ? strings.scaleNoReading : strings.recipeGrams(formatWholeGrams(value, locale));

    Widget cell(String text, TextStyle? style, {bool alignEnd = true}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.xSmall),
        child: Text(text, style: style, textAlign: alignEnd ? TextAlign.end : TextAlign.start),
      );
    }

    final List<TableRow> rows = <TableRow>[
      TableRow(
        children: <Widget>[
          cell(strings.brewSummaryStepHeader, headerStyle, alignEnd: false),
          cell(strings.brewSummaryTimeHeader, headerStyle),
          if (showWeights) cell(strings.brewSummaryWeightHeader, headerStyle),
          if (showWeights) cell(strings.brewSummaryTargetHeader, headerStyle),
        ],
      ),
    ];

    for (int index = 0; index < record.phases.length; index++) {
      final int recipeIndex = recipePhases.indexWhere((BrewPhase phase) => phase.id == record.phases[index].phaseId);
      if (recipeIndex < 0) {
        continue;
      }
      rows.add(
        TableRow(
          children: <Widget>[
            cell(BrewPhaseLabels.labelFor(recipePhases, recipeIndex, strings), cellStyle, alignEnd: false),
            cell(RecipeStatsRow.formatBrewTime(record.durationOfPhase(index)), cellStyle),
            if (showWeights) cell(grams(record.weightAtEndOfPhase(index)), cellStyle),
            if (showWeights) cell(grams(recipePhases[recipeIndex].targetWeightGrams), targetStyle),
          ],
        ),
      );
    }

    return Table(
      columnWidths: <int, TableColumnWidth>{
        0: const FlexColumnWidth(2),
        1: const FlexColumnWidth(),
        if (showWeights) 2: const FlexColumnWidth(),
        if (showWeights) 3: const FlexColumnWidth(),
      },
      border: TableBorder(horizontalInside: BorderSide(color: context.cupwardColors.cardBorder)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }
}
