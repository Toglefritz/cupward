import 'package:material_ui/material_ui.dart';

/// The main action at the bottom of the brewing screen, which moves the brew to its next step.
///
/// It is the theme's solid green filled button, full width of the content column. The label changes with the phase,
/// for example "Continue" before the brew starts and "Done" at the end, so the caller supplies it.
class BrewActionButton extends StatelessWidget {
  /// Creates a button with [label] that calls [onPressed] when tapped.
  const BrewActionButton({required this.label, required this.onPressed, super.key});

  /// The text on the button.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis));
  }
}
