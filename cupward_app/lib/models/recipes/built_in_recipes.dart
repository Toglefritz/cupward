import 'brew_phase.dart';
import 'brew_phase_kind.dart';
import 'brew_recipe.dart';

/// The recipes that ship with the app.
///
/// These are available before the user creates or saves any recipe of their own. Their [BrewRecipe.id] values are
/// stable, because stored brews refer to recipes by ID.
abstract final class BuiltInRecipes {
  /// A balanced V60 pour over: 20 g of coffee to 320 g of water (a 1:16 ratio), brewed in three minutes: prepare, bloom,
  /// three pours, and complete. The bloom is 60 g (three times the coffee) with a 45 second rest, and the pours bring
  /// the total to 160 g, 240 g, and 320 g.
  static const BrewRecipe v60PourOver = BrewRecipe(
    id: 'v60-pour-over',
    name: 'V60 Pour Over',
    profile: 'Balanced & Clean',
    coffeeGrams: 20,
    waterGrams: 320,
    brewTime: Duration(minutes: 3),
    yieldMilliliters: 320,
    phases: <BrewPhase>[
      BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
      BrewPhase(
        id: 'bloom',
        kind: BrewPhaseKind.bloom,
        targetWeightGrams: 60,
        duration: Duration(seconds: 45),
      ),
      BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 160),
      BrewPhase(id: 'pour-2', kind: BrewPhaseKind.pour, targetWeightGrams: 240),
      BrewPhase(id: 'pour-3', kind: BrewPhaseKind.pour, targetWeightGrams: 320),
      BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
    ],
  );

  /// Every built-in recipe, in the order they are offered.
  static const List<BrewRecipe> all = <BrewRecipe>[v60PourOver];

  /// The recipe that a new brew starts with when the user has not chosen one.
  static const BrewRecipe defaultRecipe = v60PourOver;
}
