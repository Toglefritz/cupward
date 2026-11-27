import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

import '../on_device_model/on_device_model_service.dart';
import '../on_device_model/on_device_model_state.dart';

/// Decisions that brew feedback and recipe creation share about the hybrid AI system, which they reach only through
/// the `firebase_hybrid_ai` plugin.
abstract final class HybridAiSupport {
  /// Whether the plugin can serve requests on the platform the app runs on.
  ///
  /// It does on Android, on iOS, and in the browser. A device on one of those platforms can still be too old, such as
  /// an iPad that runs a version of iOS before the Foundation Models framework. The plugin then throws a
  /// `HybridAiNotSupportedException`, and the services report that the feature is unavailable. macOS and the other
  /// desktop platforms have no implementation of the plugin.
  static bool get isPlatformSupported =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns the mode for a request that may use either model, given what [model] knows about the device.
  ///
  /// A device that is known to have no on-device model, such as an iPad that cannot run Apple Intelligence, goes
  /// straight to the cloud model, so the request does not first try a model that cannot answer. Otherwise the
  /// on-device model is preferred, so the data stays on the device when it can. While the model is still being
  /// checked or downloaded the answer is not known, and the on-device model is preferred.
  static InferenceMode modeFor(OnDeviceModelService model) {
    return model.state == OnDeviceModelState.unavailable ? InferenceMode.onlyInCloud : InferenceMode.preferOnDevice;
  }
}
