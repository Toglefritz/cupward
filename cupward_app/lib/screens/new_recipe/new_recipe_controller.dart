import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_method.dart';
import '../../models/recipes/brew_recipe.dart';
import '../../models/recipes/new_recipe_request.dart';
import '../../services/recipe_generation/recipe_generation_exception.dart';
import '../../services/recipe_generation/recipe_generation_failure.dart';
import '../../services/recipe_generation/recipe_generation_service.dart';
import 'models/new_recipe_status.dart';
import 'new_recipe_route.dart';
import 'new_recipe_view.dart';

/// State and behavior for [NewRecipeRoute].
///
/// The controller holds the form: the chosen [selectedMethod], and the taste preferences in [preferencesController],
/// which the text field edits directly. The form is complete once a method is chosen and the preferences are not
/// blank, and [request] then describes what the user asked for. A menu in the title card sets [localOnly], which keeps
/// the request on the device's own model.
///
/// "Create recipe" sends the request to the hybrid AI system. While it runs, [status] is [NewRecipeStatus.creating]
/// and the screen shows progress in place of the form. When the recipe is saved, the screen closes with it as its
/// result. If it fails, [status] is [NewRecipeStatus.failed] with the reason in [failure], and the form keeps what the
/// user entered. Going back is blocked while the recipe is created, as [canLeave] explains.
class NewRecipeController extends State<NewRecipeRoute> {
  /// The service that creates and saves the recipe, created once for the life of the screen.
  late final RecipeGenerationService _service = widget.generationService ?? RecipeGenerationService();

  /// Where the screen stands.
  NewRecipeStatus status = NewRecipeStatus.editing;

  /// Why the last attempt failed, or null if it did not.
  RecipeGenerationFailure? failure;

  /// The chosen brewing method, or null if none has been chosen.
  BrewMethod? selectedMethod;

  /// Whether the recipe is to be created with the on-device model only, so the request never goes to the cloud. Set
  /// from the menu in the title card, and off at first.
  bool localOnly = false;

  /// Holds the text of the taste preferences field.
  final TextEditingController preferencesController = TextEditingController();

  /// The focus of the taste preferences field.
  final FocusNode preferencesFocus = FocusNode();

  /// Whether the user can leave the screen. They cannot while the recipe is created, because the recipe is saved
  /// before the screen closes with it, so leaving would save a recipe the brewing screen never hears about.
  bool get canLeave => status != NewRecipeStatus.creating;

  /// Whether the form is complete, so a recipe can be created.
  bool get canCreate => selectedMethod != null && preferencesController.text.trim().isNotEmpty;

  /// What the user asked for, or null until the form is complete.
  NewRecipeRequest? get request {
    final BrewMethod? method = selectedMethod;
    if (method == null || !canCreate) {
      return null;
    }
    return NewRecipeRequest(method: method, preferences: preferencesController.text);
  }

  @override
  void initState() {
    super.initState();
    // The create button depends on the text, so the screen rebuilds as the user types.
    preferencesController.addListener(_onPreferencesChanged);
  }

  /// Rebuilds the screen after the preferences text changes.
  void _onPreferencesChanged() => setState(() {});

  /// Handles a tap on a brewing method card by choosing [method].
  void onMethodSelected(BrewMethod method) {
    setState(() => selectedMethod = method);
  }

  /// Handles the local-only switch in the menu by setting [localOnly] to [value].
  void onLocalOnlyChanged(bool value) {
    setState(() => localOnly = value);
  }

  /// Handles a tap on a topic chip by starting a line about [topic] in the preferences, such as "Roast: ", and putting
  /// the cursor after it.
  ///
  /// The topic goes on a new line unless the field is empty or already ends with one. Nothing is added if it would go
  /// past the field's length limit.
  void onTopicPressed(String topic) {
    final String text = preferencesController.text;
    final String separator = text.isEmpty || text.endsWith('\n') ? '' : '\n';
    final String updated = '$text$separator$topic: ';
    if (updated.length > NewRecipeRequest.maxPreferencesLength) {
      return;
    }

    preferencesController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    preferencesFocus.requestFocus();
  }

  /// Handles a tap on "Create recipe", or on Try again after a failure, by creating the recipe the form describes.
  Future<void> onCreatePressed() async {
    final NewRecipeRequest? current = request;
    if (current == null || status == NewRecipeStatus.creating) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      status = NewRecipeStatus.creating;
      failure = null;
    });

    try {
      final BrewRecipe recipe = await _service.createRecipe(current, localOnly: localOnly);
      if (mounted) {
        Navigator.pop(context, recipe);
      }
    } on RecipeGenerationException catch (error) {
      if (mounted) {
        setState(() {
          status = NewRecipeStatus.failed;
          failure = error.failure;
        });
      }
    }
  }

  /// Handles a tap on Edit after a failure by returning to the form, with what the user entered.
  void onEditPressed() {
    setState(() {
      status = NewRecipeStatus.editing;
      failure = null;
    });
  }

  @override
  void dispose() {
    preferencesController
      ..removeListener(_onPreferencesChanged)
      ..dispose();
    preferencesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NewRecipeView(this);
}
