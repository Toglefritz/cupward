import 'package:material_ui/material_ui.dart';

import '../../../components/panel_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/on_device_model/on_device_model_state.dart';
import '../../../theme/context_theme_extension.dart';
import '../../../theme/insets.dart';
import 'on_device_model_download_bar.dart';
import 'on_device_model_status_dot.dart';

/// A card on the home screen that says whether brew feedback can run on this device, and offers to download the
/// on-device model when it can be downloaded.
///
/// It matches the brewing screen's cards: a cream surface with a hairline border and rounded corners. At the top, an
/// "On-device AI" heading sits over a status light and label, with an action on the right when there is one: Download
/// while the model can be downloaded, or Try again after a failed check. A one-sentence explanation follows, and a
/// progress bar while the model downloads.
///
/// Feedback falls back to the cloud in every state, so nothing here stops the user from brewing.
class OnDeviceModelPanel extends StatelessWidget {
  /// Creates a panel for the model in [state].
  const OnDeviceModelPanel({
    required this.state,
    required this.downloadProgress,
    required this.didDownloadFail,
    required this.onDownloadPressed,
    required this.onTryAgainPressed,
    super.key,
  });

  /// Where the app stands with the model.
  final OnDeviceModelState state;

  /// How much of the model has downloaded, from 0.0 to 1.0, or null when unknown.
  final double? downloadProgress;

  /// Whether the last download failed.
  final bool didDownloadFail;

  /// Called when the Download button is tapped.
  final VoidCallback onDownloadPressed;

  /// Called when the Try again button is tapped.
  final VoidCallback onTryAgainPressed;

  /// The corner radius of the card, matching the brewing screen's cards.
  static const double _cornerRadius = 16;

  /// Returns the status label for [state], such as "Ready".
  static String labelFor(OnDeviceModelState state, AppLocalizations strings) {
    switch (state) {
      case OnDeviceModelState.checking:
        return strings.modelStatusChecking;
      case OnDeviceModelState.available:
        return strings.modelStatusReady;
      case OnDeviceModelState.downloadable:
        return strings.modelStatusDownloadable;
      case OnDeviceModelState.downloading:
        return strings.modelStatusDownloading;
      case OnDeviceModelState.unavailable:
        return strings.modelStatusUnavailable;
      case OnDeviceModelState.unknown:
        return strings.modelStatusUnknown;
    }
  }

  /// Returns the one-sentence explanation for [state].
  static String messageFor(OnDeviceModelState state, AppLocalizations strings) {
    switch (state) {
      case OnDeviceModelState.checking:
        return strings.modelMessageChecking;
      case OnDeviceModelState.available:
        return strings.modelMessageReady;
      case OnDeviceModelState.downloadable:
        return strings.modelMessageDownloadable;
      case OnDeviceModelState.downloading:
        return strings.modelMessageDownloading;
      case OnDeviceModelState.unavailable:
        return strings.modelMessageUnavailable;
      case OnDeviceModelState.unknown:
        return strings.modelMessageUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final bool showFailure = didDownloadFail && state == OnDeviceModelState.downloadable;

    final Widget? action;
    switch (state) {
      case OnDeviceModelState.downloadable:
        action = PanelButton(label: strings.buttonDownloadModel, onPressed: onDownloadPressed);
      case OnDeviceModelState.unknown:
        action = PanelButton(label: strings.buttonTryAgain, onPressed: onTryAgainPressed);
      case OnDeviceModelState.checking:
      case OnDeviceModelState.available:
      case OnDeviceModelState.downloading:
      case OnDeviceModelState.unavailable:
        action = null;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cupwardColors.cardSurface,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: context.cupwardColors.cardBorder),
        boxShadow: <BoxShadow>[
          // A little stronger than on the brewing screen, because this card sits over a photograph.
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.modelTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.xxSmall),
                          child: Row(
                            children: <Widget>[
                              OnDeviceModelStatusDot(state: state),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: Insets.xSmall),
                                  child: Text(
                                    labelFor(state, strings),
                                    // On narrow screens the action leaves little room, so the label wraps rather
                                    // than being cut off.
                                    maxLines: 2,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (action != null) Padding(padding: const EdgeInsets.only(left: Insets.small), child: action),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: Insets.xSmall),
              child: Text(
                showFailure ? strings.modelDownloadFailed : messageFor(state, strings),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: showFailure ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            if (state == OnDeviceModelState.downloading)
              Padding(
                padding: const EdgeInsets.only(top: Insets.small),
                child: OnDeviceModelDownloadBar(progress: downloadProgress),
              ),
          ],
        ),
      ),
    );
  }
}
