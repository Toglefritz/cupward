import 'package:material_ui/material_ui.dart';

import '../../components/content_card.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/context_theme_extension.dart';
import '../../theme/insets.dart';
import 'new_recipe_controller.dart';

/// Layout for the new recipe screen. Contains no logic.
///
/// For now it shows a single card with the screen's title, in the app's scrolling content column of limited width.
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child:
                            Text(strings.newRecipeTitle, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xSmall),
                        child: Text(
                          strings.newRecipePlaceholder,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
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
