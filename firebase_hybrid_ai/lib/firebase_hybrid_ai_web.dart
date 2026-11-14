import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';

import 'src/exceptions/firebase_hybrid_ai_exception.dart';
import 'src/messages.g.dart';
import 'src/platform/firebase_hybrid_ai_platform.dart';
import 'src/web/chrome_availability.dart';
import 'src/web/chrome_language_model.dart';

/// The [FirebaseHybridAiPlatform] implementation for web browsers.
///
/// On-device inference in the browser uses Chrome's built-in Prompt API, the same API that the Firebase AI Logic
/// web SDK uses. Browsers that do not provide it report the on-device model as unavailable.
class FirebaseHybridAiWeb extends FirebaseHybridAiPlatform {
  /// Creates the implementation. An [availabilityReader] can be supplied to replace the browser call in tests.
  new({@visibleForTesting Future<String?> Function()? availabilityReader})
    : _availabilityReader = availabilityReader ?? readChromeLanguageModelAvailability;

  /// Reads the raw availability string from the browser.
  final Future<String?> Function() _availabilityReader;

  /// Registers this implementation as the active one. Called by the Flutter tooling at startup on web.
  static void registerWith(Registrar registrar) {
    FirebaseHybridAiPlatform.instance = FirebaseHybridAiWeb();
  }

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus() async {
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
}
