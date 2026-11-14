import 'package:material_ui/material_ui.dart';

/// Links for recording raw frames and copying them as test fixtures.
class CaptureControls extends StatelessWidget {
  /// Creates the controls.
  const CaptureControls({
    required this.isCapturing,
    required this.frameCount,
    required this.onToggle,
    required this.onCopy,
    super.key,
  });

  /// Whether frames are being recorded.
  final bool isCapturing;

  /// The number of frames recorded so far.
  final int frameCount;

  /// Starts or stops recording.
  final VoidCallback onToggle;

  /// Copies recorded frames to the clipboard.
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            isCapturing ? 'Recording frames: $frameCount' : 'Frame capture',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: onToggle,
          child: Text(isCapturing ? 'Stop' : 'Record'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton(
            onPressed: frameCount == 0 ? null : onCopy,
            child: Text('Copy $frameCount'),
          ),
        ),
      ],
    );
  }
}
