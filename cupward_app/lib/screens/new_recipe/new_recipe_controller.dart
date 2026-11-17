import 'package:material_ui/material_ui.dart';

import 'new_recipe_route.dart';
import 'new_recipe_view.dart';

/// State and behavior for [NewRecipeRoute].
class NewRecipeController extends State<NewRecipeRoute> {
  @override
  Widget build(BuildContext context) => NewRecipeView(this);
}
