import 'dart:async';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'home_route.dart';
import 'home_view.dart';
import 'models/activity_entry.dart';

/// State and behavior for [HomeRoute].
///
/// Checks the on-device model status when the screen opens and again whenever the user asks. When the model can be
/// downloaded, it starts the download, shows its progress, and checks the status again when the download finishes. Each
/// step is recorded in an activity log that is shown on the screen, newest first.
class HomeController extends State<HomeRoute> {
  /// The plugin entry point.
  final FirebaseHybridAi hybridAi = FirebaseHybridAi();

  /// The most recent successful result, or null before the first check completes.
  OnDeviceModelStatus? status;

  /// A description of the most recent failure, or null if the last check succeeded.
  String? errorMessage;

  /// Whether a check is currently running.
  bool isChecking = false;

  /// Whether a model download is currently running.
  bool isDownloading = false;

  /// How much of the running download has finished, from 0.0 to 1.0. Only meaningful while [isDownloading].
  double downloadFraction = 0;

  /// The smallest change in [downloadFraction] that updates the screen.
  ///
  /// Platforms can report progress many times per second. Redrawing for every report adds work without making the
  /// bar look any different, so reports closer together than this are skipped.
  static const double _progressStep = 0.01;

  /// When the most recent successful check finished, or null before the first one.
  DateTime? checkedAt;

  /// The activity log, newest first.
  final List<ActivityEntry> activity = <ActivityEntry>[];

  /// The name of the platform the app is running on, such as "Android" or "Web".
  String get platformLabel {
    if (kIsWeb) {
      return 'Web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(onCheckPressed());
  }

  /// Reads the on-device model status and updates the screen with the result or the failure.
  Future<void> onCheckPressed() async {
    setState(() {
      isChecking = true;
      errorMessage = null;
    });

    _log('Checking the on-device model.');

    try {
      final OnDeviceModelStatus result = await hybridAi.checkOnDeviceStatus();

      if (!mounted) {
        return;
      }

      final String modelSuffix = result.modelName == null ? '' : ' (${result.modelName})';
      _log('On-device model is ${result.availability.name}$modelSuffix.');

      setState(() {
        status = result;
        checkedAt = DateTime.now();
      });
    } on FirebaseHybridAiException catch (exception) {
      debugPrint('On-device status check failed: $exception');

      if (!mounted) {
        return;
      }

      final String message = exception.message ?? exception.code;
      _log('Check failed: $message', isError: true);

      // The previous result is cleared so a failure is never shown next to a value that may no longer be true.
      setState(() {
        errorMessage = message;
        status = null;
        checkedAt = null;
      });
    } finally {
      if (mounted) {
        setState(() => isChecking = false);
      }
    }
  }

  /// Downloads the on-device model, shows its progress, and checks the status again afterwards.
  ///
  /// On the web, Chrome only starts a download in response to a user action. This is called from a button tap, which
  /// satisfies that requirement.
  Future<void> onDownloadPressed() async {
    setState(() {
      isDownloading = true;
      downloadFraction = 0;
      errorMessage = null;
    });

    _log('Downloading the on-device model.');

    bool succeeded = false;
    double shownFraction = 0;

    try {
      await for (final OnDeviceModelDownloadProgress progress in hybridAi.downloadOnDeviceModel()) {
        if (!mounted) {
          return;
        }

        // The final report is always shown so the bar reaches the end.
        if (progress.fraction - shownFraction >= _progressStep || progress.fraction >= 1) {
          shownFraction = progress.fraction;
          setState(() => downloadFraction = progress.fraction);
        }
      }

      succeeded = true;
      _log('Download finished.');
    } on FirebaseHybridAiException catch (exception) {
      debugPrint('On-device model download failed: $exception');

      if (!mounted) {
        return;
      }

      final String message = exception.message ?? exception.code;
      _log('Download failed: $message', isError: true);

      setState(() => errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }

    // The status is read again so the screen shows the result of the download, such as the model name.
    if (succeeded && mounted) {
      await onCheckPressed();
    }
  }

  /// Adds an entry to the top of the activity log.
  void _log(String message, {bool isError = false}) {
    setState(() {
      activity.insert(0, ActivityEntry(time: DateTime.now(), message: message, isError: isError));
    });
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
