import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/scale/scale_connection_status.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'scale_battery_indicator.dart';
import 'scale_status_dot.dart';

/// The left side of the scale panel: a "Scale" heading, a status light with its label, and, once the scale has
/// reported it, the battery level.
class ScaleStatusSummary extends StatelessWidget {
  /// Creates a summary for [status], with the battery at [batteryPercent] when it is known.
  const ScaleStatusSummary({required this.status, this.batteryPercent, super.key});

  /// Where the app stands with the scale.
  final ScaleConnectionStatus status;

  /// The scale's remaining charge from 0 to 100, or null when no scale is connected or it has not reported yet.
  final int? batteryPercent;

  /// Returns the label for [status], such as "Connected".
  static String labelFor(ScaleConnectionStatus status, AppLocalizations strings) {
    switch (status) {
      case ScaleConnectionStatus.unsupported:
        return strings.scaleStatusUnsupported;
      case ScaleConnectionStatus.disconnected:
        return strings.scaleStatusDisconnected;
      case ScaleConnectionStatus.scanning:
        return strings.scaleStatusScanning;
      case ScaleConnectionStatus.connecting:
        return strings.scaleStatusConnecting;
      case ScaleConnectionStatus.connected:
        return strings.scaleStatusConnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final int? battery = batteryPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                strings.scaleTitle,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Padding(
                padding: const EdgeInsets.only(top: Insets.xxSmall),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScaleStatusDot(status: status),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: Insets.xSmall),
                        child: Text(
                          labelFor(status, strings),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (battery != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.xxSmall),
            child: ScaleBatteryIndicator(percent: battery),
          ),
      ],
    );
  }
}
