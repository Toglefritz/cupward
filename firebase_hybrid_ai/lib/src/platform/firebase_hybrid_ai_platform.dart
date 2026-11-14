import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../exceptions/firebase_not_initialized_exception.dart';
import '../exceptions/hybrid_ai_not_supported_exception.dart';
import '../firebase_hybrid_ai.dart';
import '../messages.g.dart';
import 'pigeon_firebase_hybrid_ai.dart';

/// The interface that platform implementations of the plugin must extend.
///
/// The public [FirebaseHybridAi] class delegates to [instance]. Android and iOS use [PigeonFirebaseHybridAi], and
/// the web implementation replaces it when the plugin registers itself in a browser.
abstract class FirebaseHybridAiPlatform extends PlatformInterface {
  /// Creates a platform implementation.
  new() : super(token: _token);

  static final Object _token = Object();

  static FirebaseHybridAiPlatform _instance = PigeonFirebaseHybridAi();

  /// The implementation that [FirebaseHybridAi] delegates to.
  ///
  /// Defaults to [PigeonFirebaseHybridAi].
  static FirebaseHybridAiPlatform get instance => _instance;

  /// Replaces the implementation. Platform packages call this when they register themselves.
  static set instance(FirebaseHybridAiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the state of the on-device model on the current device or browser.
  ///
  /// Throws a [FirebaseNotInitializedException] if the platform needs Firebase and it is not initialized, and a
  /// [HybridAiNotSupportedException] if the platform does not provide the capability.
  Future<OnDeviceModelStatus> checkOnDeviceStatus() {
    throw UnimplementedError('checkOnDeviceStatus() has not been implemented.');
  }
}
