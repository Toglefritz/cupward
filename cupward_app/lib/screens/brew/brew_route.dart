import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_recipe.dart';
import '../../services/scale/scale_service.dart';
import 'brew_controller.dart';

/// The brewing screen, which guides the user through brewing [recipe].
class BrewRoute extends StatefulWidget {
  /// Creates the screen for brewing [recipe].
  ///
  /// [scaleService] defaults to the app's shared `ScaleService.instance`, and [now] to `DateTime.now`. Tests supply
  /// their own.
  const BrewRoute({required this.recipe, this.scaleService, this.now, super.key});

  /// The recipe being brewed.
  final BrewRecipe recipe;

  /// The service used for the scale, or null to use the app's shared one.
  final ScaleService? scaleService;

  /// The source of the current time for rests and the cancel window, or null to use the system clock.
  final DateTime Function()? now;

  @override
  State<BrewRoute> createState() => BrewController();
}
