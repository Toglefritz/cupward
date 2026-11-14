import 'exceptions/firebase_hybrid_ai_exception.dart';
import 'exceptions/firebase_not_initialized_exception.dart';
import 'exceptions/hybrid_ai_not_supported_exception.dart';
import 'messages.g.dart';
import 'platform/firebase_hybrid_ai_platform.dart';

/// The entry point for running prompts with on-device and cloud models through Firebase AI Logic.
///
/// Calls are forwarded to the platform implementation, which wraps the Firebase AI Logic hybrid inference SDK for
/// the current platform. Firebase must be initialized with `firebase_core` before any call that reaches the native
/// SDKs.
class FirebaseHybridAi {
  /// Returns the state of the on-device model on this device or browser.
  ///
  /// Use this to decide whether to surface on-device features, or to prompt the user to wait for or start a model
  /// download. The result describes the model installed on the device, not the cloud, so it is valid offline.
  ///
  /// Throws a [FirebaseNotInitializedException] if Firebase has not been initialized, a
  /// [HybridAiNotSupportedException] if the platform does not provide hybrid inference, and a
  /// [FirebaseHybridAiException] for any other failure reported by the platform.
  Future<OnDeviceModelStatus> checkOnDeviceStatus() => FirebaseHybridAiPlatform.instance.checkOnDeviceStatus();
}
