import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';

/// A progress bar for the on-device model download, with the percentage beside it.
///
/// When the platform has not reported progress, such as for a download that started outside the app, the bar moves
/// without a percentage. Screen readers announce the percentage as a phrase, such as "Model download 42 percent".
class OnDeviceModelDownloadBar extends StatelessWidget {
  /// Creates a bar for a download that is [progress] complete, from 0.0 to 1.0, or of unknown progress when null.
  const OnDeviceModelDownloadBar({required this.progress, super.key});

  /// How much has downloaded, from 0.0 to 1.0, or null when unknown.
  final double? progress;

  /// The thickness of the bar.
  static const double _barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final double? fraction = progress;
    final int? percent = fraction == null ? null : (fraction * 100).round();

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_barHeight / 2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: _barHeight,
              backgroundColor: context.cupwardColors.cardBorder,
              semanticsLabel: percent == null ? null : strings.modelDownloadProgressSemantics(percent),
            ),
          ),
        ),
        if (percent != null)
          Padding(
            padding: const EdgeInsets.only(left: Insets.xSmall),
            child: ExcludeSemantics(
              child: Text(strings.modelDownloadProgress(percent), style: theme.textTheme.labelSmall),
            ),
          ),
      ],
    );
  }
}
