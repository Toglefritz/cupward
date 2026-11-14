import Flutter
import UIKit

public class FirebaseHybridAiPlugin: NSObject, FlutterPlugin, FirebaseHybridAiPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FirebaseHybridAiPlugin()
    FirebaseHybridAiPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
