import Foundation

/// A failure that Dart receives as a `PlatformException` with the same `code` as on Android.
///
/// The codes are shared with the Android implementation, because Dart turns them into exceptions. A code that Dart does
/// not know becomes a plain `FirebaseHybridAiException`.
struct HybridAiFailure: Error {
  /// Firebase has no default app, so no request can be made.
  static let firebaseNotInitialized = "firebase-not-initialized"

  /// On-device inference was required, or was the only choice left, and the on-device model cannot serve the request.
  static let onDeviceUnavailable = "on-device-unavailable"

  /// The model failed to produce a response.
  static let generationFailed = "generation-failed"

  /// The model answered with no text.
  static let emptyResponse = "empty-response"

  /// A schema sent from Dart is not a schema the plugin understands.
  static let invalidSchema = "invalid-schema"

  /// This version of iOS, or this build of the plugin, cannot run the request at all.
  static let unimplemented = "unimplemented"

  /// The code that Dart switches on.
  let code: String

  /// A short description for the person reading the exception.
  let message: String

  /// The original error text, if there was one.
  let details: String?

  /// Creates a failure with the given [code] and [message].
  init(_ code: String, _ message: String, details: String? = nil) {
    self.code = code
    self.message = message
    self.details = details
  }

  /// The error that Pigeon returns to Dart.
  var pigeonError: PigeonError {
    PigeonError(code: code, message: message, details: details)
  }

  /// Converts any [error] thrown while generating into an error for Dart.
  ///
  /// A `HybridAiFailure` and a `PigeonError` keep their codes. Anything else becomes `generation-failed`, with the
  /// original error text in the details.
  static func pigeonError(from error: Error) -> PigeonError {
    if let failure = error as? HybridAiFailure {
      return failure.pigeonError
    }
    if let pigeonError = error as? PigeonError {
      return pigeonError
    }
    return PigeonError(
      code: generationFailed,
      message: error.localizedDescription,
      details: String(describing: error)
    )
  }
}
