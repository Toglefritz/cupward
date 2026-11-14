import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

/// The on-device model's availability as a large figure, with a sentence explaining what it means.
class AvailabilityFigure extends StatelessWidget {
  /// Creates the display for [availability], or a placeholder when it is null.
  ///
  /// When [errorMessage] is set, it replaces the explanation, in the error color.
  const new({required this.availability, this.errorMessage, super.key});

  /// The availability to show, or null before the first successful check.
  final OnDeviceModelAvailability? availability;

  /// A description of the last failure, or null if the last check succeeded.
  final String? errorMessage;

  /// Placeholder shown before the first successful check.
  static const String _empty = '–';

  /// The word shown as the figure for [value].
  static String title(OnDeviceModelAvailability value) {
    switch (value) {
      case OnDeviceModelAvailability.available:
        return 'Available';
      case OnDeviceModelAvailability.downloadable:
        return 'Downloadable';
      case OnDeviceModelAvailability.downloading:
        return 'Downloading';
      case OnDeviceModelAvailability.unavailable:
        return 'Unavailable';
    }
  }

  /// A sentence describing what [value] means for running prompts.
  static String description(OnDeviceModelAvailability value) {
    switch (value) {
      case OnDeviceModelAvailability.available:
        return 'The model is installed. Prompts can run on this device.';
      case OnDeviceModelAvailability.downloadable:
        return 'The model is not installed yet but can be downloaded.';
      case OnDeviceModelAvailability.downloading:
        return 'The model is downloading. It cannot be used until the download finishes.';
      case OnDeviceModelAvailability.unavailable:
        return 'This device or browser cannot run an on-device model.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OnDeviceModelAvailability? current = availability;

    final String explanation = current == null ? 'Run a check to read the model status.' : description(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('On-device model', style: theme.textTheme.titleMedium),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(current == null ? _empty : title(current), style: theme.textTheme.displayLarge, maxLines: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            errorMessage ?? explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: errorMessage == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
