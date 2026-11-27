import 'package:material_ui/material_ui.dart';

import '../../components/content_card.dart';
import '../../components/status_card.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipes/brew_recipe.dart';
import '../../theme/context_theme_extension.dart';
import '../../theme/insets.dart';
import 'components/recipe_picker_card.dart';
import 'models/recipe_picker_status.dart';
import 'recipe_picker_controller.dart';

/// Layout for the recipe list screen. Contains no logic.
///
/// It uses the app's scrolling content column of limited width. A card with the title, a short explanation, and a close
/// button comes first, so the screen can be left without a choice in a browser, which has no back button of its own.
/// The user's recipes follow as cards, the newest first. While they load, and if they cannot be loaded, a single status
/// card takes their place.
class RecipePickerView extends StatelessWidget {
  /// Creates the view for [state].
  const RecipePickerView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final RecipePickerController state;

  /// The widest the content column grows on large windows, matching the other screens.
  static const double _maxContentWidth = 760;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Insets.small, Insets.xSmall, Insets.small, Insets.small),
              children: <Widget>[
                ContentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                strings.recipePickerTitle,
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: strings.recipePickerCloseTooltip,
                            icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                            onPressed: state.onClosePressed,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xxSmall),
                        child: Text(
                          strings.recipePickerIntro,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._buildContent(strings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns what follows the title card for the current status.
  List<Widget> _buildContent(AppLocalizations strings) {
    switch (state.status) {
      case RecipePickerStatus.loading:
        return <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: StatusCard(
              title: strings.recipePickerLoadingTitle,
              message: strings.recipePickerLoadingMessage,
              isBusy: true,
            ),
          ),
        ];
      case RecipePickerStatus.failed:
        return <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: StatusCard(
              title: strings.recipePickerErrorTitle,
              message: strings.recipePickerErrorMessage,
              action: OutlinedButton(onPressed: state.onTryAgainPressed, child: Text(strings.buttonTryAgain)),
            ),
          ),
        ];
      case RecipePickerStatus.loaded:
        return <Widget>[
          for (final BrewRecipe recipe in state.recipes)
            Padding(
              padding: const EdgeInsets.only(top: Insets.small),
              child: RecipePickerCard(
                recipe: recipe,
                isCurrent: state.isCurrent(recipe),
                onPressed: () => state.onRecipePressed(recipe),
              ),
            ),
        ];
    }
  }
}
