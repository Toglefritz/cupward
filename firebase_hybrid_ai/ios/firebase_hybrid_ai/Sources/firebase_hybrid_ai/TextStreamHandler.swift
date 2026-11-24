import Flutter
import Foundation

/// Streams the response to one prompt to Dart, one chunk at a time.
///
/// The handler belongs to a single request. It is registered on an event channel named by the request's token, and it
/// starts generating when Dart listens to that channel. Each chunk is sent on the main thread, as Flutter requires. The
/// stream ends when the model finishes, and reports an error if it fails. Cancelling the Dart subscription cancels the
/// task, which stops the generation.
///
/// [onFinished] is called once the request is over for any reason, so the plugin can unregister the channel.
final class TextStreamHandler: StreamTextGenerationStreamHandler {
  /// Creates a handler that runs [generate] when Dart starts listening.
  ///
  /// [generate] receives a function that sends one chunk to Dart.
  init(
    generate: @escaping (@escaping @Sendable (TextGenerationChunk) async -> Void) async throws -> Void,
    onFinished: @escaping () -> Void
  ) {
    self.generate = generate
    self.onFinished = onFinished
  }

  private let generate: (@escaping @Sendable (TextGenerationChunk) async -> Void) async throws -> Void
  private let onFinished: () -> Void

  /// The running generation, or nil before Dart listens and after the request finishes.
  private var task: Task<Void, Never>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<TextGenerationChunk>) {
    task = Task { @MainActor in
      do {
        try await generate { chunk in
          // A chunk that arrives after cancelling is dropped, because the channel is already closed.
          await MainActor.run {
            if !Task.isCancelled {
              sink.success(chunk)
            }
          }
        }
        if !Task.isCancelled {
          sink.endOfStream()
        }
      } catch is CancellationError {
        // Dart cancelled, so there is nobody to tell.
      } catch {
        if !Task.isCancelled {
          let pigeonError = HybridAiFailure.pigeonError(from: error)
          sink.error(code: pigeonError.code, message: pigeonError.message, details: pigeonError.details)
        }
      }
      onFinished()
    }
  }

  override func onCancel(withArguments arguments: Any?) {
    task?.cancel()
    task = nil
    onFinished()
  }

  /// Stops any running generation. Called when the plugin detaches.
  func dispose() {
    task?.cancel()
    task = nil
  }
}
