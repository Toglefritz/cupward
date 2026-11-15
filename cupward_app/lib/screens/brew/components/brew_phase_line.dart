import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';

/// One half of the line that connects the phase markers, on one side of a marker.
///
/// It is drawn in the accent color once the brew has reached it, and as a hairline before that. It draws nothing when
/// it would lead off the end of the indicator.
class BrewPhaseLine extends StatelessWidget {
  /// Creates a line half. [isVisible] is false at the ends of the indicator, and [isReached] says whether the brew has
  /// reached it.
  const BrewPhaseLine({required this.isVisible, required this.isReached, super.key});

  /// Whether the half is drawn at all.
  final bool isVisible;

  /// Whether the brew has reached this part of the line.
  final bool isReached;

  /// The thickness of the line.
  static const double thickness = 1.5;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      height: thickness,
      color: isReached ? context.cupwardColors.accent : context.cupwardColors.cardBorder,
    );
  }
}
