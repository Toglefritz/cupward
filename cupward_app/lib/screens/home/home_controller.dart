import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../models/recipes/built_in_recipes.dart';
import '../../services/on_device_model/on_device_model_service.dart';
import '../../services/recipes/recipe_repository.dart';
import '../brew/brew_route.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen.
///
/// On first appearance it checks whether the device can run the on-device AI model, unless an earlier visit already
/// did. The model's state belongs to the app-wide [OnDeviceModelService], so a download started here keeps going while
/// the user brews. The controller rebuilds the screen whenever the service notifies.
///
/// It also starts loading the user's recipe from [RecipeRepository]. The first time, the built-in recipe is saved as
/// the user's own copy, so that later changes to it are kept. Starting a brew waits for the load, which falls back to
/// the built-in recipe if the stored one cannot be reached.
class HomeController extends State<HomeRoute> {
  /// The service that checks and downloads the on-device model.
  OnDeviceModelService get modelService => widget.modelService ?? OnDeviceModelService.instance;

  /// The repository that stores the user's recipes.
  RecipeRepository get recipeRepository => widget.recipeRepository ?? RecipeRepository.instance;

  /// The user's recipe, once loaded, or the built-in recipe if it could not be.
  late final Future<BrewRecipe> _recipe = recipeRepository.fetchOrCreate(BuiltInRecipes.defaultRecipe);

  @override
  void initState() {
    super.initState();
    modelService.addListener(_onModelChanged);

    if (!modelService.hasChecked) {
      unawaited(modelService.checkStatus());
    }

    // Start loading now, so the recipe is usually ready by the time the user taps Start a Brew.
    unawaited(_recipe);
  }

  /// Rebuilds the screen with the model's latest state.
  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Handles a tap on Download by starting the model download.
  ///
  /// The download starts within the tap, which Chrome requires before it downloads a model.
  void onDownloadModelPressed() {
    modelService.download();
  }

  /// Handles a tap on Try again by checking for the model again.
  Future<void> onTryModelCheckAgainPressed() async {
    await modelService.checkStatus();
  }

  /// Handles a tap on the "Start a Brew" button by opening the brewing screen with the user's recipe.
  Future<void> onStartBrewPressed() async {
    final BrewRecipe recipe = await _recipe;
    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (BuildContext context) => BrewRoute(recipe: recipe)),
    );
  }

  @override
  void dispose() {
    modelService.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
