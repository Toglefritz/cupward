import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import '../home_controller.dart';
import 'availability_figure.dart';
import 'category_selector.dart';
import 'download_progress_bar.dart';
import 'status_stats.dart';

/// The availability figure, the supporting values, and the button that checks the model or downloads it.
class ModelStatusSection extends StatelessWidget {
  /// Creates the section for [state].
  const new({required this.state, super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  @override
  Widget build(BuildContext context) {
    final bool canDownload = state.status?.availability == OnDeviceModelAvailability.downloadable;
    final bool isBusy = state.isChecking || state.isDownloading;

    final String buttonLabel;
    if (state.isDownloading) {
      buttonLabel = 'Downloading';
    } else if (state.isChecking) {
      buttonLabel = 'Checking';
    } else if (canDownload) {
      buttonLabel = 'Download model';
    } else {
      buttonLabel = 'Check on-device model';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: AvailabilityFigure(availability: state.status?.availability, errorMessage: state.errorMessage),
        ),
        if (state.isDownloading)
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: DownloadProgressBar(fraction: state.downloadFraction),
          ),
        if (state.supportsCategory)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: CategorySelector(selected: state.category, onSelected: isBusy ? null : state.onCategorySelected),
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
            onPressed: isBusy ? null : (canDownload ? state.onDownloadPressed : state.onCheckPressed),
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}
