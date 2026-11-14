import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai_example/screens/home/home_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies that the home screen shows the on-device model status returned by the plugin.
///
/// The plugin's platform implementation is replaced with a fake, so no Firebase or native code is involved.
void main() {
  late FirebaseHybridAiPlatform originalPlatform;

  setUp(() {
    originalPlatform = FirebaseHybridAiPlatform.instance;
  });

  tearDown(() {
    FirebaseHybridAiPlatform.instance = originalPlatform;
  });

  /// The screen checks the status as soon as it opens, so the result must appear without any interaction.
  testWidgets('shows the model status and name after opening', (WidgetTester tester) async {
    // Arrange
    FirebaseHybridAiPlatform.instance = _FakePlatform(
      result: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available, modelName: 'nano-v4-full'),
    );

    // Act
    await tester.pumpWidget(const MaterialApp(home: HomeRoute()));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Model: nano-v4-full'), findsOneWidget);
  });

  /// A failure must be shown to the user instead of leaving the screen blank or crashing the app.
  testWidgets('shows the error message when the check fails', (WidgetTester tester) async {
    // Arrange
    FirebaseHybridAiPlatform.instance = _FakePlatform(
      error: const FirebaseNotInitializedException(message: 'Firebase is not initialized.'),
    );

    // Act
    await tester.pumpWidget(const MaterialApp(home: HomeRoute()));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Firebase is not initialized.'), findsOneWidget);
  });
}

/// A platform implementation that returns a preset [result] or throws a preset [error].
class _FakePlatform extends FirebaseHybridAiPlatform {
  /// Creates a fake that returns [result], or throws [error] when one is given.
  new({this.result, this.error});

  /// The value returned by [checkOnDeviceStatus], when no [error] is set.
  final OnDeviceModelStatus? result;

  /// The exception thrown by [checkOnDeviceStatus], if any.
  final Exception? error;

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus() async {
    if (error != null) {
      throw error!;
    }

    return result!;
  }
}
