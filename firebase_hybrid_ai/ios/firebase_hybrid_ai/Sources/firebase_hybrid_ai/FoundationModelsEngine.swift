import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  #if canImport(FirebaseAILogic)
    import FirebaseAILogic
  #endif

  /// Generates responses with Apple's Foundation Models framework, on the system's on-device model or on a Gemini model.
  ///
  /// Firebase AI Logic's Apple SDK no longer has its own hybrid model. Since version 13, the SDK provides a Gemini model
  /// that plugs into `LanguageModelSession`, the same session type that Apple's on-device model uses. This engine adds
  /// the part that makes the two hybrid: it picks the model for each request from the inference mode, and falls back
  /// from one to the other in the same cases as the Android and web implementations.
  ///
  /// - The on-device model needs iOS 26 and a device with Apple Intelligence turned on. The system downloads it, so an
  ///   app can read its status but cannot start a download.
  /// - The Gemini model needs iOS 27 and a build with Xcode 27 or later. Without either, a cloud request fails and a
  ///   hybrid request that falls back to the cloud reports why.
  ///
  /// A new session is made for every request, because a session keeps the conversation so far, and each call here is
  /// a single turn.
  @available(iOS 26.0, *)
  final class FoundationModelsEngine: HybridAiEngine {
    /// Creates an engine that uses the Gemini model named [cloudModelName] for cloud requests.
    init(cloudModelName: String) {
      self.cloudModelName = cloudModelName
    }

    /// The name that Firebase AI Logic reports for the on-device model in its responses, used here as the model name in
    /// status results.
    static let onDeviceModelName = "apple-foundation-models-system-language-model"

    /// The Gemini model used for cloud requests.
    private let cloudModelName: String

    /// Where a request can run.
    private enum Target {
      case onDevice
      case cloud

      /// The source that Dart receives for a response from this target.
      var source: InferenceSource {
        switch self {
        case .onDevice: return .onDevice
        case .cloud: return .inCloud
        }
      }
    }

    // MARK: - Status

    func checkOnDeviceStatus() -> OnDeviceModelStatus {
      switch SystemLanguageModel.default.availability {
      case .available:
        return OnDeviceModelStatus(availability: .available, modelName: Self.onDeviceModelName)
      case .unavailable(.modelNotReady):
        // The system is still downloading the model, and the app cannot speed that up.
        return OnDeviceModelStatus(availability: .downloading)
      case .unavailable:
        // The device is not eligible, or the person has not turned on Apple Intelligence. An app cannot fix either, so
        // this is not "downloadable", which on Android means that the app can start the download.
        return OnDeviceModelStatus(availability: .unavailable)
      }
    }

    // MARK: - Generation

    func generateText(prompt: String, mode: InferenceMode) async throws -> TextGenerationResult {
      let (text, target) = try await run(mode: mode) { target in
        let session = try self.makeSession(for: target)
        return try await session.respond(to: prompt).content
      }

      guard !text.isEmpty else { throw Self.emptyResponse }

      return TextGenerationResult(text: text, source: target.source)
    }

    func generateStructured(
      prompt: String,
      instructedPrompt: String,
      schemaJson: String,
      mode: InferenceMode
    ) async throws -> StructuredTextResponse {
      // A schema that is not valid is reported before any request, so it is not mistaken for a generation failure. A
      // valid schema that the framework cannot build, such as an array at the root, is requested in the prompt instead.
      _ = try JsonSchemaConverter.parse(schemaJson)
      let schema = try? JsonSchemaConverter.generationSchema(from: schemaJson)

      let (result, target) = try await run(mode: mode) { target -> (String, Bool) in
        let session = try self.makeSession(for: target)
        if let schema {
          let response = try await session.respond(to: prompt, schema: schema)
          return (response.content.jsonString, true)
        }
        return (try await session.respond(to: instructedPrompt).content, false)
      }

      guard !result.0.isEmpty else { throw Self.emptyResponse }

      return StructuredTextResponse(text: result.0, source: target.source, isSchemaEnforced: result.1)
    }

    func streamText(
      prompt: String,
      mode: InferenceMode,
      send: @escaping @Sendable (TextGenerationChunk) async -> Void
    ) async throws {
      // Once a chunk has been sent, the response cannot move to the other model, because the person would see two
      // answers joined together.
      var hasSent = false

      let plan = Self.plan(for: mode)
      for (index, target) in plan.enumerated() {
        do {
          let session = try makeSession(for: target)
          var sentSoFar = ""
          // Each snapshot holds everything generated so far, and Dart wants only what is new.
          for try await snapshot in session.streamResponse(to: prompt) {
            try Task.checkCancellation()
            let full = snapshot.content
            guard full.count > sentSoFar.count else { continue }

            let addition = String(full.dropFirst(sentSoFar.count))
            sentSoFar = full
            hasSent = true
            await send(TextGenerationChunk(text: addition, source: target.source))
          }
          if sentSoFar.isEmpty { throw Self.emptyResponse }
          return
        } catch {
          if hasSent || !Self.shouldFallBack(after: error, from: target, in: mode, isLast: index == plan.count - 1) {
            throw error
          }
        }
      }
    }

    // MARK: - Choosing the model

    /// The models to try for [mode], in order.
    private static func plan(for mode: InferenceMode) -> [Target] {
      switch mode {
      case .preferOnDevice: return [.onDevice, .cloud]
      case .onlyOnDevice: return [.onDevice]
      case .preferInCloud: return [.cloud, .onDevice]
      case .onlyInCloud: return [.cloud]
      }
    }

    /// Runs [operation] on the first model in the plan for [mode] that can answer, and returns its result with the model.
    ///
    /// The on-device model is given up on after any failure, because it is the one that is often unavailable or unable to
    /// serve a request, such as one that is too long. The cloud model is given up on only when the device is offline,
    /// since any other cloud failure, such as a rejected key, would not be fixed by the on-device model.
    private func run<Result>(
      mode: InferenceMode,
      _ operation: (Target) async throws -> Result
    ) async throws -> (Result, Target) {
      let plan = Self.plan(for: mode)
      var lastError: Error = HybridAiFailure(HybridAiFailure.generationFailed, "No model was tried.")

      for (index, target) in plan.enumerated() {
        do {
          return (try await operation(target), target)
        } catch {
          lastError = error
          if !Self.shouldFallBack(after: error, from: target, in: mode, isLast: index == plan.count - 1) {
            break
          }
        }
      }

      throw lastError
    }

    /// Whether to try the next model in the plan after [error] from [target].
    private static func shouldFallBack(after error: Error, from target: Target, in mode: InferenceMode, isLast: Bool)
      -> Bool
    {
      if isLast || error is CancellationError || Task.isCancelled {
        return false
      }
      switch target {
      case .onDevice: return true
      case .cloud: return isOffline(error)
      }
    }

    /// Whether [error] means that the device cannot reach the network.
    ///
    /// The Gemini model wraps network failures in its own error type, which this plugin cannot name, so besides
    /// `URLError` the check looks at the error's text.
    private static func isOffline(_ error: Error) -> Bool {
      let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed,
        .dataNotAllowed, .internationalRoamingOff,
      ]
      if let urlError = error as? URLError {
        return offlineCodes.contains(urlError.code)
      }
      let text = String(describing: error)
      return text.contains("networkFailure") || text.contains("NSURLErrorDomain")
    }

    // MARK: - Sessions

    /// Creates a session on the model for [target], or throws why that model cannot be used.
    private func makeSession(for target: Target) throws -> LanguageModelSession {
      switch target {
      case .onDevice:
        switch SystemLanguageModel.default.availability {
        case .available:
          return LanguageModelSession(model: SystemLanguageModel.default)
        case .unavailable(let reason):
          throw HybridAiFailure(
            HybridAiFailure.onDeviceUnavailable,
            "The on-device model is not available: \(Self.describe(reason)).",
            details: String(describing: reason)
          )
        }

      case .cloud:
        return try makeCloudSession()
      }
    }

    /// Creates a session on the Gemini model.
    private func makeCloudSession() throws -> LanguageModelSession {
      #if canImport(FirebaseAILogic) && compiler(>=6.4)
        if #available(iOS 27.0, *) {
          let ai = FirebaseAI.firebaseAI(backend: .googleAI())
          return LanguageModelSession(model: ai.geminiLanguageModel(name: cloudModelName))
        }
        throw HybridAiFailure(
          HybridAiFailure.generationFailed,
          "Cloud models in the Foundation Models framework need iOS 27 or later."
        )
      #else
        throw HybridAiFailure(
          HybridAiFailure.generationFailed,
          "This build of the plugin has no cloud model. It needs Swift Package Manager and Xcode 27 or later."
        )
      #endif
    }

    /// Words for why the system model cannot be used, for the error message.
    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
      switch reason {
      case .deviceNotEligible: return "this device does not support Apple Intelligence"
      case .appleIntelligenceNotEnabled: return "Apple Intelligence is turned off in Settings"
      case .modelNotReady: return "the system is still downloading the model"
      @unknown default: return "the system reports that it is unavailable"
      }
    }

    /// The failure for a model that answered with no text.
    private static var emptyResponse: HybridAiFailure {
      HybridAiFailure(HybridAiFailure.emptyResponse, "The model returned a response that holds no text.")
    }
  }
#endif
