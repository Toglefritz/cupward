import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import '../home_controller.dart';
import 'availability_figure.dart';
import 'status_stats.dart';

/// The availability figure, the supporting values, and the button that runs the check.
class ModelStatusSection extends StatelessWidget {
  /// Creates the section for [state].
  const new({required this.state, super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: AvailabilityFigure(availability: state.status?.availability, errorMessage: state.errorMessage),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: StatusStats(
            platform: state.platformLabel,
            modelName: state.status?.modelName,
            checkedAt: state.checkedAt,
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: FilledButton(
            onPressed: state.isChecking ? null : state.onCheckPressed,
            child: Text(state.isChecking ? 'Checking' : 'Check on-device model'),
          ),
        ),
      ],
    );
  }
}
