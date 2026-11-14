import 'package:material_ui/material_ui.dart';

import '../home_controller.dart';
import 'capture_controls.dart';
import 'live_weight.dart';
import 'reading_stats.dart';

/// Live weight, readings, tare, and frame capture for a connected scale.
class ConnectedSection extends StatelessWidget {
  /// Creates the section for [state].
  const ConnectedSection({required this.state, super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: LiveWeight(grams: state.reading?.weightGrams),
        ),
        const Padding(padding: EdgeInsets.only(top: 28), child: Divider()),
        ReadingStats(reading: state.reading),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: FilledButton(
            // The controller ignores taps while a tare is pending, so the button stays enabled and does not flash
            // its disabled style on every press.
            onPressed: state.onTarePressed,
            child: const Text('Tare'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CaptureControls(
            isCapturing: state.isCapturing,
            frameCount: state.capturedFrames.length,
            onToggle: state.onCaptureToggled,
            onCopy: state.onCopyFramesPressed,
          ),
        ),
      ],
    );
  }
}
