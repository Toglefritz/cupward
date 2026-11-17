import 'recipe_generation_failure.dart';

/// Thrown when a new recipe could not be created. [failure] says why.
class RecipeGenerationException implements Exception {
  /// Creates an exception for [failure].
  const RecipeGenerationException(this.failure);

  /// Why the recipe could not be created.
  final RecipeGenerationFailure failure;

  @override
  String toString() => 'RecipeGenerationException(${failure.name})';
}
