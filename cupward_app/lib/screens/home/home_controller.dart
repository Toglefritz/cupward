import 'package:material_ui/material_ui.dart';

import '../../models/recipes/built_in_recipes.dart';
import '../brew/brew_route.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen.
class HomeController extends State<HomeRoute> {
  /// Handles a tap on the "Start a Brew" button by opening the brewing screen with the default recipe.
  Future<void> onStartBrewPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const BrewRoute(recipe: BuiltInRecipes.defaultRecipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
