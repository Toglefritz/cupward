import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';

/// The menu in the corner of the title card on the new recipe screen, with options for how the recipe is created.
///
/// It is built like the brewing screen's `RecipeMenuButton`: a horizontal "more" icon in the secondary ink color, and a
/// menu that opens below the button and to its left, in the style of the app's cards. For now the menu has one item, a
/// switch for keeping the request on the device's own AI model. Changing the switch leaves the menu open, so the user
/// sees the new setting.
class NewRecipeMenuButton extends StatelessWidget {
  /// Creates the menu, with the local-only switch showing [isLocalOnly] and calling [onLocalOnlyChanged] when it is
  /// flipped.
  ///
  /// The switch is disabled when [onLocalOnlyChanged] is null.
  const NewRecipeMenuButton({required this.isLocalOnly, required this.onLocalOnlyChanged, super.key});

  /// Whether the recipe is to be created with the on-device model only.
  final bool isLocalOnly;

  /// Called with the new value when the switch is flipped, or null to disable the switch.
  final ValueChanged<bool>? onLocalOnlyChanged;

  /// The corner radius of the menu, a little tighter than the cards it opens from.
  static const double _menuCornerRadius = 12;

  /// The width of the menu. It is fixed so that the menu's right edge can line up with the button's, keeping the menu
  /// inside the card's corner rather than running off the screen.
  static const double _menuWidth = 240;

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
        SizedBox(
          width: _menuWidth,
          child: MenuItemButton(
            closeOnActivate: false,
            onPressed: onLocalOnlyChanged == null ? null : () => onLocalOnlyChanged!(!isLocalOnly),
            trailingIcon: ExcludeSemantics(
              child: Switch(
                value: isLocalOnly,
                onChanged: onLocalOnlyChanged,
                // The theme's primary container is the same green as the track, so the default thumb vanishes into
                // the track when it is hovered or pressed. A selected thumb stays white in every state.
                thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return states.contains(WidgetState.disabled)
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                        : theme.colorScheme.onPrimary;
                  }
                  return null;
                }),
              ),
            ),
            child: Text(strings.newRecipeMenuLocalOnly, style: theme.textTheme.bodyLarge),
          ),
        ),
      ],
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          tooltip: strings.newRecipeMenuTooltip,
          icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}
