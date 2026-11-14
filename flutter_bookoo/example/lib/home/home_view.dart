import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import 'components/log_panel.dart';
import 'components/reading_panel.dart';
import 'home_controller.dart';

/// Layout for the example screen. Contains no logic.
class HomeView extends StatelessWidget {
  /// Creates the view for [state].
  const HomeView(this.state, {super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final List<ThemisUltraDevice> devices = state.devices.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('flutter_bookoo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                FilledButton(
                  onPressed:
                      state.isScanning ||
                          state.isConnecting ||
                          state.scale != null
                      ? null
                      : state.onScanPressed,
                  child: Text(state.isScanning ? 'Scanning' : 'Scan'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: OutlinedButton(
                    onPressed: state.scale == null
                        ? null
                        : state.onDisconnectPressed,
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            if (state.scale != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ReadingPanel(reading: state.reading),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: <Widget>[
                    FilledButton(
                      onPressed: state.isTaring ? null : state.onTarePressed,
                      child: const Text('Tare'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: OutlinedButton(
                        onPressed: state.onCaptureToggled,
                        child: Text(
                          state.isCapturing ? 'Stop capture' : 'Start capture',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: OutlinedButton(
                        onPressed: state.capturedFrames.isEmpty
                            ? null
                            : state.onCopyFramesPressed,
                        child: Text(
                          'Copy ${state.capturedFrames.length} frames',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Devices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final ThemisUltraDevice device in devices)
              ListTile(
                title: Text(device.name),
                subtitle: Text('${device.address}  RSSI ${device.rssi}'),
                enabled: !state.isConnecting && state.scale == null,
                onTap: () => state.onDeviceSelected(device),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Log',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(child: LogPanel(lines: state.logLines)),
          ],
        ),
      ),
    );
  }
}
