import Flutter
import UIKit

/// iOS host implementation of the plugin.
///
/// Registers the Pigeon host API and event streams. The Firebase AI Logic hybrid inference calls for Apple platforms
/// are not implemented yet, so every call reports that to Dart instead of returning a result that could be mistaken
/// for a real device capability.
public class FirebaseHybridAiPlugin: NSObject, FlutterPlugin, FirebaseHybridAiHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FirebaseHybridAiPlugin()
    FirebaseHybridAiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    DownloadOnDeviceModelStreamHandler.register(
      with: registrar.messenger(),
      streamHandler: UnimplementedDownloadHandler()
    )
  }

  func checkOnDeviceStatus() async throws -> OnDeviceModelStatus {
    throw PigeonError(
      code: "unimplemented",
      message: "On-device model status is not implemented on iOS.",
      details: nil
    )
  }
}

/// Reports that downloading is not implemented. On Apple platforms the system downloads the on-device model when
/// Apple Intelligence is enabled, so an app cannot start a download.
private class UnimplementedDownloadHandler: DownloadOnDeviceModelStreamHandler {
  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<OnDeviceModelDownloadProgress>) {
    sink.error(
      code: "unimplemented",
      message: "Downloading the on-device model is not supported on iOS.",
      details: nil
    )
  }
}
