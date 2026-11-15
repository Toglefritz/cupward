import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the JSON form of [BrewRecipe] and the built-in recipes. No dependencies are mocked.
void main() {
  group('BrewRecipe JSON', () {
    /// Recipes are stored as JSON, so a recipe must come back unchanged after a round trip.
    test('round-trips through toJson and fromJson', () {
      // Arrange
      const BrewRecipe recipe = BuiltInRecipes.v60PourOver;

      // Act
      final BrewRecipe decoded = BrewRecipe.fromJson(recipe.toJson());

      // Assert
      expect(decoded, recipe);
    });

    /// The documented JSON shape is the storage contract, including the brew time in whole seconds.
    test('reads the documented JSON shape', () {
      // Act
      final BrewRecipe recipe = BrewRecipe.fromJson(const <String, dynamic>{
        'id': 'v60-pour-over',
        'name': 'V60 Pour Over',
        'profile': 'Balanced & Clean',
        'coffeeGrams': 20,
        'waterGrams': 320.0,
        'brewTimeSeconds': 180,
        'yieldMilliliters': 320,
      });

      // Assert
      expect(recipe.coffeeGrams, 20.0);
      expect(recipe.brewTime, const Duration(minutes: 3));
      expect(recipe.yieldMilliliters, 320.0);
    });

    /// A missing field must be reported as a format problem instead of producing a recipe with a gap.
    test('throws a FormatException for a missing field', () {
      final Map<String, dynamic> json = BuiltInRecipes.v60PourOver.toJson()..remove('name');

      expect(() => BrewRecipe.fromJson(json), throwsFormatException);
    });

    /// A recipe with no coffee or water cannot be brewed, so stored data with such a value must be rejected, also in
    /// release builds where the constructor's asserts do not run.
    test('throws a FormatException for a quantity that is not positive', () {
      final Map<String, dynamic> json = BuiltInRecipes.v60PourOver.toJson()..['waterGrams'] = 0;

      expect(() => BrewRecipe.fromJson(json), throwsFormatException);
    });
  });

  group('BuiltInRecipes', () {
    /// Stored brews refer to recipes by id, so two built-in recipes must never share one.
    test('have unique ids', () {
      final Set<String> ids = BuiltInRecipes.all.map((BrewRecipe recipe) => recipe.id).toSet();

      expect(ids, hasLength(BuiltInRecipes.all.length));
    });

    /// The default recipe must be one that the app offers.
    test('include the default recipe', () {
      expect(BuiltInRecipes.all, contains(BuiltInRecipes.defaultRecipe));
    });
  });
}
