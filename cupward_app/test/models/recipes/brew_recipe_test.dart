import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the JSON form of [BrewRecipe], including its phases, and the built-in recipes. No dependencies are mocked.
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
        'phases': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'prepare', 'kind': 'prepare'},
          <String, dynamic>{'id': 'pour-1', 'kind': 'pour'},
        ],
      });

      // Assert
      expect(recipe.coffeeGrams, 20.0);
      expect(recipe.brewTime, const Duration(minutes: 3));
      expect(recipe.yieldMilliliters, 320.0);
      expect(recipe.phases, const <BrewPhase>[
        BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
        BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour),
      ]);
    });

    /// A brew needs at least one phase to follow, so stored data without any must be rejected.
    test('throws a FormatException when there are no phases', () {
      final Map<String, dynamic> json = BuiltInRecipes.v60PourOver.toJson()..['phases'] = <dynamic>[];

      expect(() => BrewRecipe.fromJson(json), throwsFormatException);
    });

    /// Data from a newer version of the app may use a kind this version does not know, which must not be guessed at.
    test('throws a FormatException for an unknown phase kind', () {
      final Map<String, dynamic> json = BuiltInRecipes.v60PourOver.toJson()
        ..['phases'] = <dynamic>[
          <String, dynamic>{'id': 'press', 'kind': 'press'},
        ];

      expect(() => BrewRecipe.fromJson(json), throwsFormatException);
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

    /// The brewing method is stored by name, which is what the security rules accept.
    test('stores the brewing method by name', () {
      expect(BuiltInRecipes.v60PourOver.toJson()['method'], 'v60');
      final BrewRecipe press = BrewRecipe.fromJson(BuiltInRecipes.v60PourOver.toJson()..['method'] = 'frenchPress');
      expect(press.method, BrewMethod.frenchPress);
    });

    /// Recipes stored before the method was recorded are still read, with the method worked out from their steps.
    test('infers the method of a recipe stored without one', () {
      // Arrange
      final Map<String, dynamic> pourOver = BuiltInRecipes.v60PourOver.toJson()..remove('method');
      final Map<String, dynamic> immersion = BuiltInRecipes.v60PourOver.toJson()
        ..remove('method')
        ..['phases'] = <Map<String, dynamic>>[
          <String, dynamic>{'id': 'pour-1', 'kind': 'pour', 'targetWeightGrams': 320},
          <String, dynamic>{'id': 'steep', 'kind': 'steep', 'durationSeconds': 240},
        ];
      // Act and assert
      expect(BrewRecipe.fromJson(pourOver).method, BrewMethod.v60);
      expect(BrewRecipe.fromJson(immersion).method, BrewMethod.frenchPress);
    });

    /// A method added by a newer version of the app must not make the recipe unreadable.
    test('infers the method when the stored one is unknown', () {
      final Map<String, dynamic> json = BuiltInRecipes.v60PourOver.toJson()..['method'] = 'siphon';
      expect(BrewRecipe.fromJson(json).method, BrewMethod.v60);
    });

    /// The method is part of what makes two recipes the same.
    test('compares the method', () {
      const BrewRecipe recipe = BuiltInRecipes.v60PourOver;
      final BrewRecipe chemex = recipe.copyWith(method: BrewMethod.chemex);
      expect(chemex, isNot(recipe));
      expect(chemex.copyWith(method: BrewMethod.v60), recipe);
    });
  });

  group('BuiltInRecipes', () {
    /// Stored brews refer to recipes by id, so two built-in recipes must never share one.
    test('have unique ids', () {
      final Set<String> ids = BuiltInRecipes.all.map((BrewRecipe recipe) => recipe.id).toSet();

      expect(ids, hasLength(BuiltInRecipes.all.length));
    });

    /// Records of a brew refer to phases by id, so the ids within a recipe must be unique.
    test('have unique phase ids within each recipe', () {
      for (final BrewRecipe recipe in BuiltInRecipes.all) {
        final Set<String> ids = recipe.phases.map((BrewPhase phase) => phase.id).toSet();

        expect(ids, hasLength(recipe.phases.length), reason: recipe.id);
      }
    });

    /// The concept for the brewing screen shows these six phases for the V60 pour over.
    test('give the V60 pour over its six phases', () {
      expect(BuiltInRecipes.v60PourOver.phases.map((BrewPhase phase) => phase.kind), <BrewPhaseKind>[
        BrewPhaseKind.prepare,
        BrewPhaseKind.bloom,
        BrewPhaseKind.pour,
        BrewPhaseKind.pour,
        BrewPhaseKind.pour,
        BrewPhaseKind.complete,
      ]);
    });

    /// The default recipe must be one that the app offers.
    test('include the default recipe', () {
      expect(BuiltInRecipes.all, contains(BuiltInRecipes.defaultRecipe));
    });
  });
}
