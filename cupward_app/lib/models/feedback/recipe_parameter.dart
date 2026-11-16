/// A brewing variable that brew feedback can suggest changing.
///
/// Some parameters are part of a `BrewRecipe`, such as the coffee dose, so a suggestion can give a new value for them.
/// Others, such as the grind size, are not recorded by the app, so a suggestion can only describe the change in words.
/// [hasRecipeValue] says which is which.
///
/// The [name] of each value is what the AI model is asked to answer with, so values must not be renamed.
enum RecipeParameter {
  /// How fine or coarse the coffee is ground.
  grindSize(hasRecipeValue: false),

  /// The weight of coffee, in grams.
  coffeeDose(hasRecipeValue: true),

  /// The total weight of water, in grams.
  waterAmount(hasRecipeValue: true),

  /// The weight of water in the bloom, in grams.
  bloomWater(hasRecipeValue: true),

  /// How long the bloom rests, in seconds.
  bloomTime(hasRecipeValue: true),

  /// How quickly the water is poured.
  pourRate(hasRecipeValue: false),

  /// The temperature of the water.
  waterTemperature(hasRecipeValue: false),

  /// The total brew time, in seconds.
  brewTime(hasRecipeValue: true);

  const RecipeParameter({required this.hasRecipeValue});

  /// Whether the recipe stores a value for this parameter, so a suggestion can give a new value.
  final bool hasRecipeValue;

  /// Returns the parameter whose [name] is [value], or null if none has it.
  static RecipeParameter? tryFromName(String value) {
    for (final RecipeParameter parameter in values) {
      if (parameter.name == value) {
        return parameter;
      }
    }
    return null;
  }
}
