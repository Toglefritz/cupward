import '../../../components/recipe_stats_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/feedback/change_direction.dart';
import '../../../models/feedback/recipe_parameter.dart';

/// The display text for suggested changes: the name of each brewing variable, the word for which way it changes, and
/// its values with their units.
///
/// The direction words depend on the variable, so a finer grind reads "Finer" and a longer bloom reads "Longer",
/// rather than both reading "More".
abstract final class RecipeParameterLabels {
  /// Returns the name of [parameter], such as "Grind size".
  static String nameFor(RecipeParameter parameter, AppLocalizations strings) {
    switch (parameter) {
      case RecipeParameter.grindSize:
        return strings.parameterGrindSize;
      case RecipeParameter.coffeeDose:
        return strings.parameterCoffeeDose;
      case RecipeParameter.waterAmount:
        return strings.parameterWaterAmount;
      case RecipeParameter.bloomWater:
        return strings.parameterBloomWater;
      case RecipeParameter.bloomTime:
        return strings.parameterBloomTime;
      case RecipeParameter.pourRate:
        return strings.parameterPourRate;
      case RecipeParameter.waterTemperature:
        return strings.parameterWaterTemperature;
      case RecipeParameter.brewTime:
        return strings.parameterBrewTime;
      case RecipeParameter.steepTime:
        return strings.parameterSteepTime;
    }
  }

  /// Returns the word for changing [parameter] in [direction], such as "Finer" for a grind size increase.
  static String directionFor(RecipeParameter parameter, ChangeDirection direction, AppLocalizations strings) {
    final bool up = direction == ChangeDirection.increase;
    switch (parameter) {
      case RecipeParameter.grindSize:
        return up ? strings.directionFiner : strings.directionCoarser;
      case RecipeParameter.coffeeDose:
      case RecipeParameter.waterAmount:
      case RecipeParameter.bloomWater:
        return up ? strings.directionMore : strings.directionLess;
      case RecipeParameter.bloomTime:
      case RecipeParameter.brewTime:
      case RecipeParameter.steepTime:
        return up ? strings.directionLonger : strings.directionShorter;
      case RecipeParameter.pourRate:
        return up ? strings.directionFaster : strings.directionSlower;
      case RecipeParameter.waterTemperature:
        return up ? strings.directionHotter : strings.directionCooler;
    }
  }

  /// Formats [value] of [parameter] with its unit, such as "20.0 g" for a coffee dose or "0:45" for a bloom time.
  ///
  /// Only parameters that the recipe stores have values. Others return the value as a plain number.
  static String formatValue(RecipeParameter parameter, double value, AppLocalizations strings) {
    final String locale = strings.localeName;
    switch (parameter) {
      case RecipeParameter.coffeeDose:
        return strings.recipeGrams(RecipeStatsRow.formatCoffeeGrams(value, locale));
      case RecipeParameter.waterAmount:
      case RecipeParameter.bloomWater:
        return strings.recipeGrams(RecipeStatsRow.formatWaterGrams(value, locale));
      case RecipeParameter.bloomTime:
      case RecipeParameter.brewTime:
      case RecipeParameter.steepTime:
        return RecipeStatsRow.formatBrewTime(Duration(seconds: value.round()));
      case RecipeParameter.grindSize:
      case RecipeParameter.pourRate:
      case RecipeParameter.waterTemperature:
        return RecipeStatsRow.formatWaterGrams(value, locale);
    }
  }
}
