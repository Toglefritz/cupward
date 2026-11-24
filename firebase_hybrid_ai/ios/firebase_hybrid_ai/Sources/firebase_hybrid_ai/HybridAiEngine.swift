import Foundation

#if canImport(FirebaseCore)
  import FirebaseCore
#endif
#if canImport(FoundationModels)
  import FoundationModels
#endif

/// What the plugin needs from a platform's generation backend.
///
/// The protocol has no availability requirement, so the plugin can hold an engine on every version of iOS that it
/// supports. `HybridAiEngineFactory` decides whether this device can have one.
protocol HybridAiEngine {
  /// Returns whether the system's on-device model can be used right now.
  func checkOnDeviceStatus() -> OnDeviceModelStatus

  /// Generates text for [prompt], on the model or models that [mode] allows.
  func generateText(prompt: String, mode: InferenceMode) async throws -> TextGenerationResult

  /// Generates a response that should match the JSON schema in [schemaJson].
  ///
  /// The schema constrains the model when the platform can build it. Otherwise [instructedPrompt], which describes the
  /// schema in words, is sent instead, and the response is reported as not enforced.
  func generateStructured(
    prompt: String,
    instructedPrompt: String,
    schemaJson: String,
    mode: InferenceMode
  ) async throws -> StructuredTextResponse

  /// Generates text for [prompt] and calls [send] with each piece, in order, until the response is complete.
  ///
  /// Cancelling the calling task stops the generation.
  func streamText(
    prompt: String,
    mode: InferenceMode,
    send: @escaping @Sendable (TextGenerationChunk) async -> Void
  ) async throws
}

/// Creates the engine for this device.
enum HybridAiEngineFactory {
  /// Returns an engine that sends requests to a cloud model named [cloudModelName] and to the system's on-device model.
  ///
  /// Every request needs a default Firebase app, as on Android, even when it only uses the on-device model, so that a
  /// setup mistake shows up the same way on every platform.
  ///
  /// Throws a failure with the `firebase-not-initialized` code if Firebase has not been configured, and with the
  /// `unimplemented` code if the device runs a version of iOS without the Foundation Models framework.
  static func make(cloudModelName: String) throws -> HybridAiEngine {
    #if canImport(FirebaseCore)
      guard FirebaseApp.app() != nil else {
        throw HybridAiFailure(
          HybridAiFailure.firebaseNotInitialized,
          "Firebase must be initialized before the on-device or cloud model can be used."
        )
      }
    #endif

    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return FoundationModelsEngine(cloudModelName: cloudModelName)
      }
    #endif

    throw HybridAiFailure(
      HybridAiFailure.unimplemented,
      "Generation needs iOS 26 or later, which is the first version with Apple's Foundation Models framework."
    )
  }
}
