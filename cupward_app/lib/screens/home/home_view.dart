import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'components/home_title.dart';
import 'components/on_device_model_panel.dart';
import 'components/start_brew_button.dart';
import 'home_controller.dart';

/// View for the home screen.
///
/// A full-bleed photograph fills the screen. The app's name sits centered near the top. Near the bottom, the on-device
/// AI panel sits above the button that starts a brew. All of them are inside the safe area and a content column of
/// limited width.
class HomeView extends StatelessWidget {
  /// Creates the home view with the required controller.
  const HomeView(this.state, {super.key});

  /// Controller instance that manages state and business logic for this view.
  final HomeController state;

  /// The widest the content column grows on large windows.
  static const double _maxContentWidth = 560;

  /// Horizontal page margin, matching the other screens' layout.
  static const double _margin = 28;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/golden_morning.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_margin, Insets.large, _margin, Insets.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const HomeTitle(),
                      const Spacer(),
                      OnDeviceModelPanel(
                        state: state.modelService.state,
                        downloadProgress: state.modelService.downloadProgress,
                        didDownloadFail: state.modelService.didDownloadFail,
                        onDownloadPressed: state.onDownloadModelPressed,
                        onTryAgainPressed: state.onTryModelCheckAgainPressed,
                      ),
                      const SizedBox(height: Insets.medium),
                      StartBrewButton(
                        label: AppLocalizations.of(context)!.buttonStartBrew,
                        onPressed: state.onStartBrewPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
