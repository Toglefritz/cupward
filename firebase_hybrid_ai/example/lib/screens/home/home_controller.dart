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
/// downloaded, it starts the download, shows its progress, and checks the status again when the download finishes. The
/// user can also send a prompt to the hybrid AI system and see the response and where it came from. Each step is
/// recorded in an activity log that is shown on the screen, newest first.
class HomeController extends State<HomeRoute> {
  /// The plugin entry point.
  final FirebaseHybridAi hybridAi = FirebaseHybridAi();

  /// The most recent successful result, or null before the first check completes.
  OnDeviceModelStatus? status;

  /// A description of the most recent failure, or null if the last check succeeded.
  String? errorMessage;

  /// Whether a check is currently running.
  bool isChecking = false;

  /// The Gemini Nano release to check and download. The example targets the preview release, which is where Gemini
  /// Nano 4 is offered. Only Android offers a choice, so other platforms ignore it.
  OnDeviceModelCategory category = OnDeviceModelCategory.preview;

  /// Whether the platform lets the user choose a model release, which only Android does.
  bool get supportsCategory => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether a model download is currently running.
  bool isDownloading = false;

  /// How much of the running download has finished, from 0.0 to 1.0. Only meaningful while [isDownloading].
  double downloadFraction = 0;

  /// The smallest change in [downloadFraction] that updates the screen.
  ///
  /// Platforms can report progress many times per second. Redrawing for every report adds work without making the
  /// bar look any different, so reports closer together than this are skipped.
  static const double _progressStep = 0.01;

  /// The prompt text that is sent to the model, which the user edits or fills from a sample prompt.
  final TextEditingController promptController = TextEditingController();

  /// How the next prompt is routed between the on-device model and the cloud.
  InferenceMode mode = InferenceMode.preferOnDevice;

  /// Whether a prompt is currently being generated.
  bool isGenerating = false;

  /// The response to the last prompt, or null before the first one and after a failure.
  TextGenerationResult? generation;

  /// How long the last successful request took, or null.
  Duration? generationTime;

  /// A description of the last failed request, or null if the last request succeeded.
  String? generationError;

  /// Whether the prompt can be sent now: it has text, and nothing else is running.
  bool get canSend => promptController.text.trim().isNotEmpty && !isGenerating && !isChecking && !isDownloading;

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

    // The send button depends on the text, so the screen rebuilds as the user types.
    promptController.addListener(() => setState(() {}));

    unawaited(onCheckPressed());
  }

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  /// Reads the on-device model status and updates the screen with the result or the failure.
  Future<void> onCheckPressed() async {
    setState(() {
      isChecking = true;
      errorMessage = null;
    });

    _log('Checking the on-device model$_categorySuffix.');

    try {
      final OnDeviceModelStatus result = await hybridAi.checkOnDeviceStatus(category: category);

      if (!mounted) {
        return;
      }

      final String modelSuffix = result.modelName == null ? '' : ' (${result.modelName})';
      _log('On-device model$_categorySuffix is ${result.availability.name}$modelSuffix.');

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

    _log('Downloading the on-device model$_categorySuffix.');

    bool succeeded = false;
    double shownFraction = 0;

    try {
      await for (final OnDeviceModelDownloadProgress progress in hybridAi.downloadOnDeviceModel(category: category)) {
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

  /// Puts a sample prompt into the text field so the user can send it or edit it first.
  // The text controller notifies the screen, so this is a method for the view to call and not a property setter.
  // ignore: use_setters_to_change_properties
  void onSamplePromptSelected(String prompt) {
    promptController.text = prompt;
  }

  /// Chooses how the next prompt is routed between the on-device model and the cloud.
  void onModeSelected(InferenceMode selected) {
    setState(() => mode = selected);
  }

  /// Sends the prompt to the hybrid AI system and shows the response, or the failure.
  ///
  /// The model release, the routing mode, and the cloud model come from the screen's current selections. The time is
  /// measured around the plugin call, so it includes any model loading that the first on-device request needs.
  Future<void> onSendPressed() async {
    final String prompt = promptController.text.trim();
    final Stopwatch stopwatch = Stopwatch()..start();

    setState(() {
      isGenerating = true;
      generation = null;
      generationTime = null;
      generationError = null;
    });

    _log('Sending a prompt (${mode.name}$_categorySuffix).');

    try {
      final TextGenerationResult result = await hybridAi.generateText(prompt, mode: mode, category: category);
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      _log('Response from ${result.source.name} in ${stopwatch.elapsedMilliseconds} ms.');

      setState(() {
        generation = result;
        generationTime = stopwatch.elapsed;
      });
    } on FirebaseHybridAiException catch (exception) {
      debugPrint('Text generation failed: $exception');

      if (!mounted) {
        return;
      }

      final String message = exception.message ?? exception.code;
      _log('Generation failed: $message', isError: true);

      setState(() => generationError = message);
    } finally {
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  /// Switches to the given model release and checks its status, because availability differs between releases.
  ///
  /// The previous result is cleared first, so the screen never shows the status of a different release.
  Future<void> onCategorySelected(OnDeviceModelCategory selected) async {
    setState(() {
      category = selected;
      status = null;
      checkedAt = null;
    });

    await onCheckPressed();
  }

  /// A phrase naming the selected release for the activity log, or nothing on platforms with no choice.
  String get _categorySuffix => supportsCategory ? ' (${category.name})' : '';

  /// Adds an entry to the top of the activity log.
  void _log(String message, {bool isError = false}) {
    setState(() {
      activity.insert(0, ActivityEntry(time: DateTime.now(), message: message, isError: isError));
    });
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
