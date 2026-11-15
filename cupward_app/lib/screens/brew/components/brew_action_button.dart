import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';

/// The main action at the bottom of the brewing screen, which moves the brew to its next step.
///
/// It comes in two weights. The prominent form is the theme's solid green filled button, for steps that only the user
/// can end. The quiet form is an outlined button with no fill, for steps that the scale ends by itself, where the
/// button is only a manual override and should not draw the eye from the pour. The quiet form is also shorter than the
/// filled button, which leaves more room for the step and the scale readings while the user pours. Because the heights
/// differ, the content above shifts slightly when one form replaces the other. The label changes with the phase, for
/// example "Continue" before the brew starts and "Done" at the end, so the caller supplies it.
class BrewActionButton extends StatelessWidget {
  /// Creates a button with [label] that calls [onPressed] when tapped.
  ///
  /// The button is prominent unless [isProminent] is false.
  const BrewActionButton({required this.label, required this.onPressed, this.isProminent = true, super.key});

  /// The text on the button.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// The height of the quiet form, which is also the minimum touch target size.
  static const double quietHeight = 48;

  /// Whether the button is the solid green form (true) or the quiet outlined form (false).
  final bool isProminent;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    if (isProminent) {
      return FilledButton(onPressed: onPressed, child: text);
    }

    final ThemeData theme = context.theme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: context.cupwardColors.cardBorder, width: 1.5),
        minimumSize: const Size.fromHeight(quietHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: theme.textTheme.labelLarge,
      ),
      child: text,
    );
  }
}
