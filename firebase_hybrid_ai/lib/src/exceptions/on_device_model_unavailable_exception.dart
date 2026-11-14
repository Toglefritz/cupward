import '../messages.g.dart';
import 'firebase_hybrid_ai_exception.dart';

/// Thrown when a request needs the on-device model and the device cannot provide it.
///
/// This is reported for an [InferenceMode.onlyOnDevice] request when the model is not installed, is still
/// downloading, or is not supported on the device. Check the model with `checkOnDeviceStatus`, download it with
/// `downloadOnDeviceModel`, or use an inference mode that can fall back to the cloud.
class OnDeviceModelUnavailableException extends FirebaseHybridAiException {
  /// Creates the exception with the platform's [message] and [details].
  const new({super.message, super.details}) : super(code: 'on-device-unavailable');
}
