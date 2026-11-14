import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

/// One scan result that can be tapped to connect.
class DeviceTile extends StatelessWidget {
  /// Creates a tile for [device].
  ///
  /// [onTap] is null while the tile is disabled, for example during another
  /// connection attempt. [isConnecting] replaces the chevron with a spinner.
  const DeviceTile({
    required this.device,
    required this.isConnecting,
    this.onTap,
    super.key,
  });

  /// The scan result shown.
  final ThemisUltraDevice device;

  /// Whether a connection to this device is in progress.
  final bool isConnecting;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(device.name, style: theme.textTheme.titleMedium),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Signal ${device.rssi} dBm',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
