import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../services/recipes/recipe_repository.dart';
import 'models/recipe_picker_status.dart';
import 'recipe_picker_route.dart';
import 'recipe_picker_view.dart';

/// State and behavior for [RecipePickerRoute].
///
/// The recipes are loaded when the screen appears. While they load the status is [RecipePickerStatus.loading]. It ends
/// with the [recipes] and [RecipePickerStatus.loaded], or with [RecipePickerStatus.failed], after which the user can
/// try again. The current recipe is always listed, even if it is not stored yet, such as the built-in recipe on a
/// first launch without a network.
class RecipePickerController extends State<RecipePickerRoute> {
  /// The repository that lists the user's recipes.
  RecipeRepository get _repository => widget.recipeRepository ?? RecipeRepository.instance;

  /// Where loading stands.
  RecipePickerStatus status = RecipePickerStatus.loading;

  /// The user's recipes, newest first, once loaded.
  List<BrewRecipe> recipes = const <BrewRecipe>[];

  /// Whether [recipe] is the one on the brewing screen.
  bool isCurrent(BrewRecipe recipe) => recipe.id == widget.currentRecipe.id;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Loads the recipes and shows them. The status must already be [RecipePickerStatus.loading].
  Future<void> _load() async {
    try {
      final List<BrewRecipe> stored = await _repository.fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        recipes = stored.any(isCurrent) ? stored : <BrewRecipe>[widget.currentRecipe, ...stored];
        status = RecipePickerStatus.loaded;
      });
    } on Object catch (error) {
      debugPrint('Could not load the recipes: $error');
      if (!mounted) {
        return;
      }
      setState(() => status = RecipePickerStatus.failed);
    }
  }

  /// Handles a tap on Try again by loading the recipes again.
  Future<void> onTryAgainPressed() {
    setState(() => status = RecipePickerStatus.loading);
    return _load();
  }

  /// Handles a tap on [recipe] by closing the screen with it as the choice.
  void onRecipePressed(BrewRecipe recipe) {
    Navigator.pop(context, recipe);
  }

  /// Handles a tap on the close button by closing the screen without a choice.
  void onClosePressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => RecipePickerView(this);
}
