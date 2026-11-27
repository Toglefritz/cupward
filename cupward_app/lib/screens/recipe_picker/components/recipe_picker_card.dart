import 'package:material_ui/material_ui.dart';

import '../../../components/recipe_summary_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_recipe.dart';
import '../../../theme/insets.dart';

/// One recipe in the list on the recipe list screen: the app's recipe summary card, which can be tapped to choose the
/// recipe.
///
/// The recipe that is already on the brewing screen shows a check mark in the card's corner. The card is a single
/// button for screen readers, and reports whether it is the current recipe.
class RecipePickerCard extends StatelessWidget {
  /// Creates the card for [recipe], which calls [onPressed] when tapped, and shows a check mark if [isCurrent].
  const RecipePickerCard({required this.recipe, required this.isCurrent, required this.onPressed, super.key});

  /// The recipe shown.
  final BrewRecipe recipe;

  /// Whether this is the recipe that is on the brewing screen now.
  final bool isCurrent;

  /// Called when the card is tapped.
  final VoidCallback onPressed;

  /// The corner radius of the card, which the touch ripple follows.
  static const double _cornerRadius = 16;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isCurrent,
        child: Stack(
          children: <Widget>[
            RecipeSummaryCard(
              recipe: recipe,
              menu: isCurrent
                  ? Padding(
                      padding: const EdgeInsets.all(Insets.xSmall),
                      child: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        semanticLabel: strings.recipePickerCurrent,
                      ),
                    )
                  : null,
            ),
            // The ripple sits over the card, because the card's opaque surface would hide one drawn beneath it.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_cornerRadius),
                  onTap: onPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
