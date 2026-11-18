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
/// * Brew time: the target brew time. For a recipe with a steep, the steep changes by the same amount, since the steep
///   is the part of an immersion brew that the brewing screen times. It must stay longer than zero.
/// * Steep time: the steep's duration, with the brew time changed by the same amount.
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
        return _setBrewTime(recipe, Duration(seconds: value.round()));
      case RecipeParameter.steepTime:
        return _setSteepTime(recipe, Duration(seconds: value.round()));
      case RecipeParameter.grindSize:
      case RecipeParameter.pourRate:
      case RecipeParameter.waterTemperature:
        return null;
    }
  }

  /// Whether [suggestion] can be applied to [recipe].
  static bool canApply(BrewRecipe recipe, RecipeSuggestion suggestion) => apply(recipe, suggestion) != null;

  /// Sets the brew time to [time], and moves the steep, if there is one, by the same amount. Returns null if the steep
  /// would no longer last longer than zero.
  static BrewRecipe? _setBrewTime(BrewRecipe recipe, Duration time) {
    final int steepIndex = recipe.phases.indexWhere((BrewPhase phase) => phase.kind == BrewPhaseKind.steep);
    final Duration? steepTime = steepIndex < 0 ? null : recipe.phases[steepIndex].duration;
    if (steepTime == null) {
      return recipe.copyWith(brewTime: time);
    }
    final Duration newSteep = steepTime + (time - recipe.brewTime);
    if (newSteep <= Duration.zero) {
      return null;
    }
    return _replaceAt(
      recipe.copyWith(brewTime: time),
      steepIndex,
      (BrewPhase steep) => steep.copyWith(duration: newSteep),
    );
  }

  /// Sets the steep's duration to [time], and moves the brew time by the same amount. Returns null if the recipe has
  /// no timed steep, or if the brew time would no longer be longer than zero.
  static BrewRecipe? _setSteepTime(BrewRecipe recipe, Duration time) {
    final int steepIndex = recipe.phases.indexWhere((BrewPhase phase) => phase.kind == BrewPhaseKind.steep);
    final Duration? steepTime = steepIndex < 0 ? null : recipe.phases[steepIndex].duration;
    if (steepTime == null) {
      return null;
    }
    final Duration brewTime = recipe.brewTime + (time - steepTime);
    if (brewTime <= Duration.zero) {
      return null;
    }
    return _replaceAt(
      recipe.copyWith(brewTime: brewTime),
      steepIndex,
      (BrewPhase steep) => steep.copyWith(duration: time),
    );
  }

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
    return bloomIndex < 0 ? null : _replaceAt(recipe, bloomIndex, change);
  }

  /// Returns [recipe] with the phase at [index] replaced by [change] applied to it.
  static BrewRecipe _replaceAt(BrewRecipe recipe, int index, BrewPhase Function(BrewPhase phase) change) {
    return recipe.copyWith(
      phases: <BrewPhase>[
        for (int i = 0; i < recipe.phases.length; i++)
          if (i == index) change(recipe.phases[i]) else recipe.phases[i],
      ],
    );
  }

  /// Rounds [value] to the nearest tenth, the scale's precision.
  static double _roundTenth(double value) => (value * 10).roundToDouble() / 10;
}
