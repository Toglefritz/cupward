import 'package:material_ui/material_ui.dart';

import '../theme/context_theme_extension.dart';
import '../theme/insets.dart';

/// The app's card: a cream surface with a hairline border, rounded corners, and a soft shadow, around [child].
///
/// It matches the recipe and brew summary cards, so screens built from it look like the rest of the app.
class ContentCard extends StatelessWidget {
  /// Creates a card around [child], with [padding] inside the border.
  const ContentCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: Insets.medium, vertical: Insets.small),
    super.key,
  });

  /// The content of the card.
  final Widget child;

  /// The space between the border and [child].
  final EdgeInsetsGeometry padding;

  /// The corner radius, matching the app's other cards.
  static const double _cornerRadius = 16;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cupwardColors.cardSurface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: context.cupwardColors.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
