import 'firebase_hybrid_ai_exception.dart';

/// Thrown when a call needs Firebase but no default Firebase app exists.
///
/// This typically means `Firebase.initializeApp` has not completed before the call. Initialize Firebase, with
/// `firebase_core`, before using this plugin.
class FirebaseNotInitializedException extends FirebaseHybridAiException {
  /// Creates the exception with the platform's [message] and [details].
  const new({super.message, super.details}) : super(code: 'firebase-not-initialized');
}
