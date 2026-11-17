import 'package:material_ui/material_ui.dart';

import '../../models/recipes/brew_method.dart';
import '../../models/recipes/new_recipe_request.dart';
import 'new_recipe_route.dart';
import 'new_recipe_view.dart';

/// State and behavior for [NewRecipeRoute].
///
/// The controller holds the form: the chosen [selectedMethod], and the taste preferences in [preferencesController],
/// which the text field edits directly. The form is complete once a method is chosen and the preferences are not
/// blank, and [request] then describes what the user asked for.
class NewRecipeController extends State<NewRecipeRoute> {
  /// The chosen brewing method, or null if none has been chosen.
  BrewMethod? selectedMethod;

  /// Holds the text of the taste preferences field.
  final TextEditingController preferencesController = TextEditingController();

  /// The focus of the taste preferences field.
  final FocusNode preferencesFocus = FocusNode();

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

  /// Handles a tap on "Create recipe". The form's [request] is complete when this is called.
  void onCreatePressed() {
    FocusScope.of(context).unfocus();
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
