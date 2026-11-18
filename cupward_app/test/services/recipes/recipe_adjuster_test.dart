import 'package:cupward/models/feedback/change_direction.dart';
import 'package:cupward/models/feedback/recipe_parameter.dart';
import 'package:cupward/models/feedback/recipe_suggestion.dart';
import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
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

/// A French press recipe with a four-minute steep in a five-minute brew.
final BrewRecipe _press = BuiltInRecipes.v60PourOver.copyWith(
  method: BrewMethod.frenchPress,
  brewTime: const Duration(minutes: 5),
  phases: const <BrewPhase>[
    BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
    BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 320),
    BrewPhase(id: 'steep', kind: BrewPhaseKind.steep, duration: Duration(minutes: 4)),
    BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
  ],
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

    /// A steep time change moves the steep, which the brewing screen times, and the brew time with it.
    test('changes the steep time and the brew time with it', () {
      final BrewRecipe result = RecipeAdjuster.apply(
        _press,
        _suggestion(RecipeParameter.steepTime, current: 240, suggested: 270),
      )!;
      expect(result.phases[2].duration, const Duration(seconds: 270));
      expect(result.brewTime, const Duration(seconds: 330));
    });

    /// For an immersion brew, a brew time change is a change to the steep, or it would not change the brew at all.
    test('moves the steep with the brew time of an immersion recipe', () {
      final BrewRecipe result = RecipeAdjuster.apply(
        _press,
        _suggestion(RecipeParameter.brewTime, current: 300, suggested: 280),
      )!;
      expect(result.brewTime, const Duration(seconds: 280));
      expect(result.phases[2].duration, const Duration(seconds: 220));
    });

    /// A pour over has no steep to change.
    test('cannot apply a steep time to a pour over', () {
      expect(
        RecipeAdjuster.canApply(recipe, _suggestion(RecipeParameter.steepTime, current: 240, suggested: 270)),
        isFalse,
      );
    });
  });
}
