import 'package:material_ui/material_ui.dart';

import '../../../services/on_device_model/on_device_model_state.dart';
import '../../../theme/context_theme_extension.dart';

/// A small round light showing where the app stands with the on-device AI model.
///
/// It uses the same colors as the scale panel's status light: green once the model is ready, amber while the app is
/// checking or downloading, and a pale hairline color otherwise. The status label beside it says the same thing in
/// words, so the dot is left out of screen reader announcements.
class OnDeviceModelStatusDot extends StatelessWidget {
  /// Creates a dot for [state].
  const OnDeviceModelStatusDot({required this.state, super.key});

  /// The state shown.
  final OnDeviceModelState state;

  /// The diameter of the dot.
  static const double _size = 10;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.theme.colorScheme;

    final Color color;
    switch (state) {
      case OnDeviceModelState.available:
        color = context.cupwardColors.success;
      case OnDeviceModelState.checking:
      case OnDeviceModelState.downloading:
        color = colors.tertiary;
      case OnDeviceModelState.downloadable:
      case OnDeviceModelState.unavailable:
      case OnDeviceModelState.unknown:
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
