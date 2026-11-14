import 'package:material_ui/material_ui.dart';

import 'components/on_device_status_card.dart';
import 'home_controller.dart';

/// The layout of the home screen. All behavior lives in [HomeController].
class HomeView extends StatelessWidget {
  /// Creates the view for the given [state].
  const new(this.state, {super.key});

  /// The controller that owns the data shown by this view.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Hybrid AI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OnDeviceStatusCard(status: state.status, errorMessage: state.errorMessage, isChecking: state.isChecking),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: FilledButton(
                  onPressed: state.isChecking ? null : state.onCheckPressed,
                  child: const Text('Check on-device model'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
