import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// The home screen's main action: a cream, pill-shaped button with a centered label and a trailing chevron.
///
/// It sits over a photograph, where the theme's solid green button would look heavy, so it uses the theme's cream
/// gradient with ink text instead. A soft shadow separates it from the image. The width is limited, so on wide screens
/// the button stays a compact pill instead of stretching across the page.
class StartBrewButton extends StatelessWidget {
  /// Creates the button with the given [label], which calls [onPressed] when tapped.
  const StartBrewButton({required this.label, required this.onPressed, super.key});

  /// The text in the middle of the button.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// The height of the pill.
  static const double _height = 42;

  /// The widest the button grows.
  static const double _maxWidth = 320;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth, minHeight: _height),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: <BoxShadow>[
              BoxShadow(color: colors.onSurface.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: ShapeDecoration(shape: const StadiumBorder(), gradient: context.cupwardColors.creamGradient),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onPressed,
                child: SizedBox(
                  height: _height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.medium),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // The label is centered on the whole button, and padded on both sides by the chevron's width
                        // so that a long label never runs under it.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Insets.medium),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface),
                          ),
                        ),
                      ],
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
