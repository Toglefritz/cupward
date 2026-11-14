import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'firebase_hybrid_ai_pigeon.dart';

abstract class FirebaseHybridAiPlatform extends PlatformInterface {
  /// Constructs a FirebaseHybridAiPlatform.
  FirebaseHybridAiPlatform() : super(token: _token);

  static final Object _token = Object();

  static FirebaseHybridAiPlatform _instance = PigeonFirebaseHybridAi();

  /// The instance of [FirebaseHybridAiPlatform] to use.
  ///
  /// Defaults to [PigeonFirebaseHybridAi].
  static FirebaseHybridAiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FirebaseHybridAiPlatform] when
  /// they register themselves.
  static set instance(FirebaseHybridAiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
