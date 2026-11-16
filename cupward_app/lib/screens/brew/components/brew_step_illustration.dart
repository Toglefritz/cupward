import 'package:material_ui/material_ui.dart';

import '../../../theme/brew_step_image.dart';

/// The illustration for the current step of a brew, centered and kept to the images' proportions.
///
/// When the step changes, the new image fades in over the old one. The images only illustrate the step's title and
/// instructions, so screen readers skip them.
class BrewStepIllustration extends StatelessWidget {
  /// Creates the illustration showing [image].
  const BrewStepIllustration({required this.image, super.key});

  /// The image for the current step.
  final BrewStepImage image;

  /// The tallest the illustration grows. Its height, rather than its width, is limited, so that the recipe, the step,
  /// and the scale readings fit on one phone screen.
  static const double _maxHeight = 220;

  /// How long the fade between two steps' images takes.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: AspectRatio(
          aspectRatio: BrewStepImage.aspectRatio,
          child: AnimatedSwitcher(
            duration: _fadeDuration,
            child: Image.asset(
              image.path,
              // The key makes the switcher treat each step's image as a new child, so it fades between them.
              key: ValueKey<BrewStepImage>(image),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
