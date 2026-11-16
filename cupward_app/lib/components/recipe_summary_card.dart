import 'package:material_ui/material_ui.dart';

import '../models/recipes/brew_recipe.dart';
import '../theme/context_theme_extension.dart';
import '../theme/insets.dart';
import 'recipe_stats_row.dart';

/// A card that summarizes the recipe being brewed: its name and profile, and its targets.
///
/// On a wide screen the name sits on the left and the targets on the right, separated by a rule, as one row. On a
/// narrow screen there is not enough room for both, so the name sits above the targets instead.
class RecipeSummaryCard extends StatelessWidget {
  /// Creates the card for [recipe].
  const RecipeSummaryCard({required this.recipe, super.key});

  /// The recipe shown.
  final BrewRecipe recipe;

  /// The narrowest card width at which the name and the targets fit side by side.
  static const double _sideBySideMinWidth = 600;

  /// The corner radius of the card.
  static const double _cornerRadius = 16;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final Color ruleColor = context.cupwardColors.cardBorder;

    final Widget title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          recipe.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          // The serif title role at a card's scale, so the name keeps the app's headline face.
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26, height: 1.1),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xxSmall),
          child: Text(
            recipe.profile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cupwardColors.cardSurface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: ruleColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.medium, vertical: Insets.small),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= _sideBySideMinWidth) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Align(alignment: Alignment.centerLeft, child: title),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
                      child: VerticalDivider(width: 1, color: ruleColor),
                    ),
                    Expanded(flex: 5, child: RecipeStatsRow(recipe: recipe)),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                title,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.small),
                  child: Divider(color: ruleColor),
                ),
                RecipeStatsRow(recipe: recipe),
              ],
            );
          },
        ),
      ),
    );
  }
}
