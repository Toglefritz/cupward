import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A compact cream pill for the scale panel's actions, such as "Tare" and "Find scale".
///
/// It uses the theme's cream gradient with ink text and a hairline border, matching the app's other cream buttons at a
/// size that fits inside a card. The label is a single line that shrinks rather than wraps when space is short.
class ScalePanelButton extends StatelessWidget {
  /// Creates a button with [label] that calls [onPressed] when tapped.
  const ScalePanelButton({required this.label, required this.onPressed, super.key});

  /// The text on the button.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// The height of the pill, which is also the minimum touch target size.
  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final ShapeBorder shape = StadiumBorder(side: BorderSide(color: context.cupwardColors.cardBorder));

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(shape: shape, gradient: context.cupwardColors.creamGradient),
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.small),
              child: Center(
                widthFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
