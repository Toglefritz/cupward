import 'package:cupward/models/feedback/change_direction.dart';
import 'package:cupward/models/feedback/recipe_parameter.dart';
import 'package:cupward/models/feedback/recipe_suggestion.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/services/recipes/recipe_adjuster.dart';
import 'package:flutter_test/flutter_test.dart';

/// A suggestion to change [parameter] from [current] to [suggested].
RecipeSuggestion _suggestion(RecipeParameter parameter, {double? current, double? suggested}) => RecipeSuggestion(
      parameter: parameter,
      direction: ChangeDirection.increase,
      title: 'Change it',
      change: 'A little more',
      rationale: 'Because.',
      expectedEffect: 'Better.',
      currentValue: current,
      suggestedValue: suggested,
    );

/// Verifies how each kind of suggestion changes a recipe, and which cannot be applied.
void main() {
  const BrewRecipe recipe = BuiltInRecipes.v60PourOver;

  /// The target weight of each phase of [result], in order, leaving out phases without one.
  List<double> targets(BrewRecipe result) => <double>[
        for (final BrewPhase phase in result.phases)
          if (phase.targetWeightGrams != null) phase.targetWeightGrams!,
      ];

  group('RecipeAdjuster', () {
    /// A dose change touches only the coffee, so the brew changes in one variable.
    test('changes the coffee dose alone', () {
      // Act
      final BrewRecipe result = RecipeAdjuster.apply(
        recipe,
        _suggestion(RecipeParameter.coffeeDose, current: 20, suggested: 21),
      )!;

      // Assert
      expect(result.coffeeGrams, 21);
      expect(result.waterGrams, recipe.waterGrams);
      expect(result.phases, recipe.phases);
      expect(result.id, recipe.id);
    });

    /// The pour targets are cumulative and the last one is the total, so they scale with the water.
    test('scales the pour targets and yield with the water', () {
      // Act
      final BrewRecipe result = RecipeAdjuster.apply(
        recipe,
        _suggestion(RecipeParameter.waterAmount, current: 320, suggested: 336),
      )!;

      // Assert
      expect(result.waterGrams, 336);
      expect(targets(result), <double>[63, 168, 252, 336]);
      expect(result.yieldMilliliters, 336);
      expect(result.coffeeGrams, recipe.coffeeGrams);
    });

    /// The bloom's target changes on its own, as long as the first pour still adds water after it.
    test('changes the bloom water within the first pour', () {
      // Act
      final BrewRecipe? result = RecipeAdjuster.apply(
        recipe,
        _suggestion(RecipeParameter.bloomWater, current: 60, suggested: 70),
      );
      final BrewRecipe? tooMuch = RecipeAdjuster.apply(
        recipe,
        _suggestion(RecipeParameter.bloomWater, current: 60, suggested: 160),
      );

      // Assert
      expect(targets(result!), <double>[70, 160, 240, 320]);
      expect(tooMuch, isNull);
    });

    /// Times are stored as whole seconds.
    test('changes the bloom rest and the brew time', () {
      // Act
      final BrewRecipe bloom = RecipeAdjuster.apply(
        recipe,
        _suggestion(RecipeParameter.bloomTime, current: 45, suggested: 54.6),
      )!;
      final BrewRecipe brew = RecipeAdjuster.apply(
        recipe,
        _suggestion(RecipeParameter.brewTime, current: 180, suggested: 165),
      )!;

      // Assert
      expect(bloom.phases[1].duration, const Duration(seconds: 55));
      expect(bloom.phases[1].targetWeightGrams, 60);
      expect(brew.brewTime, const Duration(seconds: 165));
    });

    /// Grind, pour rate, and temperature are not in the recipe, and a change without a value has nothing to save.
    test('cannot apply a change the recipe does not store', () {
      final RecipeSuggestion grind = _suggestion(RecipeParameter.grindSize, current: 3, suggested: 4);
      final RecipeSuggestion withoutValue = _suggestion(RecipeParameter.coffeeDose, current: 20);
      final RecipeSuggestion dose = _suggestion(RecipeParameter.coffeeDose, current: 20, suggested: 21);

      expect(RecipeAdjuster.canApply(recipe, grind), isFalse);
      expect(RecipeAdjuster.canApply(recipe, withoutValue), isFalse);
      expect(RecipeAdjuster.canApply(recipe, dose), isTrue);
    });
  });
}
