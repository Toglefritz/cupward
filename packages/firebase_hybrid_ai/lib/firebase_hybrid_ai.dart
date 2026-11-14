
import 'firebase_hybrid_ai_platform_interface.dart';

class FirebaseHybridAi {
  Future<String?> getPlatformVersion() {
    return FirebaseHybridAiPlatform.instance.getPlatformVersion();
  }
}
