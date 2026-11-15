import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import 'brew_controller.dart';

/// The brewing screen, which guides the user through brewing [recipe].
class BrewRoute extends StatefulWidget {
  /// Creates the screen for brewing [recipe].
  const BrewRoute({required this.recipe, super.key});

  /// The recipe being brewed.
  final BrewRecipe recipe;

  @override
  State<BrewRoute> createState() => BrewController();
}
