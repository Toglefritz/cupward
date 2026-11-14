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
  /// On Android, [category] selects which Gemini Nano model to check: the stable model, or a newer preview model
  /// such as Gemini Nano 4. Preview models can require the AICore Developer Preview on the device, and are reported
  /// as unavailable without it. Check and download the same [category] that your app will use. Other platforms
  /// ignore [category].
  ///
  /// Throws a [FirebaseNotInitializedException] if Firebase has not been initialized, a
  /// [HybridAiNotSupportedException] if the platform does not provide hybrid inference, and a
  /// [FirebaseHybridAiException] for any other failure reported by the platform.
  Future<OnDeviceModelStatus> checkOnDeviceStatus({OnDeviceModelCategory category = OnDeviceModelCategory.stable}) =>
      FirebaseHybridAiPlatform.instance.checkOnDeviceStatus(category: category);

  /// Downloads the on-device model and reports progress as a fraction from 0.0 to 1.0.
  ///
  /// On Android, [category] selects which Gemini Nano model to download. See [checkOnDeviceStatus]. Other platforms
  /// ignore it.
  ///
  /// The download starts when the returned stream is listened to, and the stream completes when the model is
  /// installed. Use [checkOnDeviceStatus] afterwards to confirm the result. Failures are emitted as errors of type
  /// [FirebaseHybridAiException].
  ///
  /// On the web, Chrome only starts a download in response to a user action, so listen to the stream from a handler
  /// such as a button tap. On Apple platforms the system installs the model when Apple Intelligence is enabled, so
  /// the stream fails with [HybridAiNotSupportedException]. Listen to the stream only once at a time, because
  /// platforms do not support concurrent downloads of the same model.
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) => FirebaseHybridAiPlatform.instance.downloadOnDeviceModel(category: category);
}
