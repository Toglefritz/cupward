import 'package:material_ui/material_ui.dart';

import 'new_recipe_controller.dart';

/// The screen for creating a new recipe, opened from the recipe menu on the brewing screen.
///
/// For now it is a placeholder. Going back returns to the brewing screen.
class NewRecipeRoute extends StatefulWidget {
  /// Creates the screen.
  const NewRecipeRoute({super.key});

  @override
  State<NewRecipeRoute> createState() => NewRecipeController();
}
