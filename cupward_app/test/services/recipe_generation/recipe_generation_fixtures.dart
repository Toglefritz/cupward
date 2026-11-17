import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/new_recipe_request.dart';

/// Shared test data for recipe creation: requests and AI answers in the shape of the schema.
abstract final class RecipeGenerationFixtures {
  /// A request for a pour-over recipe.
  static const NewRecipeRequest pourOverRequest = NewRecipeRequest(
    method: BrewMethod.kalitaWave,
    preferences: 'Strong, medium-dark roast, about 350 ml.',
  );

  /// A request for an immersion recipe.
  static const NewRecipeRequest immersionRequest = NewRecipeRequest(
    method: BrewMethod.frenchPress,
    preferences: 'Full-bodied and sweet.',
  );

  /// A brewable pour-over answer: 22 g to 350 g, a bloom, and three pours.
  static Map<String, dynamic> pourOverAnswer() => <String, dynamic>{
        'name': 'Bold Morning Kalita',
        'profile': 'Bold & Syrupy',
        'coffeeGrams': 22,
        'waterGrams': 350,
        'brewTimeSeconds': 210,
        'yieldMilliliters': 306,
        'phases': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'prepare'},
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 55, 'durationSeconds': 40},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 170},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 260},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
          <String, dynamic>{'kind': 'complete'},
        ],
      };

  /// A brewable immersion answer: one pour, then a four-minute steep.
  static Map<String, dynamic> immersionAnswer() => <String, dynamic>{
        'name': 'Sweet Press',
        'profile': 'Rich & Sweet',
        'coffeeGrams': 20,
        'waterGrams': 300,
        'brewTimeSeconds': 270,
        'yieldMilliliters': 260,
        'phases': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'prepare'},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 240},
          <String, dynamic>{'kind': 'complete'},
        ],
      };
}
