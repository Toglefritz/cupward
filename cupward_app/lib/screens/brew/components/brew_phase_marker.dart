import 'package:material_ui/material_ui.dart';

import '../../../theme/context_theme_extension.dart';
import '../models/brew_phase_status.dart';

/// The dot that marks one phase in the phase indicator.
///
/// The current phase is a filled dot in the copper accent. A finished phase is a filled dot with a check mark. A phase
/// that has not started is a small ring, so the brew's progress reads from left to right.
class BrewPhaseMarker extends StatelessWidget {
  /// Creates the marker for a phase with the given [status].
  const BrewPhaseMarker({required this.status, super.key});

  /// Where the phase stands in the brew.
  final BrewPhaseStatus status;

  /// The diameter of the current phase's dot.
  static const double currentSize = 18;

  /// The diameter of the other phases' dots and rings.
  static const double otherSize = 18;

  /// The width of an upcoming phase's ring.
  static const double _ringWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.theme.colorScheme;
    final Color accent = context.cupwardColors.accent;

    switch (status) {
      case BrewPhaseStatus.current:
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        );
      case BrewPhaseStatus.completed:
        return Container(
          width: otherSize,
          height: otherSize,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          child: Icon(Icons.check, size: otherSize - 6, color: colors.onPrimary),
        );
      case BrewPhaseStatus.upcoming:
        return Container(
          width: otherSize,
          height: otherSize,
          decoration: BoxDecoration(
            color: context.cupwardColors.cardSurface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.onSurfaceVariant.withValues(alpha: 0.5), width: _ringWidth),
          ),
        );
    }
  }
}
