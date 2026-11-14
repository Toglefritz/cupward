import 'package:pigeon/pigeon.dart';

// This file defines the interface between Dart and the Android and iOS host
// code. After editing it, regenerate the output files with:
//
//   dart run pigeon --input pigeon/messages.dart
//
// Pigeon reads a single input file and does not follow `part` or `import`
// directives, so every type it generates must be declared here. The data types
// below are also this plugin's public data types: the library exports them
// from the generated file. The doc comments here become the public API
// documentation.
//
// This file is excluded from analysis. Pigeon cannot parse the `new(...)`
// constructor syntax that `dart fix` produces, so do not run `dart fix` on it.
//
// The web implementation does not use Pigeon for calls. It calls the browser
// APIs directly through `dart:js_interop`, and returns these same types.

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'firebase_hybrid_ai',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/splendidendeavors/firebase_hybrid_ai/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.splendidendeavors.firebase_hybrid_ai'),
    swiftOut: 'ios/firebase_hybrid_ai/Sources/firebase_hybrid_ai/Messages.g.swift',
  ),
)
/// Whether the on-device model can be used for inference right now.
///
/// The values describe the model on the current device or browser, not the
/// network. A model that is [downloadable] has not been installed yet, so
/// on-device inference is not possible until the download finishes.
enum OnDeviceModelAvailability {
  /// The model is installed and ready for inference.
  available,

  /// The model can be downloaded but is not installed.
  downloadable,

  /// The model is being downloaded and cannot be used until the download
  /// completes.
  downloading,

  /// The device or browser cannot run an on-device model, for example because
  /// the hardware is unsupported or the browser does not provide the required
  /// API.
  unavailable,
}

/// Which on-device model the platform should use, when it offers a choice.
///
/// Only Android offers a choice. Gemini Nano is available in a stable release
/// and in preview releases that are newer and not yet widely deployed. Other
/// platforms ignore this value.
enum OnDeviceModelCategory {
  /// The latest stable model, fully tested and available on consumer devices.
  /// This is the default.
  stable,

  /// The latest preview model with full performance, such as Gemini Nano 4
  /// Full. It is designed for higher reasoning power and complex tasks.
  /// Preview models need the AICore Developer Preview on the device, and are
  /// reported as unavailable until the device is enrolled.
  preview,

  /// The latest preview model that is optimized for speed and lower latency,
  /// such as Gemini Nano 4 Fast. It needs the AICore Developer Preview on the
  /// device, and is reported as unavailable until the device is enrolled.
  previewFast,
}

/// How a request chooses between the on-device model and the cloud model.
///
/// The on-device model is the one selected by [OnDeviceModelCategory] where the
/// platform offers a choice. The cloud model is a Gemini model that the caller
/// names for the request.
enum InferenceMode {
  /// Use the on-device model if it is available and can serve the request.
  /// Otherwise, fall back to the cloud model.
  preferOnDevice,

  /// Use the on-device model. If it is not available, fail instead of using the
  /// cloud.
  onlyOnDevice,

  /// Use the cloud model. If the device is offline, fall back to the on-device
  /// model. Other cloud failures are not retried on the device.
  preferInCloud,

  /// Use the cloud model. If the cloud model is not available, fail instead of
  /// using the on-device model.
  onlyInCloud,
}

/// Where a response was generated.
enum InferenceSource {
  /// The on-device model generated the response, so the prompt did not leave
  /// the device.
  onDevice,

  /// The cloud model generated the response.
  inCloud,
}

/// The state of the on-device model on the current device or browser.
class OnDeviceModelStatus {
  OnDeviceModelStatus({required this.availability, this.modelName});

  /// Whether the on-device model can be used right now.
  final OnDeviceModelAvailability availability;

  /// The name the platform reports for the on-device model, such as the Gemini
  /// Nano version on Android.
  ///
  /// This is null when the platform does not report a name or when the model
  /// is not [OnDeviceModelAvailability.available]. Web browsers do not report
  /// a model name.
  final String? modelName;
}

/// How far along an on-device model download is.
class OnDeviceModelDownloadProgress {
  OnDeviceModelDownloadProgress({required this.fraction});

  /// The portion of the download that has finished, from 0.0 (nothing
  /// downloaded) to 1.0 (complete).
  ///
  /// The platforms report different amounts of detail, so only this common
  /// value is exposed.
  final double fraction;
}

/// A generated text response and where it came from.
class TextGenerationResult {
  TextGenerationResult({required this.text, required this.source});

  /// The generated text.
  final String text;

  /// Whether the on-device model or the cloud model generated [text].
  final InferenceSource source;
}

/// Calls from Dart into the Android and iOS host code.
@HostApi()
abstract class FirebaseHybridAiHostApi {
  /// Returns the state of the on-device model on this device, for the given
  /// [category] of model where the platform offers a choice.
  @async
  OnDeviceModelStatus checkOnDeviceStatus(OnDeviceModelCategory category);

  /// Generates text for [prompt] using the on-device model, the cloud model, or
  /// both, as chosen by [mode].
  ///
  /// [category] selects the on-device model where the platform offers a
  /// choice, and [cloudModelName] names the Gemini model used for cloud
  /// inference.
  @async
  TextGenerationResult generateText(
    String prompt,
    InferenceMode mode,
    OnDeviceModelCategory category,
    String cloudModelName,
  );
}

/// Streams from the Android and iOS host code to Dart.
@EventChannelApi()
abstract class FirebaseHybridAiEventsApi {
  /// Starts downloading the on-device model and streams its progress.
  ///
  /// The stream ends when the download completes and emits an error if it
  /// fails. Cancelling the subscription stops listening to the download.
  ///
  /// Pigeon event channels cannot take parameters, so the category of model to
  /// download is chosen with the channel's instance name. The host code
  /// registers one channel for each [OnDeviceModelCategory], named after the
  /// category's `name`, and Dart opens the matching one.
  OnDeviceModelDownloadProgress downloadOnDeviceModel();
}
