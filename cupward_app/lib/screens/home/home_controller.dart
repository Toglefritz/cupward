import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/recipes/built_in_recipes.dart';
import '../../services/on_device_model/on_device_model_service.dart';
import '../brew/brew_route.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen.
///
/// On first appearance it checks whether the device can run the on-device AI model, unless an earlier visit already
/// did. The model's state belongs to the app-wide [OnDeviceModelService], so a download started here keeps going while
/// the user brews. The controller rebuilds the screen whenever the service notifies.
class HomeController extends State<HomeRoute> {
  /// The service that checks and downloads the on-device model.
  OnDeviceModelService get modelService => widget.modelService ?? OnDeviceModelService.instance;

  @override
  void initState() {
    super.initState();
    modelService.addListener(_onModelChanged);

    if (!modelService.hasChecked) {
      unawaited(modelService.checkStatus());
    }
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
  void dispose() {
    modelService.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
