import 'package:pigeon/pigeon.dart';

// This file is where you define the interface between Dart code and host
// platform code. After editing this file, run
//   dart run pigeon --input pigeon/messages.dart
// to re-generate all of the output files.
//
// If you add new platforms to your plugin, add the corresponding output
// options in the PigeonOptions below.
//
// To learn more about Pigeon, see https://pub.dev/packages/pigeon.

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'firebase_hybrid_ai',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/example/firebase_hybrid_ai/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.firebase_hybrid_ai'),
    swiftOut: [
      'ios/firebase_hybrid_ai/Sources/firebase_hybrid_ai/Messages.g.swift',
    ],
  ),
)
@HostApi()
abstract class FirebaseHybridAiPluginApi {
  /// Returns the system version of the host platform.
  String getPlatformVersion();
}
