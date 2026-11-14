import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai_pigeon.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFirebaseHybridAiPlatform
    with MockPlatformInterfaceMixin
    implements FirebaseHybridAiPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = FirebaseHybridAiPlatform.instance;

  test('PigeonFirebaseHybridAi is the default instance', () {
    expect(initialPlatform, isInstanceOf<PigeonFirebaseHybridAi>());
  });

  test('getPlatformVersion', () async {
    FirebaseHybridAi firebaseHybridAiPlugin = FirebaseHybridAi();
    MockFirebaseHybridAiPlatform fakePlatform = MockFirebaseHybridAiPlatform();
    FirebaseHybridAiPlatform.instance = fakePlatform;

    expect(await firebaseHybridAiPlugin.getPlatformVersion(), '42');
  });
}
