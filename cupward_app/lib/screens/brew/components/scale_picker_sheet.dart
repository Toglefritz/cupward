import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/scale/scale_connection_status.dart';
import '../../../services/scale/scale_failure.dart';
import '../../../services/scale/scale_service.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'scale_device_tile.dart';

/// A bottom sheet that lists the BOOKOO scales found nearby, so the user can choose theirs.
///
/// The sheet shows the scales from [service] as they are found. While nothing has been found it explains what to do,
/// and once the search ends it offers to search again. If the search or a connection attempt fails, the reason is shown
/// above the list. While connecting, a progress bar runs along the top and the scales cannot be tapped.
///
/// The sheet is its own route, so it does not rebuild with the brewing screen. It listens to [service] directly
/// instead.
class ScalePickerSheet extends StatelessWidget {
  /// Creates a sheet showing the scales found by [service].
  const ScalePickerSheet({
    required this.service,
    required this.onDeviceSelected,
    required this.onSearchAgainPressed,
    super.key,
  });

  /// The service whose scan results are listed.
  final ScaleService service;

  /// Called with the scale the user tapped.
  final ValueChanged<ThemisUltraDevice> onDeviceSelected;

  /// Called when the "Search again" button is tapped.
  final VoidCallback onSearchAgainPressed;

  /// Returns the message for [failure].
  static String messageFor(ScaleFailure failure, AppLocalizations strings) {
    switch (failure) {
      case ScaleFailure.bluetoothUnavailable:
        return strings.scaleFailureBluetooth;
      case ScaleFailure.connectionFailed:
        return strings.scaleFailureConnection;
      case ScaleFailure.unsupportedDevice:
        return strings.scaleFailureUnsupported;
      case ScaleFailure.unknown:
        return strings.scaleFailureUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (BuildContext context, Widget? child) => _buildContent(context),
    );
  }

  /// Builds the sheet for the service's current state.
  Widget _buildContent(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final ScaleConnectionStatus status = service.status;
    final List<ThemisUltraDevice> devices = service.devices.values.toList()
      ..sort((ThemisUltraDevice a, ThemisUltraDevice b) => b.rssi.compareTo(a.rssi));
    final bool isScanning = status == ScaleConnectionStatus.scanning;
    final bool isConnecting = status == ScaleConnectionStatus.connecting;
    final ScaleFailure? failure = service.failure;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Kept in the layout at all times, so the content does not jump when a connection starts.
          SizedBox(height: Insets.xxSmall, child: isConnecting ? const LinearProgressIndicator() : null),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(Insets.medium, Insets.small, Insets.medium, Insets.medium),
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(strings.scalePickerTitle, style: theme.textTheme.titleLarge),
                ),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.small),
                    child: Text(
                      messageFor(failure, strings),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.small),
                    child: Row(
                      children: <Widget>[
                        if (isScanning)
                          const Padding(
                            padding: EdgeInsets.only(right: Insets.small),
                            child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        Expanded(
                          child: Text(
                            isScanning ? strings.scalePickerSearching : strings.scalePickerNoneFound,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.xSmall),
                    child: Column(
                      children: <Widget>[
                        for (final ThemisUltraDevice device in devices)
                          ScaleDeviceTile(
                            device: device,
                            onTap: isConnecting ? null : () => onDeviceSelected(device),
                          ),
                      ],
                    ),
                  ),
                if (status == ScaleConnectionStatus.disconnected)
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.small),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: onSearchAgainPressed, child: Text(strings.buttonSearchAgain)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
