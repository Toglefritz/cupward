import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/recipes/brew_recipe.dart';
import '../theme/app_icon.dart';
import '../theme/context_theme_extension.dart';
import '../theme/insets.dart';
import 'recipe_stat.dart';

/// A recipe's targets in equal columns, separated by hairline rules: coffee, water, brew time, and yield.
class RecipeStatsRow extends StatelessWidget {
  /// Creates the row for [recipe].
  const RecipeStatsRow({required this.recipe, super.key});

  /// The recipe whose targets are shown.
  final BrewRecipe recipe;

  /// Formats a coffee dose with one decimal place, such as "20.0", because doses are weighed to a tenth of a gram.
  static String formatCoffeeGrams(double grams, String locale) => NumberFormat('0.0', locale).format(grams);

  /// Formats a water weight with no decimal places for whole grams, such as "320", and one place otherwise.
  static String formatWaterGrams(double grams, String locale) => NumberFormat('#,##0.#', locale).format(grams);

  /// Formats a brew time as minutes and seconds, such as "3:00".
  static String formatBrewTime(Duration time) {
    final String seconds = (time.inSeconds % 60).toString().padLeft(2, '0');

    return '${time.inMinutes}:$seconds';
  }

  /// Formats a yield as whole milliliters, such as "320". The yield is an estimate, so decimals would mislead.
  static String formatYieldMilliliters(double milliliters, String locale) =>
      NumberFormat('#,##0', locale).format(milliliters);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final String locale = strings.localeName;

    final List<Widget> stats = <Widget>[
      RecipeStat(
        icon: AppIcon.coffee,
        value: strings.recipeGrams(formatCoffeeGrams(recipe.coffeeGrams, locale)),
        label: strings.recipeCoffeeLabel,
      ),
      RecipeStat(
        icon: AppIcon.water,
        value: strings.recipeGrams(formatWaterGrams(recipe.waterGrams, locale)),
        label: strings.recipeWaterLabel,
      ),
      RecipeStat(icon: AppIcon.brewTime, value: formatBrewTime(recipe.brewTime), label: strings.recipeBrewTimeLabel),
      RecipeStat(
        icon: AppIcon.brewYield,
        value: strings.recipeYieldMilliliters(formatYieldMilliliters(recipe.yieldMilliliters, locale)),
        label: strings.recipeYieldLabel,
      ),
    ];

    final Color ruleColor = context.cupwardColors.cardBorder;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < stats.length; index++) ...<Widget>[
            if (index > 0) VerticalDivider(width: 1, color: ruleColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xxSmall),
                child: Center(child: stats[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
