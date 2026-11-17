import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/models/recipes/recipe_ids.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies how a recipe's name becomes its ID, which is what makes each name unique.
void main() {
  group('RecipeIds', () {
    /// Built-in recipes are stored under the same ID their name gives, so they follow the same rule.
    test('gives each built-in recipe its own ID', () {
      for (final recipe in BuiltInRecipes.all) {
        expect(RecipeIds.fromName(recipe.name), recipe.id, reason: recipe.name);
      }
    });

    /// Names that differ only in case, spacing, or punctuation count as the same name.
    test('ignores case, spacing, and punctuation', () {
      expect(RecipeIds.fromName('V60 Pour Over'), 'v60-pour-over');
      expect(RecipeIds.fromName('  v60   pour-over! '), 'v60-pour-over');
      expect(RecipeIds.fromName('V60: Pour/Over'), 'v60-pour-over');
    });

    /// Recipe names are not limited to English.
    test('keeps letters from any script', () {
      expect(RecipeIds.fromName('Café Crème'), 'café-crème');
      expect(RecipeIds.fromName('ハンドドリップ 1'), 'ハンドドリップ-1');
    });

    /// IDs stay short enough for the security rules, without a trailing hyphen.
    test('limits the length', () {
      final String id = RecipeIds.fromName('${'a' * 59} long name');
      expect(id.length, lessThanOrEqualTo(RecipeIds.maxLength));
      expect(id.endsWith('-'), isFalse);
    });

    /// A name with nothing to keep still gets an ID.
    test('falls back for a name without letters or digits', () {
      expect(RecipeIds.fromName('!!!'), RecipeIds.fallback);
    });
  });
}
