import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the result of an on-device model status check, or the error if the check failed.
class OnDeviceStatusCard extends StatelessWidget {
  /// Creates the card. [status] is null until the first check succeeds, and [errorMessage] is null unless the last
  /// check failed.
  const new({required this.status, required this.errorMessage, required this.isChecking, super.key});

  /// The most recent successful result, if any.
  final OnDeviceModelStatus? status;

  /// A description of the last failure, if the last check failed.
  final String? errorMessage;

  /// Whether a check is running. A progress indicator is shown while it is.
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final OnDeviceModelStatus? currentStatus = status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('On-device model', style: textTheme.labelLarge),
            if (isChecking)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator())
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(errorMessage!, style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
              )
            else if (currentStatus != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_title(currentStatus.availability), style: textTheme.headlineSmall),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_description(currentStatus.availability), style: textTheme.bodyMedium),
              ),
              if (currentStatus.modelName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Model: ${currentStatus.modelName}', style: textTheme.bodyMedium),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// The short label for an [availability] value.
  String _title(OnDeviceModelAvailability availability) {
    switch (availability) {
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

  /// A one-sentence explanation of what an [availability] value means for inference.
  String _description(OnDeviceModelAvailability availability) {
    switch (availability) {
      case OnDeviceModelAvailability.available:
        return 'The model is installed. Prompts can run on this device.';
      case OnDeviceModelAvailability.downloadable:
        return 'The model is not installed yet but can be downloaded.';
      case OnDeviceModelAvailability.downloading:
        return 'The model is downloading. Prompts use the cloud until it finishes.';
      case OnDeviceModelAvailability.unavailable:
        return 'This device or browser cannot run an on-device model.';
    }
  }
}
