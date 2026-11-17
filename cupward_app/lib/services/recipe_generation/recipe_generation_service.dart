import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../models/recipes/new_recipe_request.dart';
import '../../models/recipes/recipe_ids.dart';
import '../recipes/recipe_name_taken_exception.dart';
import '../recipes/recipe_repository.dart';
import 'recipe_generation_exception.dart';
import 'recipe_generation_failure.dart';
import 'recipe_generation_parser.dart';
import 'recipe_generation_prompt.dart';
import 'recipe_generation_schema.dart';

/// Creates a new recipe from a brewing method and the user's taste with the hybrid AI system, and saves it.
///
/// The request prefers the on-device model and falls back to the cloud model, as brew feedback does. If an on-device
/// answer does not match the schema, or does not make a brewable recipe, the request is repeated once with the cloud
/// model, which is held to the schema.
///
/// The recipe is then saved with [RecipeRepository.create]. Each of a user's recipes needs a unique name, so if the
/// name is taken, a number is added, such as "Bold Morning 2".
///
/// Hybrid inference runs on Android and in the browser. On other platforms [isSupported] is false, and every request
/// fails with [RecipeGenerationFailure.unsupported].
class RecipeGenerationService {
  /// Creates a service.
  ///
  /// [hybridAi] defaults to a real `FirebaseHybridAi`, [recipes] to `RecipeRepository.instance`, and [isSupported] to
  /// whether the app runs on Android or in a browser. Tests supply their own.
  RecipeGenerationService({FirebaseHybridAi? hybridAi, RecipeRepository? recipes, bool? isSupported})
      : _hybridAi = hybridAi ?? FirebaseHybridAi(),
        _recipes = recipes ?? RecipeRepository.instance,
        isSupported = isSupported ?? (kIsWeb || defaultTargetPlatform == TargetPlatform.android);

  /// How many numbered names are tried after the first when names are taken.
  static const int maxNameAttempts = 9;

  /// The plugin that runs the requests.
  final FirebaseHybridAi _hybridAi;

  /// Saves the new recipe.
  final RecipeRepository _recipes;

  /// Whether the platform can run hybrid inference.
  final bool isSupported;

  /// Creates and saves a recipe for [request], and returns it as saved.
  ///
  /// Throws a [RecipeGenerationException] if the recipe cannot be created or saved.
  Future<BrewRecipe> createRecipe(NewRecipeRequest request) async {
    if (!isSupported) {
      throw const RecipeGenerationException(RecipeGenerationFailure.unsupported);
    }

    final String prompt = RecipeGenerationPrompt.build(request);

    StructuredGenerationResult result = await _generate(prompt, InferenceMode.preferOnDevice);
    BrewRecipe? recipe = _read(result, request);
    if (recipe == null && result.source == InferenceSource.onDevice) {
      debugPrint('The on-device recipe could not be used, so the cloud model is asked.');
      result = await _generate(prompt, InferenceMode.onlyInCloud);
      recipe = _read(result, request);
    }
    if (recipe == null) {
      throw const RecipeGenerationException(RecipeGenerationFailure.invalidResponse);
    }

    return await _save(recipe);
  }

  /// Returns the recipe in [result], or null if the answer does not match the schema or is not brewable.
  BrewRecipe? _read(StructuredGenerationResult result, NewRecipeRequest request) {
    if (!result.conformsToSchema) {
      debugPrint('The recipe did not match the schema: ${result.violations}');
      return null;
    }
    try {
      return RecipeGenerationParser.parse(result.data, method: request.method);
    } on FormatException catch (error) {
      debugPrint('The recipe could not be used: ${error.message}');
      return null;
    }
  }

  /// Saves [recipe] under the first free name, adding a number if its own name is taken, and returns it as saved.
  Future<BrewRecipe> _save(BrewRecipe recipe) async {
    for (int attempt = 1; attempt <= maxNameAttempts + 1; attempt++) {
      final String name = attempt == 1 ? recipe.name : '${recipe.name} $attempt';
      final BrewRecipe named = recipe.copyWith(id: RecipeIds.fromName(name), name: name);
      try {
        await _recipes.create(named);
        return named;
      } on RecipeNameTakenException {
        continue;
      } on Object catch (error) {
        debugPrint('The new recipe could not be saved: $error');
        throw const RecipeGenerationException(RecipeGenerationFailure.saveFailed);
      }
    }
    throw const RecipeGenerationException(RecipeGenerationFailure.saveFailed);
  }

  /// Sends [prompt] with the schema in [mode], and turns plugin failures into [RecipeGenerationException]s.
  Future<StructuredGenerationResult> _generate(String prompt, InferenceMode mode) async {
    try {
      return await _hybridAi.generateStructured(prompt, schema: RecipeGenerationSchema.schema, mode: mode);
    } on HybridAiNotSupportedException catch (error) {
      debugPrint('Recipe creation is not supported here: $error');
      throw const RecipeGenerationException(RecipeGenerationFailure.unsupported);
    } on Object catch (error) {
      debugPrint('The recipe request failed: $error');
      throw const RecipeGenerationException(RecipeGenerationFailure.requestFailed);
    }
  }
}
