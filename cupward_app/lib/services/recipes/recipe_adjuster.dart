import '../../models/feedback/recipe_parameter.dart';
import '../../models/feedback/recipe_suggestion.dart';
import '../../models/recipes/brew_phase.dart';
import '../../models/recipes/brew_phase_kind.dart';
import '../../models/recipes/brew_recipe.dart';

/// Applies a suggestion from brew feedback to a recipe.
///
/// Only suggestions with a new value can be applied, which `RecipeSuggestion.hasValueChange` reports. The parser has
/// already checked that the value moves the recipe the way the suggestion says, by a small step. Each parameter
/// changes the recipe as follows:
///
/// * Coffee dose: the coffee weight.
/// * Water amount: the total water, with every phase's target weight and the yield scaled by the same ratio. The
///   targets are cumulative, and the last one is the total, so scaling them keeps each pour's share of the water.
/// * Bloom water: the bloom's target weight. It must stay below the next phase's target, so the first pour still adds
///   water.
/// * Bloom time: the bloom's rest.
/// * Brew time: the target brew time.
///
/// Grind size, pour rate, and water temperature are not stored in a recipe, so they cannot be applied.
abstract final class RecipeAdjuster {
  /// Returns [recipe] with [suggestion] applied, or null if it cannot be applied to [recipe].
  static BrewRecipe? apply(BrewRecipe recipe, RecipeSuggestion suggestion) {
    final double? value = suggestion.suggestedValue;
    if (!suggestion.hasValueChange || value == null || value <= 0) {
      return null;
    }

    switch (suggestion.parameter) {
      case RecipeParameter.coffeeDose:
        return recipe.copyWith(coffeeGrams: _roundTenth(value));
      case RecipeParameter.waterAmount:
        return _scaleWater(recipe, _roundTenth(value));
      case RecipeParameter.bloomWater:
        return _setBloomWater(recipe, _roundTenth(value));
      case RecipeParameter.bloomTime:
        return _updateBloom(recipe, (BrewPhase bloom) => bloom.copyWith(duration: Duration(seconds: value.round())));
      case RecipeParameter.brewTime:
        return recipe.copyWith(brewTime: Duration(seconds: value.round()));
      case RecipeParameter.grindSize:
      case RecipeParameter.pourRate:
      case RecipeParameter.waterTemperature:
        return null;
    }
  }

  /// Whether [suggestion] can be applied to [recipe].
  static bool canApply(BrewRecipe recipe, RecipeSuggestion suggestion) => apply(recipe, suggestion) != null;

  /// Sets the total water to [grams], scaling every target weight and the yield by the same ratio.
  static BrewRecipe _scaleWater(BrewRecipe recipe, double grams) {
    final double ratio = grams / recipe.waterGrams;
    return recipe.copyWith(
      waterGrams: grams,
      yieldMilliliters: _roundTenth(recipe.yieldMilliliters * ratio),
      phases: <BrewPhase>[
        for (final BrewPhase phase in recipe.phases)
          if (phase.targetWeightGrams == null)
            phase
          else
            phase.copyWith(targetWeightGrams: _roundTenth(phase.targetWeightGrams! * ratio)),
      ],
    );
  }

  /// Sets the bloom's target weight to [grams], or returns null if that would reach the next target.
  static BrewRecipe? _setBloomWater(BrewRecipe recipe, double grams) {
    final int bloomIndex = recipe.phases.indexWhere((BrewPhase phase) => phase.kind == BrewPhaseKind.bloom);
    if (bloomIndex < 0) {
      return null;
    }
    for (final BrewPhase later in recipe.phases.skip(bloomIndex + 1)) {
      final double? target = later.targetWeightGrams;
      if (target != null) {
        if (grams >= target) {
          return null;
        }
        break;
      }
    }
    return _updateBloom(recipe, (BrewPhase bloom) => bloom.copyWith(targetWeightGrams: grams));
  }

  /// Returns [recipe] with its bloom replaced by [change] applied to it, or null if it has no bloom.
  static BrewRecipe? _updateBloom(BrewRecipe recipe, BrewPhase Function(BrewPhase bloom) change) {
    final int bloomIndex = recipe.phases.indexWhere((BrewPhase phase) => phase.kind == BrewPhaseKind.bloom);
    if (bloomIndex < 0) {
      return null;
    }
    return recipe.copyWith(
      phases: <BrewPhase>[
        for (int index = 0; index < recipe.phases.length; index++)
          if (index == bloomIndex) change(recipe.phases[index]) else recipe.phases[index],
      ],
    );
  }

  /// Rounds [value] to the nearest tenth, the scale's precision.
  static double _roundTenth(double value) => (value * 10).roundToDouble() / 10;
}
