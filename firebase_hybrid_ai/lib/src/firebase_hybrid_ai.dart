import 'exceptions/firebase_hybrid_ai_exception.dart';
import 'exceptions/firebase_not_initialized_exception.dart';
import 'exceptions/hybrid_ai_not_supported_exception.dart';
import 'exceptions/on_device_model_unavailable_exception.dart';
import 'messages.g.dart';
import 'platform/firebase_hybrid_ai_platform.dart';

/// The entry point for running prompts with on-device and cloud models through Firebase AI Logic.
///
/// Calls are forwarded to the platform implementation, which wraps the Firebase AI Logic hybrid inference SDK for
/// the current platform. Firebase must be initialized with `firebase_core` before any call that reaches the native
/// SDKs.
class FirebaseHybridAi {
  /// The cloud model used when a request does not name one.
  ///
  /// This is the Gemini model that Firebase AI Logic names as the default for hybrid requests on the web. Android
  /// requires a model name, so the plugin supplies this one there too.
  static const String defaultCloudModel = 'gemini-3.5-flash-lite';

  /// Returns the state of the on-device model on this device or browser.
  ///
  /// Use this to decide whether to surface on-device features, or to prompt the user to wait for or start a model
  /// download. The result describes the model installed on the device, not the cloud, so it is valid offline.
  ///
  /// On Android, [category] selects which Gemini Nano model to check: the stable model, or a newer preview model
  /// such as Gemini Nano 4. Preview models need the AICore Developer Preview on the device. Until the device is
  /// enrolled, the preview categories are reported as unavailable, and after enrollment they are reported as
  /// downloadable. Read [OnDeviceModelStatus.modelName] to see which model you have. Check and download the same
  /// [category] that your app will use. Other platforms ignore [category]. See `docs/android-on-device-models.md`.
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

  /// Sends [prompt] to the hybrid AI system and returns the generated text with the source that produced it.
  ///
  /// [mode] chooses between the on-device model and the cloud model:
  ///
  /// * [InferenceMode.preferOnDevice] uses the on-device model when it is available and falls back to the cloud
  ///   otherwise. This is the default.
  /// * [InferenceMode.onlyOnDevice] never uses the cloud, so the prompt stays on the device.
  /// * [InferenceMode.preferInCloud] uses the cloud and falls back to the device when the device is offline.
  /// * [InferenceMode.onlyInCloud] never uses the device.
  ///
  /// The returned [TextGenerationResult.source] says which model answered, which matters for the fallback modes.
  /// [category] selects the on-device model on Android (see [checkOnDeviceStatus]) and [cloudModel] names the Gemini
  /// model that handles cloud inference.
  ///
  /// Cloud requests are protected by Firebase App Check, so the app needs App Check set up as described in the
  /// Firebase AI Logic documentation. Requests that only use the on-device model do not contact Firebase.
  ///
  /// On-device models answer one prompt at a time, and each call is a single turn with no conversation history.
  ///
  /// Throws an [OnDeviceModelUnavailableException] if [mode] requires the on-device model and it cannot serve the
  /// request, a [FirebaseNotInitializedException] if Firebase has not been initialized, a
  /// [HybridAiNotSupportedException] if the platform does not provide hybrid inference, and a
  /// [FirebaseHybridAiException] for any other failure, such as a rejected request or a network error.
  Future<TextGenerationResult> generateText(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = defaultCloudModel,
  }) => FirebaseHybridAiPlatform.instance.generateText(prompt, mode: mode, category: category, cloudModel: cloudModel);

  /// Sends [prompt] to the hybrid AI system and emits the response in chunks as the model produces it.
  ///
  /// The arguments and the routing behave as for [generateText]. Streaming shows the first words sooner than waiting
  /// for the whole response, which suits long answers. Each [TextGenerationChunk] holds only the text that it adds,
  /// so build the response by appending each chunk's text in order. Every chunk names its own [InferenceSource].
  ///
  /// Generation starts when the stream is listened to, and the stream completes when the response is complete.
  /// Cancelling the subscription stops the generation. Failures arrive as errors on the stream, with the same
  /// exception types that [generateText] throws, and a missing Firebase app is reported before any chunk.
  ///
  /// ```dart
  /// final StringBuffer response = StringBuffer();
  ///
  /// await for (final TextGenerationChunk chunk in hybridAi.generateTextStream('Tell me a story.')) {
  ///   response.write(chunk.text);
  /// }
  /// ```
  Stream<TextGenerationChunk> generateTextStream(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = defaultCloudModel,
  }) => FirebaseHybridAiPlatform.instance.generateTextStream(
    prompt,
    mode: mode,
    category: category,
    cloudModel: cloudModel,
  );
}
