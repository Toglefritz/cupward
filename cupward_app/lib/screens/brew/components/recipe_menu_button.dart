import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';

/// The menu in the corner of the recipe card on the brewing screen, with actions for the user's recipes.
///
/// The button is a horizontal "more" icon in the secondary ink color, so it sits quietly in the card's corner. The menu
/// opens below the button and to its left, so it stays inside the card's corner, and matches the app's cards: a cream
/// surface with a hairline border, rounded corners, and a soft shadow. It offers creating a new recipe and, below a
/// rule, starting or ending demo mode, in which the scale is simulated. While the brew has not started and the user has
/// other recipes, it also offers changing the recipe, between the two.
class RecipeMenuButton extends StatelessWidget {
  /// Creates the menu, which calls [onNewRecipePressed] when "New recipe" is chosen, [onChangeRecipePressed] when
  /// "Change recipe" is chosen, and [onDemoPressed] when "Start demo" or, while [isDemoRunning], "End demo" is chosen.
  const RecipeMenuButton({
    required this.onNewRecipePressed,
    required this.onChangeRecipePressed,
    required this.isDemoRunning,
    required this.onDemoPressed,
    super.key,
  });

  /// Called when "New recipe" is chosen.
  final VoidCallback onNewRecipePressed;

  /// Called when "Change recipe" is chosen, or null when the recipe cannot be changed now, which leaves the item out.
  final VoidCallback? onChangeRecipePressed;

  /// Whether demo mode is on, so the menu offers to end it rather than start it.
  final bool isDemoRunning;

  /// Called when "Start demo" or "End demo" is chosen.
  final VoidCallback onDemoPressed;

  /// The corner radius of the menu, a little tighter than the cards it opens from.
  static const double _menuCornerRadius = 12;

  /// The width of the menu. It is fixed so that the menu's right edge can line up with the button's, keeping the menu
  /// inside the card's corner rather than running off the screen.
  static const double _menuWidth = 200;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;

    return MenuAnchor(
      // The menu hangs from the button's bottom-right corner and opens to the left.
      alignmentOffset: const Offset(-_menuWidth, 0),
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.symmetric(vertical: 8)),
        backgroundColor: WidgetStatePropertyAll<Color>(context.cupwardColors.cardSurface),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        // A soft shadow like the cards', rather than Material's default, which reads as a grey ring on cream.
        elevation: const WidgetStatePropertyAll<double>(2),
        shadowColor: WidgetStatePropertyAll<Color>(theme.colorScheme.onSurface.withValues(alpha: 0.12)),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_menuCornerRadius),
            side: BorderSide(color: context.cupwardColors.cardBorder),
          ),
        ),
      ),
      menuChildren: <Widget>[
        // The items set the menu's width, since the menu sizes itself to them.
        SizedBox(
          width: _menuWidth,
          child: MenuItemButton(
            leadingIcon: Icon(Icons.add, color: theme.colorScheme.onSurface),
            onPressed: onNewRecipePressed,
            child: Text(strings.recipeMenuNewRecipe, style: theme.textTheme.bodyLarge),
          ),
        ),
        if (onChangeRecipePressed != null)
          SizedBox(
            width: _menuWidth,
            child: MenuItemButton(
              leadingIcon: Icon(Icons.swap_horiz, color: theme.colorScheme.onSurface),
              onPressed: onChangeRecipePressed,
              child: Text(strings.buttonChangeRecipe, style: theme.textTheme.bodyLarge),
            ),
          ),
        Divider(height: 9, color: context.cupwardColors.cardBorder),
        SizedBox(
          width: _menuWidth,
          child: MenuItemButton(
            leadingIcon: Icon(
              isDemoRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: onDemoPressed,
            child: Text(
              isDemoRunning ? strings.recipeMenuEndDemo : strings.recipeMenuStartDemo,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          tooltip: strings.recipeMenuTooltip,
          icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}
