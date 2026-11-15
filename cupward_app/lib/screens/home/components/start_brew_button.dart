import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';

/// The home screen's main action: the theme's solid green filled button, full width, with a centered label.
///
/// It matches the prominent form of the brewing screen's main action, so starting a brew and moving through it look
/// the same. It is the most eye-catching element on the screen: the only solid color among the cream cards, and taller
/// than the card actions. A soft shadow lifts it off the photograph behind it.
class StartBrewButton extends StatelessWidget {
  /// Creates the button with the given [label], which calls [onPressed] when tapped.
  const StartBrewButton({required this.label, required this.onPressed, super.key});

  /// The text in the middle of the button.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// The corner radius of the theme's filled buttons, so the shadow follows the button's shape.
  static const double _cornerRadius = 10;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cornerRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
