import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';

/// One nearby scale in the list of scales: its name, with its signal strength below.
///
/// The signal helps tell two scales apart, since the nearer one is usually stronger.
class ScaleDeviceTile extends StatelessWidget {
  /// Creates a tile for [device] that calls [onTap] when tapped, or is disabled when [onTap] is null.
  const ScaleDeviceTile({required this.device, required this.onTap, super.key});

  /// The scale shown.
  final ThemisUltraDevice device;

  /// Called when the tile is tapped, or null while it cannot be chosen, such as during a connection attempt.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: onTap != null,
      leading: Icon(Icons.scale_outlined, color: theme.colorScheme.onSurface),
      title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
      subtitle: Text(
        strings.scalePickerSignal(device.rssi),
        style: theme.textTheme.labelSmall,
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
