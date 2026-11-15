import 'package:material_ui/material_ui.dart';

import '../../../services/scale/scale_connection_status.dart';
import '../../../theme/context_theme_extension.dart';

/// A small round light showing where the app stands with the scale.
///
/// It is green while a scale is connected, amber while the app is searching or connecting, and a pale hairline color
/// otherwise. The status label beside it says the same thing in words, so the dot is left out of screen reader
/// announcements.
class ScaleStatusDot extends StatelessWidget {
  /// Creates a dot for [status].
  const ScaleStatusDot({required this.status, super.key});

  /// The connection status shown.
  final ScaleConnectionStatus status;

  /// The diameter of the dot.
  static const double _size = 10;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.theme.colorScheme;

    final Color color;
    switch (status) {
      case ScaleConnectionStatus.connected:
        color = context.cupwardColors.success;
      case ScaleConnectionStatus.scanning:
      case ScaleConnectionStatus.connecting:
        color = colors.tertiary;
      case ScaleConnectionStatus.disconnected:
      case ScaleConnectionStatus.unsupported:
        color = colors.outlineVariant;
    }

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}
