import Flutter
import UIKit

/// iOS host implementation of the plugin.
///
/// Registers the Pigeon host API. The Firebase AI Logic hybrid inference calls for Apple platforms are not
/// implemented yet, so every call reports that to Dart instead of returning a result that could be mistaken for
/// a real device capability.
public class FirebaseHybridAiPlugin: NSObject, FlutterPlugin, FirebaseHybridAiHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FirebaseHybridAiPlugin()
    FirebaseHybridAiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func checkOnDeviceStatus() async throws -> OnDeviceModelStatus {
    throw PigeonError(
      code: "unimplemented",
      message: "On-device model status is not implemented on iOS.",
      details: nil
    )
  }
}
