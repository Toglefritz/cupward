import 'package:material_ui/material_ui.dart';
import '../../services/on_device_model/on_device_model_service.dart';
import '../../services/recipes/recipe_repository.dart';
import 'home_controller.dart';

/// Landing screen shown when the app first loads.
///
/// [HomeController] checks whether the device can run the on-device AI model as soon as the screen appears, and the
/// screen offers to download the model when it can be downloaded. The button that starts a brewing session is
/// available throughout, because brew feedback falls back to the cloud until the model is ready.
class HomeRoute extends StatefulWidget {
  /// Creates the home route widget.
  ///
  /// [modelService] defaults to the app's shared `OnDeviceModelService.instance`, and [recipeRepository] to
  /// `RecipeRepository.instance`. Tests supply their own.
  const HomeRoute({this.modelService, this.recipeRepository, super.key});

  /// The service that checks and downloads the on-device model, or null to use the app's shared one.
  final OnDeviceModelService? modelService;

  /// The repository that stores the user's recipes, or null to use the app's shared one.
  final RecipeRepository? recipeRepository;

  @override
  State<HomeRoute> createState() => HomeController();
}
