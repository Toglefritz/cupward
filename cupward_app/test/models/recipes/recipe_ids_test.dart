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

    /// Shortening must not split a character made of two UTF-16 units, which Firestore would reject in an ID.
    test('does not split a character outside the Basic Multilingual Plane', () {
      // U+20000, a CJK letter, is two UTF-16 units.
      final String id = RecipeIds.fromName('${'a' * 59}\u{20000}');
      expect(id, 'a' * 59);
      expect(id.runes.every((int rune) => rune < 0xD800 || rune > 0xDFFF), isTrue);
    });

    /// Names of only symbols would all share the fallback ID, so they are recognized.
    test('tells whether a name has letters or digits', () {
      expect(RecipeIds.hasLettersOrDigits('☕'), isFalse);
      expect(RecipeIds.hasLettersOrDigits('!! ??'), isFalse);
      expect(RecipeIds.hasLettersOrDigits('☕ 2'), isTrue);
      expect(RecipeIds.hasLettersOrDigits('Café'), isTrue);
    });
  });
}
