import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_method.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'brew_method_labels.dart';

/// A tappable card for one brewing method: its name in the serif face, the cup it tends to give, and its typical brew
/// time in the copper accent.
///
/// It is the app's cream card. When [isSelected], the border turns the theme's green and thicker, and a green check
/// appears in the corner. Screen readers announce it as one of a group of buttons, with whether it is selected.
class BrewMethodCard extends StatelessWidget {
  /// Creates a card for [method], which calls [onPressed] when tapped.
  const BrewMethodCard({required this.method, required this.isSelected, required this.onPressed, super.key});

  /// The method shown.
  final BrewMethod method;

  /// Whether this is the chosen method.
  final bool isSelected;

  /// Called when the card is tapped.
  final VoidCallback onPressed;

  /// The corner radius, matching the app's cards.
  static const double _cornerRadius = 16;

  /// How long the change between selected and not takes.
  static const Duration _animationDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final Color green = theme.colorScheme.primary;
    final BorderRadius radius = BorderRadius.circular(_cornerRadius);

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: _animationDuration,
        decoration: BoxDecoration(
          color: context.cupwardColors.cardSurface,
          borderRadius: radius,
          border: Border.all(
            color: isSelected ? green : context.cupwardColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: isSelected ? 0.1 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(Insets.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          BrewMethodLabels.nameFor(method, strings),
                          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 21, height: 1.15),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: _animationDuration,
                        opacity: isSelected ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: Insets.xxSmall),
                          child: Icon(Icons.check_circle, size: 20, color: green),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xxSmall),
                    child: Text(
                      BrewMethodLabels.descriptionFor(method, strings),
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xSmall),
                    child: Text(
                      BrewMethodLabels.timeFor(method, strings),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.cupwardColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
