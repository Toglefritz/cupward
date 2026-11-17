/// Where the new recipe screen stands.
enum NewRecipeStatus {
  /// The user is filling in the form.
  editing,

  /// The recipe is being created.
  creating,

  /// The recipe could not be created. The user can try again or go back to the form.
  failed,
}
