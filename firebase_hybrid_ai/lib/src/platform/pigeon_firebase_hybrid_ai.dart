import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../exceptions/firebase_hybrid_ai_exception.dart';
import '../exceptions/firebase_not_initialized_exception.dart';
import '../exceptions/hybrid_ai_not_supported_exception.dart';
import '../messages.g.dart';
import 'firebase_hybrid_ai_platform.dart';

/// The [FirebaseHybridAiPlatform] implementation for Android and iOS.
///
/// Calls reach the native Firebase AI Logic SDKs through the Pigeon-generated [FirebaseHybridAiHostApi]. This class
/// translates [PlatformException]s into this plugin's exception types, so that callers do not depend on platform
/// error codes.
class PigeonFirebaseHybridAi extends FirebaseHybridAiPlatform {
  /// Creates the implementation. A [api] can be supplied to replace the host API in tests.
  new({@visibleForTesting FirebaseHybridAiHostApi? api}) : _hostApi = api ?? FirebaseHybridAiHostApi();

  /// The generated client that sends messages to the native code.
  final FirebaseHybridAiHostApi _hostApi;

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus() async {
    try {
      return await _hostApi.checkOnDeviceStatus();
    } on PlatformException catch (exception) {
      throw _exceptionFromPlatform(exception);
    }
  }

  /// Maps a platform error code to the most specific exception type for it.
  ///
  /// Codes that have no dedicated type become a plain [FirebaseHybridAiException].
  FirebaseHybridAiException _exceptionFromPlatform(PlatformException exception) {
    final String? details = exception.details?.toString();

    switch (exception.code) {
      case 'firebase-not-initialized':
        return FirebaseNotInitializedException(message: exception.message, details: details);
      case 'unimplemented':
        return HybridAiNotSupportedException(message: exception.message, details: details);
      default:
        return FirebaseHybridAiException(code: exception.code, message: exception.message, details: details);
    }
  }
}
