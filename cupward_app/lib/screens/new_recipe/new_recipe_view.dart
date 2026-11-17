import 'package:material_ui/material_ui.dart';

import '../../components/content_card.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/context_theme_extension.dart';
import '../../theme/insets.dart';
import 'components/brew_method_picker.dart';
import 'components/taste_preferences_field.dart';
import 'new_recipe_controller.dart';

/// Layout for the new recipe screen. Contains no logic.
///
/// The app's scrolling content column of limited width holds, in order: a card with the screen's title and a short
/// explanation, the brewing methods as a grid of cards under their own heading, the taste preferences card under its
/// heading, and the "Create recipe" button. The button is disabled, with a note saying why, until a method is chosen
/// and the preferences are filled in. Dragging the list hides the keyboard.
class NewRecipeView extends StatelessWidget {
  /// Creates the view for [state].
  const NewRecipeView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final NewRecipeController state;

  /// The widest the content column grows on large windows, matching the other screens.
  static const double _maxContentWidth = 760;

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

    return Scaffold(
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
                        child:
                            Text(strings.newRecipeTitle, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30)),
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
            ),
          ),
        ),
      ),
    );
  }
}
