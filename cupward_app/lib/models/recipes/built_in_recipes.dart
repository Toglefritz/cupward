import 'brew_recipe.dart';

/// The recipes that ship with the app.
///
/// These are available before the user creates or saves any recipe of their own. Their [BrewRecipe.id] values are
/// stable, because stored brews refer to recipes by ID.
abstract final class BuiltInRecipes {
  /// A balanced V60 pour over: 20 g of coffee to 320 g of water (a 1:16 ratio), brewed in three minutes.
  static const BrewRecipe v60PourOver = BrewRecipe(
    id: 'v60-pour-over',
    name: 'V60 Pour Over',
    profile: 'Balanced & Clean',
    coffeeGrams: 20,
    waterGrams: 320,
    brewTime: Duration(minutes: 3),
    yieldMilliliters: 320,
  );

  /// Every built-in recipe, in the order they are offered.
  static const List<BrewRecipe> all = <BrewRecipe>[v60PourOver];

  /// The recipe that a new brew starts with when the user has not chosen one.
  static const BrewRecipe defaultRecipe = v60PourOver;
}
