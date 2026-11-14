import '../messages.g.dart';
import 'firebase_hybrid_ai_exception.dart';

/// Thrown when the current platform does not provide the requested capability.
///
/// This is reported for platforms that this plugin does not implement or that cannot offer the capability at all.
/// It does not mean the on-device model is merely absent. Absence is reported through
/// [OnDeviceModelAvailability.unavailable] instead. Callers can catch this type to disable AI features on such
/// platforms.
class HybridAiNotSupportedException extends FirebaseHybridAiException {
  /// Creates the exception with the platform's [message] and [details].
  const new({super.message, super.details}) : super(code: 'not-supported');
}
