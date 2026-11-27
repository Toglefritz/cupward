import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../services/recipes/recipe_repository.dart';
import 'recipe_picker_controller.dart';

/// The screen that lists all of the user's recipes so they can choose the one to brew, opened from the brewing screen.
///
/// It marks [currentRecipe], the one on the brewing screen. Tapping a recipe closes the screen with that recipe as its
/// result, so the brewing screen can switch to it. Closing the screen any other way gives no result, and the brewing
/// screen stays as it was.
class RecipePickerRoute extends StatefulWidget {
  /// Creates the screen, with [currentRecipe] marked as the current one.
  ///
  /// [recipeRepository] defaults to `RecipeRepository.instance`. Tests supply their own.
  const RecipePickerRoute({required this.currentRecipe, this.recipeRepository, super.key});

  /// The recipe that is on the brewing screen now.
  final BrewRecipe currentRecipe;

  /// The repository that lists the user's recipes, or null to use the app's shared one.
  final RecipeRepository? recipeRepository;

  @override
  State<RecipePickerRoute> createState() => RecipePickerController();
}
