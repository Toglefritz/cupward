import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
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
/// Each model request is limited to [requestTimeout] and each save to [saveTimeout], so the screen never waits
/// forever. A save that times out may still reach Firestore later, in which case the recipe appears without having
/// been offered to the user, so the save limit is generous.
///
/// Hybrid inference runs on Android and in the browser. On other platforms [isSupported] is false, and every request
/// fails with [RecipeGenerationFailure.unsupported].
class RecipeGenerationService {
  /// Creates a service.
  ///
  /// [hybridAi] defaults to a real `FirebaseHybridAi`, [recipes] to `RecipeRepository.instance`, and [isSupported] to
  /// whether the app runs on Android or in a browser. Tests supply their own, and can shorten [requestTimeout] and
  /// [saveTimeout].
  RecipeGenerationService({
    FirebaseHybridAi? hybridAi,
    RecipeRepository? recipes,
    bool? isSupported,
    this.requestTimeout = const Duration(seconds: 90),
    this.saveTimeout = const Duration(seconds: 30),
  })  : _hybridAi = hybridAi ?? FirebaseHybridAi(),
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

  /// The longest one model request may take before it counts as failed. On-device models can be slow to start, so
  /// this allows for that.
  final Duration requestTimeout;

  /// The longest saving the recipe may take before it counts as failed.
  final Duration saveTimeout;

  /// Creates and saves a recipe for [request], and returns it as saved.
  ///
  /// Throws a [RecipeGenerationException] if the recipe cannot be created or saved.
  Future<BrewRecipe> createRecipe(NewRecipeRequest request) async {
    if (!isSupported) {
      throw const RecipeGenerationException(RecipeGenerationFailure.unsupported);
    }

    final String prompt = RecipeGenerationPrompt.build(request);

    StructuredGenerationResult result = await _generate(prompt, InferenceMode.preferOnDevice);
    final _Reading first = _read(result, request);
    BrewRecipe? recipe = first.recipe;
    if (recipe == null && result.source == InferenceSource.onDevice) {
      debugPrint('The on-device recipe could not be used, so the cloud model is asked.');
      // The cloud request says why the first answer was rejected, so that it does not repeat the mistake.
      final String cloudPrompt = RecipeGenerationPrompt.build(request, rejection: first.problem);
      result = await _generate(cloudPrompt, InferenceMode.onlyInCloud);
      recipe = _read(result, request).recipe;
    }
    if (recipe == null) {
      throw const RecipeGenerationException(RecipeGenerationFailure.invalidResponse);
    }

    return await _save(recipe);
  }

  /// Reads the recipe in [result], or says why the answer does not match the schema or is not brewable.
  _Reading _read(StructuredGenerationResult result, NewRecipeRequest request) {
    if (!result.conformsToSchema) {
      debugPrint('The recipe did not match the schema: ${result.violations}');
      return const _Reading.rejected('It did not match the required JSON format.');
    }
    try {
      return _Reading.accepted(RecipeGenerationParser.parse(result.data, method: request.method));
    } on FormatException catch (error) {
      debugPrint('The recipe could not be used: ${error.message}');
      return _Reading.rejected(error.message);
    }
  }

  /// Saves [recipe] under the first free name, adding a number if its own name is taken, and returns it as saved.
  Future<BrewRecipe> _save(BrewRecipe recipe) async {
    for (int attempt = 1; attempt <= maxNameAttempts + 1; attempt++) {
      final String name = attempt == 1 ? recipe.name : '${recipe.name} $attempt';
      final BrewRecipe named = recipe.copyWith(id: RecipeIds.fromName(name), name: name);
      try {
        await _recipes.create(named).timeout(saveTimeout);
        return named;
      } on RecipeNameTakenException {
        continue;
      } on TimeoutException {
        debugPrint('Saving the new recipe took longer than $saveTimeout.');
        throw const RecipeGenerationException(RecipeGenerationFailure.saveFailed);
      } on FirebaseException catch (error) {
        debugPrint('The new recipe could not be saved (${error.plugin}/${error.code}): ${error.message}');
        throw const RecipeGenerationException(RecipeGenerationFailure.saveFailed);
      } on Object catch (error) {
        debugPrint('The new recipe could not be saved: $error');
        throw const RecipeGenerationException(RecipeGenerationFailure.saveFailed);
      }
    }
    debugPrint('Every name tried for "${recipe.name}" is taken.');
    throw const RecipeGenerationException(RecipeGenerationFailure.nameTaken);
  }

  /// Sends [prompt] with the schema in [mode], and turns plugin failures into [RecipeGenerationException]s.
  Future<StructuredGenerationResult> _generate(String prompt, InferenceMode mode) async {
    try {
      return await _hybridAi
          .generateStructured(prompt, schema: RecipeGenerationSchema.schema, mode: mode)
          .timeout(requestTimeout);
    } on TimeoutException {
      debugPrint('The recipe request in $mode took longer than $requestTimeout.');
      throw const RecipeGenerationException(RecipeGenerationFailure.requestFailed);
    } on HybridAiNotSupportedException catch (error) {
      debugPrint('Recipe creation is not supported here: $error');
      throw const RecipeGenerationException(RecipeGenerationFailure.unsupported);
    } on Object catch (error) {
      debugPrint('The recipe request failed: $error');
      throw const RecipeGenerationException(RecipeGenerationFailure.requestFailed);
    }
  }
}

/// The outcome of reading one model answer: a [recipe], or the [problem] that made it unusable.
class _Reading {
  const _Reading.accepted(BrewRecipe this.recipe) : problem = null;

  const _Reading.rejected(String this.problem) : recipe = null;

  /// The recipe, or null if the answer could not be used.
  final BrewRecipe? recipe;

  /// Why the answer could not be used, or null if it could.
  final String? problem;
}
