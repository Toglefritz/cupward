import Flutter
import UIKit

/// iOS host implementation of the plugin.
///
/// Registers the Pigeon host API and forwards each call to a `HybridAiEngine`, which runs it on Apple's on-device model,
/// a Gemini model, or both, as the inference mode says. Pigeon calls the `async` functions on the main thread, and an
/// error thrown from one is returned to Dart as a `PlatformException`.
public class FirebaseHybridAiPlugin: NSObject, FlutterPlugin, FirebaseHybridAiHostApi {
  /// The messenger of the attached engine, which is needed to register event channels while the plugin runs.
  private var messenger: FlutterBinaryMessenger?

  /// The streamed generations that are prepared or running, by token. A request is added by `prepareTextStream` and
  /// removed when its stream ends, fails, or is cancelled, or when the plugin detaches.
  private var textStreams: [String: (handler: TextStreamHandler, channel: StreamTextGenerationEventChannel)] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FirebaseHybridAiPlugin()
    instance.messenger = registrar.messenger()
    FirebaseHybridAiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)

    // Each category has its own channel, named after the category, because event channels cannot take parameters.
    for instanceName in ["stable", "preview", "previewFast"] {
      DownloadOnDeviceModelStreamHandler.register(
        with: registrar.messenger(),
        instanceName: instanceName,
        streamHandler: UnsupportedDownloadHandler()
      )
    }

    registrar.publish(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    FirebaseHybridAiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
    for token in Array(textStreams.keys) {
      finishTextStream(token)
    }
    messenger = nil
  }

  /// Reports whether the system's on-device model can be used.
  ///
  /// The `category` is ignored, because Apple provides one on-device model.
  func checkOnDeviceStatus(category: OnDeviceModelCategory) async throws -> OnDeviceModelStatus {
    try engine(cloudModelName: "").checkOnDeviceStatus()
  }

  func generateText(
    prompt: String,
    mode: InferenceMode,
    category: OnDeviceModelCategory,
    cloudModelName: String
  ) async throws -> TextGenerationResult {
    do {
      return try await engine(cloudModelName: cloudModelName).generateText(prompt: prompt, mode: mode)
    } catch {
      throw HybridAiFailure.pigeonError(from: error)
    }
  }

  func generateStructured(
    prompt: String,
    instructedPrompt: String,
    schemaJson: String,
    mode: InferenceMode,
    category: OnDeviceModelCategory,
    cloudModelName: String
  ) async throws -> StructuredTextResponse {
    do {
      return try await engine(cloudModelName: cloudModelName).generateStructured(
        prompt: prompt,
        instructedPrompt: instructedPrompt,
        schemaJson: schemaJson,
        mode: mode
      )
    } catch {
      throw HybridAiFailure.pigeonError(from: error)
    }
  }

  /// Prepares a streamed generation and returns the token that names its event channel.
  ///
  /// The engine is created here so that a missing Firebase app is reported to the caller right away. The handler is
  /// registered under a new token and starts generating only when Dart listens to the channel.
  func prepareTextStream(
    prompt: String,
    mode: InferenceMode,
    category: OnDeviceModelCategory,
    cloudModelName: String
  ) async throws -> String {
    guard let messenger else {
      throw PigeonError(
        code: HybridAiFailure.generationFailed,
        message: "The plugin is not attached to a Flutter engine.",
        details: nil
      )
    }

    let engine = try engine(cloudModelName: cloudModelName)
    let token = UUID().uuidString
    let handler = TextStreamHandler(
      generate: { send in try await engine.streamText(prompt: prompt, mode: mode, send: send) },
      onFinished: { [weak self] in self?.finishTextStream(token) }
    )
    let channel = StreamTextGenerationStreamHandler.register(
      with: messenger,
      instanceName: token,
      streamHandler: handler
    )
    textStreams[token] = (handler, channel)

    return token
  }

  /// Ends the streamed generation with the given [token]: stops it, unregisters its channel, and forgets it.
  ///
  /// This is safe to call more than once for the same token, because the stream can finish and be cancelled at nearly the
  /// same time.
  private func finishTextStream(_ token: String) {
    guard let stream = textStreams.removeValue(forKey: token) else { return }

    stream.channel.setStreamHandler(nil)
    stream.handler.dispose()
  }

  /// Returns the engine for this device, or the error that says why there is none.
  private func engine(cloudModelName: String) throws -> HybridAiEngine {
    do {
      return try HybridAiEngineFactory.make(cloudModelName: cloudModelName)
    } catch {
      throw HybridAiFailure.pigeonError(from: error)
    }
  }
}

/// Reports that downloading is not supported. On Apple platforms the system downloads the on-device model when Apple
/// Intelligence is turned on, so an app can read the model's status but cannot start a download.
private class UnsupportedDownloadHandler: DownloadOnDeviceModelStreamHandler {
  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<OnDeviceModelDownloadProgress>) {
    sink.error(
      code: HybridAiFailure.unimplemented,
      message: "Apple platforms download the on-device model when Apple Intelligence is turned on. An app cannot start the download.",
      details: nil
    )
  }
}
