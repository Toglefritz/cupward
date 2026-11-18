import 'package:material_ui/material_ui.dart';

import '../../components/content_card.dart';
import '../../components/status_card.dart';
import '../../l10n/app_localizations.dart';
import '../../services/recipe_generation/recipe_generation_failure.dart';
import '../../theme/context_theme_extension.dart';
import '../../theme/insets.dart';
import 'components/brew_method_labels.dart';
import 'components/brew_method_picker.dart';
import 'components/taste_preferences_field.dart';
import 'models/new_recipe_status.dart';
import 'new_recipe_controller.dart';

/// Layout for the new recipe screen. Contains no logic.
///
/// The app's scrolling content column of limited width holds, in order: a card with the screen's title and a short
/// explanation, the brewing methods as a grid of cards under their own heading, the taste preferences card under its
/// heading, and the "Create recipe" button. The button is disabled, with a note saying why, until a method is chosen
/// and the preferences are filled in. Dragging the list hides the keyboard.
///
/// While the recipe is created, and if that fails, a status card takes the place of the form below the title card:
/// first with progress, then with the reason and buttons to try again or edit the request. The screen cannot be left
/// while the recipe is created, since the recipe is saved before the screen would hand it back.
class NewRecipeView extends StatelessWidget {
  /// Creates the view for [state].
  const NewRecipeView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final NewRecipeController state;

  /// The widest the content column grows on large windows, matching the other screens.
  static const double _maxContentWidth = 760;

  /// Returns the message for [failure].
  static String messageFor(RecipeGenerationFailure failure, AppLocalizations strings) {
    switch (failure) {
      case RecipeGenerationFailure.unsupported:
        return strings.newRecipeFailureUnsupported;
      case RecipeGenerationFailure.requestFailed:
        return strings.newRecipeFailureRequest;
      case RecipeGenerationFailure.invalidResponse:
        return strings.newRecipeFailureInvalid;
      case RecipeGenerationFailure.saveFailed:
        return strings.newRecipeFailureSave;
      case RecipeGenerationFailure.nameTaken:
        return strings.newRecipeFailureNameTaken;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(Insets.xSmall, Insets.medium, Insets.xSmall, Insets.xSmall),
          child: Semantics(
            header: true,
            child: Text(text, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
          ),
        );

    return PopScope(
      canPop: state.canLeave,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.small),
                children: <Widget>[
                  ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            strings.newRecipeTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.xxSmall),
                          child: Text(
                            strings.newRecipeIntro,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.status != NewRecipeStatus.editing)
                    Padding(padding: const EdgeInsets.only(top: Insets.small), child: _statusCard(strings))
                  else ...<Widget>[
                    sectionTitle(strings.newRecipeMethodTitle),
                    BrewMethodPicker(selected: state.selectedMethod, onSelected: state.onMethodSelected),
                    sectionTitle(strings.newRecipeTasteTitle),
                    TastePreferencesField(
                      controller: state.preferencesController,
                      focusNode: state.preferencesFocus,
                      onTopicPressed: state.onTopicPressed,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.medium),
                      child: FilledButton(
                        onPressed: state.canCreate ? state.onCreatePressed : null,
                        child: Text(strings.buttonCreateRecipe),
                      ),
                    ),
                    if (!state.canCreate)
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xSmall),
                        child: Text(
                          strings.newRecipeNeedsInput,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The card shown in place of the form while the recipe is created, or after it failed.
  Widget _statusCard(AppLocalizations strings) {
    final RecipeGenerationFailure? failure = state.failure;
    if (state.status == NewRecipeStatus.creating || failure == null) {
      final String method =
          state.selectedMethod == null ? '' : BrewMethodLabels.nameFor(state.selectedMethod!, strings);
      return StatusCard(
        title: strings.newRecipeCreatingTitle,
        message: strings.newRecipeCreatingMessage(method),
        isBusy: true,
      );
    }

    return StatusCard(
      title: strings.newRecipeErrorTitle,
      message: messageFor(failure, strings),
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: Insets.small,
        runSpacing: Insets.xSmall,
        children: <Widget>[
          if (failure != RecipeGenerationFailure.unsupported)
            OutlinedButton(onPressed: state.onCreatePressed, child: Text(strings.buttonTryAgain)),
          TextButton(onPressed: state.onEditPressed, child: Text(strings.buttonEditRequest)),
        ],
      ),
    );
  }
}
