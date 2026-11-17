/// Thrown when a new recipe is created with a name that one of the user's recipes already has.
///
/// Names count as the same when they give the same ID, as described in `RecipeIds`.
class RecipeNameTakenException implements Exception {
  /// Creates an exception for a recipe named [name], whose ID is [recipeId].
  const RecipeNameTakenException({required this.name, required this.recipeId});

  /// The name that was asked for.
  final String name;

  /// The ID the name gives, which an existing recipe already has.
  final String recipeId;

  @override
  String toString() => 'RecipeNameTakenException($name, $recipeId)';
}
