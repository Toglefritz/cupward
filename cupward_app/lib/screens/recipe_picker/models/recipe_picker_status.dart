/// Where the recipe list screen stands with loading the user's recipes.
enum RecipePickerStatus {
  /// The recipes are being loaded.
  loading,

  /// The recipes have loaded.
  loaded,

  /// The recipes could not be loaded.
  failed,
}
