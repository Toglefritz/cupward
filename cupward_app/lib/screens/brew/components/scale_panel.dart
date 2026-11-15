import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/recipes/brew_phase_kind.dart';
import '../../../services/scale/scale_connection_status.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'scale_flow_reading.dart';
import 'scale_panel_button.dart';
import 'scale_status_summary.dart';
import 'scale_weight_reading.dart';

/// A card with the scale's live state, shown under the current step's illustration.
///
/// The card has three parts:
///
/// * On the left, the connection status, with the battery level under it once the scale reports one.
/// * In the middle, the live weight.
/// * On the right, the one thing relevant to the current phase. While setting up, that is a Tare button. While water is
///   poured, in the bloom and the pours, it is the flow rate. Once the brew is complete, nothing is shown there.
///
/// Until a scale is connected, the right side holds a "Find scale" button instead, or a progress indicator while
/// connecting. The brewing screen leaves the panel out where scales cannot be used, such as in a web browser. If it is
/// shown there anyway, it says the scale is not available and offers nothing to tap.
///
/// On a wide card the three parts sit in a row, separated by rules. A narrow card cannot fit the weight between the
/// other two, so the status and the action share the top row and the weight sits below them.
class ScalePanel extends StatelessWidget {
  /// Creates a panel for a scale in [status], showing [reading], with the action for a phase of [phaseKind].
  const ScalePanel({
    required this.status,
    required this.reading,
    required this.phaseKind,
    required this.onFindScalePressed,
    required this.onTarePressed,
    super.key,
  });

  /// Where the app stands with the scale.
  final ScaleConnectionStatus status;

  /// The latest measurement from the scale, or null when none has arrived or no scale is connected.
  final BookooScaleReading? reading;

  /// The kind of the current phase of the brew, which decides what the right side shows once a scale is connected.
  final BrewPhaseKind phaseKind;

  /// Called when the "Find scale" button is tapped.
  final VoidCallback onFindScalePressed;

  /// Called when the Tare button is tapped.
  final VoidCallback onTarePressed;

  /// The narrowest card at which the three parts fit side by side.
  static const double _rowMinWidth = 360;

  /// The corner radius of the card.
  static const double _cornerRadius = 16;

  /// The size of the progress indicator shown while connecting.
  static const double _progressSize = 24;

  /// The minimum height of the content, so the card keeps its size as the right side changes.
  static const double _minContentHeight = 64;

  /// The minimum height of the top row of the narrow layout, the height of a button, so the row keeps its size when the
  /// action changes.
  static const double _topRowMinHeight = 48;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final Color ruleColor = context.cupwardColors.cardBorder;
    final bool isConnected = status == ScaleConnectionStatus.connected;
    final BookooScaleReading? latest = isConnected ? reading : null;

    final Widget summary = ScaleStatusSummary(status: status, batteryPercent: latest?.batteryPercent);
    final Widget weight = ScaleWeightReading(grams: latest?.weightGrams);
    final Widget? action = _buildAction(context, latest);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cupwardColors.cardSurface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: ruleColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.small, vertical: Insets.small),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= _rowMinWidth) {
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _minContentHeight),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Align(alignment: Alignment.centerLeft, child: summary),
                      ),
                      _rule(ruleColor),
                      Expanded(flex: 4, child: Center(child: weight)),
                      // With nothing on the right, the weight takes its space rather than leaving an empty column.
                      if (action != null) ...<Widget>[
                        _rule(ruleColor),
                        Expanded(flex: 3, child: Center(child: action)),
                      ],
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _topRowMinHeight),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: summary),
                      if (action != null)
                        Padding(
                          padding: const EdgeInsets.only(left: Insets.xSmall),
                          child: action,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xSmall),
                  child: Divider(color: ruleColor),
                ),
                Center(child: weight),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A vertical rule between two parts of the row layout.
  Widget _rule(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xSmall),
      child: VerticalDivider(width: 1, color: color),
    );
  }

  /// Returns what the right side of the panel shows, or null when it shows nothing.
  Widget? _buildAction(BuildContext context, BookooScaleReading? latest) {
    final AppLocalizations strings = AppLocalizations.of(context)!;

    switch (status) {
      case ScaleConnectionStatus.unsupported:
        return null;
      case ScaleConnectionStatus.disconnected:
      case ScaleConnectionStatus.scanning:
        // While searching, the button reopens the list of scales without restarting the search.
        return ScalePanelButton(label: strings.buttonFindScale, onPressed: onFindScalePressed);
      case ScaleConnectionStatus.connecting:
        return const SizedBox.square(
          dimension: _progressSize,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case ScaleConnectionStatus.connected:
        switch (phaseKind) {
          case BrewPhaseKind.prepare:
            return ScalePanelButton(label: strings.buttonTare, onPressed: onTarePressed);
          case BrewPhaseKind.bloom:
          case BrewPhaseKind.pour:
            return ScaleFlowReading(gramsPerSecond: latest?.flowRateGramsPerSecond);
          case BrewPhaseKind.complete:
            return null;
        }
    }
  }
}
