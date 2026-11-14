import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../exceptions/firebase_hybrid_ai_exception.dart';
import '../exceptions/firebase_not_initialized_exception.dart';
import '../exceptions/hybrid_ai_not_supported_exception.dart';
import '../exceptions/on_device_model_unavailable_exception.dart';
import '../firebase_hybrid_ai.dart';
import '../messages.g.dart';
import 'pigeon_firebase_hybrid_ai.dart';

/// The interface that platform implementations of the plugin must extend.
///
/// The public [FirebaseHybridAi] class delegates to [instance]. Android and iOS use [PigeonFirebaseHybridAi], and
/// the web implementation replaces it when the plugin registers itself in a browser.
abstract class FirebaseHybridAiPlatform extends PlatformInterface {
  /// Creates a platform implementation.
  new() : super(token: _token);

  static final Object _token = Object();

  static FirebaseHybridAiPlatform _instance = PigeonFirebaseHybridAi();

  /// The implementation that [FirebaseHybridAi] delegates to.
  ///
  /// Defaults to [PigeonFirebaseHybridAi].
  static FirebaseHybridAiPlatform get instance => _instance;

  /// Replaces the implementation. Platform packages call this when they register themselves.
  static set instance(FirebaseHybridAiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the state of the on-device model on the current device or browser.
  ///
  /// [category] selects which model to check where the platform offers a choice, and is ignored elsewhere.
  ///
  /// Throws a [FirebaseNotInitializedException] if the platform needs Firebase and it is not initialized, and a
  /// [HybridAiNotSupportedException] if the platform does not provide the capability.
  Future<OnDeviceModelStatus> checkOnDeviceStatus({OnDeviceModelCategory category = OnDeviceModelCategory.stable}) {
    throw UnimplementedError('checkOnDeviceStatus() has not been implemented.');
  }

  /// Downloads the on-device model and reports progress.
  ///
  /// [category] selects which model to download where the platform offers a choice, and is ignored elsewhere.
  ///
  /// The download starts when the returned stream is listened to. The stream emits the progress as it advances,
  /// then completes when the model is installed. Failures are emitted as errors of type
  /// [FirebaseHybridAiException], including [HybridAiNotSupportedException] on platforms that cannot download.
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) {
    throw UnimplementedError('downloadOnDeviceModel() has not been implemented.');
  }

  /// Generates text for [prompt] and reports where it was generated.
  ///
  /// [mode] chooses between the on-device model and the cloud model. [category] selects the on-device model where
  /// the platform offers a choice, and is ignored elsewhere. [cloudModel] names the Gemini model that handles cloud
  /// inference.
  ///
  /// Throws an [OnDeviceModelUnavailableException] if [mode] requires the on-device model and it cannot serve the
  /// request, a [FirebaseNotInitializedException] if Firebase is not initialized, a
  /// [HybridAiNotSupportedException] if the platform does not provide the capability, and a
  /// [FirebaseHybridAiException] for any other failure.
  Future<TextGenerationResult> generateText(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) {
    throw UnimplementedError('generateText() has not been implemented.');
  }

  /// Generates text for [prompt] and emits it in chunks as the model produces it.
  ///
  /// The arguments are the same as for [generateText]. Generation starts when the returned stream is listened to,
  /// and each [TextGenerationChunk] holds the text that it adds to the response. The stream completes when the
  /// response is complete, and cancelling the subscription stops the generation. Failures are emitted as errors,
  /// with the same exception types that [generateText] throws.
  Stream<TextGenerationChunk> generateTextStream(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) {
    throw UnimplementedError('generateTextStream() has not been implemented.');
  }
}
