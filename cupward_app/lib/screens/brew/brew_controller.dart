import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import 'brew_route.dart';
import 'brew_view.dart';

/// State and behavior for [BrewRoute].
class BrewController extends State<BrewRoute> {
  /// The recipe being brewed.
  BrewRecipe get recipe => widget.recipe;

  @override
  Widget build(BuildContext context) => BrewView(this);
}
