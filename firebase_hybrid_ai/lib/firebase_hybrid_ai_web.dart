import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';

import 'src/exceptions/firebase_hybrid_ai_exception.dart';
import 'src/exceptions/hybrid_ai_not_supported_exception.dart';
import 'src/exceptions/on_device_model_unavailable_exception.dart';
import 'src/firebase_hybrid_ai.dart';
import 'src/messages.g.dart';
import 'src/platform/firebase_hybrid_ai_platform.dart';
import 'src/web/chrome_availability.dart';
import 'src/web/chrome_language_model.dart';
import 'src/web/firebase_ai_js.dart';
import 'src/web/web_generation_response.dart';

/// The [FirebaseHybridAiPlatform] implementation for web browsers.
///
/// On-device inference in the browser uses Chrome's built-in Prompt API, the same API that the Firebase AI Logic web
/// SDK uses. Browsers that do not provide it report the on-device model as unavailable. Chrome chooses and updates
/// the model itself, so the `category` arguments are ignored. Text generation goes through the Firebase AI Logic
/// JavaScript SDK, which this plugin asks `firebase_core` to load.
class FirebaseHybridAiWeb extends FirebaseHybridAiPlatform {
  /// Creates the implementation.
  ///
  /// [availabilityReader], [downloader], and [generator] can be supplied to replace the browser calls in tests.
  new({
    @visibleForTesting Future<String?> Function()? availabilityReader,
    @visibleForTesting Stream<double> Function()? downloader,
    @visibleForTesting
    Future<WebGenerationResponse> Function({
      required String prompt,
      required InferenceMode mode,
      required String cloudModel,
      required bool initializeDeviceModel,
    })?
    generator,
  }) : _availabilityReader = availabilityReader ?? readChromeLanguageModelAvailability,
       _downloader = downloader ?? downloadChromeLanguageModel,
       _generator = generator ?? generateWithFirebaseAiJs;

  /// Reads the raw availability string from the browser.
  final Future<String?> Function() _availabilityReader;

  /// Starts the model download in the browser and streams its progress fractions.
  final Stream<double> Function() _downloader;

  /// Sends a prompt through the Firebase AI Logic JavaScript SDK.
  final Future<WebGenerationResponse> Function({
    required String prompt,
    required InferenceMode mode,
    required String cloudModel,
    required bool initializeDeviceModel,
  })
  _generator;

  /// Registers this implementation as the active one. Called by the Flutter tooling at startup on web.
  ///
  /// This also asks `firebase_core` to load the Firebase AI Logic JavaScript SDK together with the other Firebase
  /// scripts when the app initializes Firebase.
  static void registerWith(Registrar registrar) {
    FirebaseCoreWeb.registerService('ai');
    FirebaseHybridAiPlatform.instance = FirebaseHybridAiWeb();
  }

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) async {
    final String? rawAvailability;

    try {
      rawAvailability = await _availabilityReader();
    } on Object catch (error) {
      throw FirebaseHybridAiException(
        code: 'status-check-failed',
        message: 'The browser rejected the on-device model availability check.',
        details: error.toString(),
      );
    }

    // The browser does not report a model name, so only the availability is returned.
    return OnDeviceModelStatus(availability: parseChromeAvailability(rawAvailability));
  }

  @override
  Future<TextGenerationResult> generateText(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) async {
    final bool usesDevice = mode != InferenceMode.onlyInCloud;
    final String? rawAvailability = usesDevice ? await _readAvailabilityForGeneration() : null;
    final bool isInstalled = rawAvailability == 'available';

    // A request that must run on the device cannot succeed without the model, so it fails here with a specific
    // error and does not wait for a browser error.
    if (mode == InferenceMode.onlyOnDevice && !isInstalled) {
      throw OnDeviceModelUnavailableException(
        message: 'The on-device model is not installed in this browser (${rawAvailability ?? 'no Prompt API'}).',
      );
    }

    try {
      final WebGenerationResponse response = await _generator(
        prompt: prompt,
        mode: mode,
        cloudModel: cloudModel,
        // The SDK requires this call before on-device inference. It is skipped when the model is not installed,
        // because it would start a download, and the fallback modes should use the cloud instead of waiting for one.
        initializeDeviceModel: usesDevice && isInstalled,
      );

      return TextGenerationResult(text: response.text, source: _sourceFromSdk(response.source));
    } on FirebaseHybridAiException {
      rethrow;
    } on Object catch (error) {
      throw FirebaseHybridAiException(
        code: 'generation-failed',
        message: 'The Firebase AI Logic SDK could not generate a response.',
        details: error.toString(),
      );
    }
  }

  @override
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) async* {
    // A browser without the Prompt API has no model to download, so this is reported as unsupported and not as a
    // failed download.
    final String? rawAvailability;

    try {
      rawAvailability = await _availabilityReader();
    } on Object catch (error) {
      throw FirebaseHybridAiException(
        code: 'download-failed',
        message: 'The browser rejected the on-device model availability check.',
        details: error.toString(),
      );
    }

    if (rawAvailability == null) {
      throw const HybridAiNotSupportedException(message: 'This browser does not provide the Prompt API.');
    }

    try {
      await for (final double fraction in _downloader()) {
        yield OnDeviceModelDownloadProgress(fraction: fraction);
      }
    } on Object catch (error) {
      throw FirebaseHybridAiException(
        code: 'download-failed',
        message: 'The browser could not download the on-device model. Downloads require a user action such as a tap.',
        details: error.toString(),
      );
    }
  }

  /// Reads the browser's availability string, treating a browser failure as "not installed".
  ///
  /// A failure here must not stop a request that can still be served by the cloud.
  Future<String?> _readAvailabilityForGeneration() async {
    try {
      return await _availabilityReader();
    } on Object {
      return null;
    }
  }

  /// Converts the SDK's `inferenceSource` string, such as `ON_DEVICE`, into an [InferenceSource].
  ///
  /// Anything other than an on-device source is treated as the cloud, because a request that is not known to have
  /// run in the browser was handled by a remote service.
  InferenceSource _sourceFromSdk(String source) {
    return source.toLowerCase() == 'on_device' ? InferenceSource.onDevice : InferenceSource.inCloud;
  }
}
