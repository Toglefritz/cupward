import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai_example/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the plugin against the real host platform on a device or in a browser.
///
/// The result depends on the hardware, so the test only requires that the call completes with a status and does not
/// assert which one. It needs a configured Firebase project. See FIREBASE_SETUP.md.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkOnDeviceStatus returns a status', (WidgetTester tester) async {
    // Arrange
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Act
    final OnDeviceModelStatus status = await FirebaseHybridAi().checkOnDeviceStatus();

    // Assert
    expect(OnDeviceModelAvailability.values, contains(status.availability));
  });
}
