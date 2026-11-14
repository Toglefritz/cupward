import 'package:material_ui/material_ui.dart';

import 'status_dot.dart';

/// The connection state of the scale, with a disconnect link while connected.
class ConnectionStatusRow extends StatelessWidget {
  /// Creates the row.
  ///
  /// [deviceName] is shown after the status while connected. [onDisconnect]
  /// is null when there is nothing to disconnect.
  const ConnectionStatusRow({
    required this.isConnected,
    required this.isBusy,
    required this.busyLabel,
    this.deviceName,
    this.onDisconnect,
    super.key,
  });

  /// The height of the row, matching the Disconnect link's minimum height.
  static const double _rowHeight = 40;

  /// Whether a scale is connected.
  final bool isConnected;

  /// Whether a scan or connection attempt is in progress.
  final bool isBusy;

  /// The label shown while [isBusy], such as "Scanning".
  final String busyLabel;

  /// The connected scale's advertised name, or null.
  final String? deviceName;

  /// Called when the user taps Disconnect, or null to hide the link.
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color dotColor;
    final String label;
    if (isConnected) {
      dotColor = colors.primary;
      label = 'Connected';
    } else if (isBusy) {
      dotColor = colors.tertiary;
      label = busyLabel;
    } else {
      dotColor = colors.outlineVariant;
      label = 'Not connected';
    }

    // The Disconnect link sets the row height while connected. Holding that height in every state keeps the content
    // below from shifting when the connection state changes.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowHeight),
      child: Row(
        children: <Widget>[
          StatusDot(color: dotColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: <InlineSpan>[
                    if (isConnected && deviceName != null)
                      TextSpan(
                        text: '  $deviceName',
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (onDisconnect != null)
            TextButton(
              onPressed: onDisconnect,
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }
}
