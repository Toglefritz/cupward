import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/src/messages.g.dart';
import 'package:firebase_hybrid_ai/src/platform/pigeon_firebase_hybrid_ai.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies how [PigeonFirebaseHybridAi] returns host results and translates platform errors.
///
/// The generated host API is replaced with a fake, so no message channel is used.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('checkOnDeviceStatus', () {
    /// The status from the host, including the optional model name, must reach the caller unchanged.
    test('returns the status reported by the host', () async {
      // Arrange
      final OnDeviceModelStatus status = OnDeviceModelStatus(
        availability: OnDeviceModelAvailability.available,
        modelName: 'nano-v4-full',
      );
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(api: _FakeHostApi(status: status));

      // Act
      final OnDeviceModelStatus result = await platform.checkOnDeviceStatus();

      // Assert
      expect(result.availability, OnDeviceModelAvailability.available);
      expect(result.modelName, 'nano-v4-full');
    });

    /// A missing Firebase app is a condition callers can fix, so it gets its own exception type.
    test('throws FirebaseNotInitializedException for the firebase-not-initialized code', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(
          error: PlatformException(code: 'firebase-not-initialized', message: 'No app'),
        ),
      );

      // Act and assert
      expect(platform.checkOnDeviceStatus(), throwsA(isA<FirebaseNotInitializedException>()));
    });

    /// Platforms that have no implementation report this code, and callers use the type to disable features.
    test('throws HybridAiNotSupportedException for the unimplemented code', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(error: PlatformException(code: 'unimplemented')),
      );

      // Act and assert
      expect(platform.checkOnDeviceStatus(), throwsA(isA<HybridAiNotSupportedException>()));
    });

    /// Unknown codes must still surface as the base exception with the original code and message.
    test('throws FirebaseHybridAiException with the platform code for other errors', () async {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(
          error: PlatformException(code: 'status-check-failed', message: 'AICore error'),
        ),
      );

      // Act
      FirebaseHybridAiException? caught;
      try {
        await platform.checkOnDeviceStatus();
      } on FirebaseHybridAiException catch (exception) {
        caught = exception;
      }

      // Assert
      expect(caught, isNotNull);
      expect(caught!.code, 'status-check-failed');
      expect(caught.message, 'AICore error');
    });
  });
}

/// A host API that returns a preset [status] or throws a preset [error] without using a message channel.
class _FakeHostApi extends FirebaseHybridAiHostApi {
  /// Creates a fake that returns [status], or throws [error] when one is given.
  new({this.status, this.error});

  /// The value returned by [checkOnDeviceStatus], when no [error] is set.
  final OnDeviceModelStatus? status;

  /// The exception thrown by [checkOnDeviceStatus], if any.
  final PlatformException? error;

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus() async {
    if (error != null) {
      throw error!;
    }

    return status!;
  }
}
