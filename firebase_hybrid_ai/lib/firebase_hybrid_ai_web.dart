import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';

import 'src/exceptions/firebase_hybrid_ai_exception.dart';
import 'src/exceptions/hybrid_ai_not_supported_exception.dart';
import 'src/messages.g.dart';
import 'src/platform/firebase_hybrid_ai_platform.dart';
import 'src/web/chrome_availability.dart';
import 'src/web/chrome_language_model.dart';

/// The [FirebaseHybridAiPlatform] implementation for web browsers.
///
/// On-device inference in the browser uses Chrome's built-in Prompt API, the same API that the Firebase AI Logic web
/// SDK uses. Browsers that do not provide it report the on-device model as unavailable. Chrome chooses and updates
/// the model itself, so the `category` arguments are ignored.
class FirebaseHybridAiWeb extends FirebaseHybridAiPlatform {
  /// Creates the implementation.
  ///
  /// [availabilityReader] and [downloader] can be supplied to replace the browser calls in tests.
  new({
    @visibleForTesting Future<String?> Function()? availabilityReader,
    @visibleForTesting Stream<double> Function()? downloader,
  }) : _availabilityReader = availabilityReader ?? readChromeLanguageModelAvailability,
       _downloader = downloader ?? downloadChromeLanguageModel;

  /// Reads the raw availability string from the browser.
  final Future<String?> Function() _availabilityReader;

  /// Starts the model download in the browser and streams its progress fractions.
  final Stream<double> Function() _downloader;

  /// Registers this implementation as the active one. Called by the Flutter tooling at startup on web.
  static void registerWith(Registrar registrar) {
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
}
