import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../services/recipe_generation/recipe_generation_service.dart';
import '../../services/recipes/recipe_repository.dart';
import '../../services/scale/scale_service.dart';
import 'brew_controller.dart';

/// The brewing screen, which guides the user through brewing [recipe].
///
/// The user can create a new recipe from the recipe menu, and the screen then switches to it.
class BrewRoute extends StatefulWidget {
  /// Creates the screen for brewing [recipe].
  ///
  /// [scaleService] defaults to the app's shared `ScaleService.instance`, [recipeRepository] to
  /// `RecipeRepository.instance`, [recipeGenerationService] to a new `RecipeGenerationService`, and [now] to
  /// `DateTime.now`. Tests supply their own.
  const BrewRoute({
    required this.recipe,
    this.scaleService,
    this.recipeRepository,
    this.recipeGenerationService,
    this.now,
    super.key,
  });

  /// The recipe being brewed.
  final BrewRecipe recipe;

  /// The service used for the scale, or null to use the app's shared one.
  final ScaleService? scaleService;

  /// The repository that records which recipe is chosen, or null to use the app's shared one.
  final RecipeRepository? recipeRepository;

  /// The service the new recipe screen uses to create recipes, or null to use a new one.
  final RecipeGenerationService? recipeGenerationService;

  /// The source of the current time for rests and the cancel window, or null to use the system clock.
  final DateTime Function()? now;

  @override
  State<BrewRoute> createState() => BrewController();
}
