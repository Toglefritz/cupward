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

/// Calls from Dart into the Android and iOS host code.
@HostApi()
abstract class FirebaseHybridAiHostApi {
  /// Returns the state of the on-device model on this device.
  @async
  OnDeviceModelStatus checkOnDeviceStatus();
}
