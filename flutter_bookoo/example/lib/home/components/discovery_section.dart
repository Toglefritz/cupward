import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import '../home_controller.dart';
import 'device_tile.dart';
import 'section_header.dart';

/// Scan results and the scan button, shown while no scale is connected.
class DiscoverySection extends StatelessWidget {
  /// Creates the section for [state].
  const DiscoverySection({required this.state, super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ThemisUltraDevice> devices = state.devices.values.toList();
    final bool canConnect = !state.isConnecting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: SectionHeader(
            title: 'Nearby scales',
            trailing: state.isScanning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ),
        if (devices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              state.isScanning
                  ? 'Looking for scales.'
                  : 'Wake the scale, then scan to find it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final ThemisUltraDevice device in devices) ...<Widget>[
          DeviceTile(
            device: device,
            isConnecting: state.connectingAddress == device.address,
            onTap: canConnect ? () => state.onDeviceSelected(device) : null,
          ),
          Divider(color: theme.colorScheme.outlineVariant),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: FilledButton(
            onPressed: state.isScanning || state.isConnecting
                ? null
                : state.onScanPressed,
            child: Text(state.isScanning ? 'Scanning' : 'Scan for scales'),
          ),
        ),
      ],
    );
  }
}
