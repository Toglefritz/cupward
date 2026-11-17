import 'package:material_ui/material_ui.dart';

import '../../services/recipe_generation/recipe_generation_service.dart';
import 'new_recipe_controller.dart';

/// The screen for creating a new recipe, opened from the recipe menu on the brewing screen.
///
/// The user picks a brewing method and describes how they like their coffee, and the hybrid AI system creates a
/// recipe from them. Once it is saved, the screen closes with the new recipe as its result, so the brewing screen can
/// switch to it. Going back without creating a recipe closes the screen with no result.
class NewRecipeRoute extends StatefulWidget {
  /// Creates the screen.
  ///
  /// [generationService] defaults to a new `RecipeGenerationService`. Tests supply their own.
  const NewRecipeRoute({this.generationService, super.key});

  /// The service that creates and saves the recipe, or null to use a new one.
  final RecipeGenerationService? generationService;

  @override
  State<NewRecipeRoute> createState() => NewRecipeController();
}
