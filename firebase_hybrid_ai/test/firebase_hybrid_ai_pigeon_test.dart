import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai_pigeon.dart';
import 'package:firebase_hybrid_ai/src/messages.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getPlatformVersion', () async {
    final api = FakeFirebaseHybridAiPluginApi(platformVersion: '42');
    final plugin = PigeonFirebaseHybridAi(api: api);

    expect(await plugin.getPlatformVersion(), '42');
  });
}

/// Fake implementation of the Pigeon API that provides a pre-set response.
class FakeFirebaseHybridAiPluginApi implements FirebaseHybridAiPluginApi {
  FakeFirebaseHybridAiPluginApi({required this.platformVersion});

  final String platformVersion;

  @override
  Future<String> getPlatformVersion() async {
    return platformVersion;
  }

  @override
  // ignore: non_constant_identifier_names
  BinaryMessenger? get pigeonVar_binaryMessenger => null;

  @override
  // ignore: non_constant_identifier_names
  String get pigeonVar_messageChannelSuffix => '';
}
