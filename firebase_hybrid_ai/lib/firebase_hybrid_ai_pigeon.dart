import 'package:flutter/foundation.dart';

import 'firebase_hybrid_ai_platform_interface.dart';
import 'src/messages.g.dart';

/// An implementation of [FirebaseHybridAiPlatform] that uses Pigeon, for
/// non-web platforms.
class PigeonFirebaseHybridAi extends FirebaseHybridAiPlatform {
  /// Creates a new plugin implementation instance.
  PigeonFirebaseHybridAi({@visibleForTesting FirebaseHybridAiPluginApi? api})
    : _hostApi = api ?? FirebaseHybridAiPluginApi();

  final FirebaseHybridAiPluginApi _hostApi;

  @override
  Future<String?> getPlatformVersion() async {
    return _hostApi.getPlatformVersion();
  }
}
