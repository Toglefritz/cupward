import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that [FirebaseHybridAi] forwards calls to the active platform implementation.
///
/// The platform implementation is replaced with a fake, so no native or browser code runs.
void main() {
  late FirebaseHybridAiPlatform originalPlatform;

  setUp(() {
    originalPlatform = FirebaseHybridAiPlatform.instance;
  });

  tearDown(() {
    FirebaseHybridAiPlatform.instance = originalPlatform;
  });

  group('downloadOnDeviceModel', () {
    /// Progress events must reach the caller in order, and the stream must end when the platform's does.
    test('forwards progress from the platform and completes', () async {
      // Arrange
      FirebaseHybridAiPlatform.instance = _FakePlatform(
        progress: <double>[0, 0.5, 1],
      );

      // Act
      final List<double> fractions = await FirebaseHybridAi()
          .downloadOnDeviceModel()
          .map((OnDeviceModelDownloadProgress progress) => progress.fraction)
          .toList();

      // Assert
      expect(fractions, <double>[0, 0.5, 1]);
    });
  });

  group('checkOnDeviceStatus', () {
    /// The result from the platform must reach the caller unchanged.
    test('returns the status from the platform', () async {
      // Arrange
      final OnDeviceModelStatus status = OnDeviceModelStatus(
        availability: OnDeviceModelAvailability.available,
        modelName: 'nano-v4-full',
      );
      FirebaseHybridAiPlatform.instance = _FakePlatform(result: status);

      // Act
      final OnDeviceModelStatus result = await FirebaseHybridAi().checkOnDeviceStatus();

      // Assert
      expect(result, status);
    });

    /// A failure on the platform must not be swallowed or rewrapped by the public class.
    test('propagates exceptions from the platform', () async {
      // Arrange
      FirebaseHybridAiPlatform.instance = _FakePlatform(error: const FirebaseNotInitializedException());

      // Act and assert
      expect(FirebaseHybridAi().checkOnDeviceStatus(), throwsA(isA<FirebaseNotInitializedException>()));
    });
  });
}

/// A platform implementation that returns a preset [result] or throws a preset [error].
class _FakePlatform extends FirebaseHybridAiPlatform {
  /// Creates a fake that returns [result], or throws [error] when one is given.
  new({this.result, this.error, this.progress = const <double>[]});

  /// The fractions emitted by [downloadOnDeviceModel].
  final List<double> progress;

  /// The value returned by [checkOnDeviceStatus], when no [error] is set.
  final OnDeviceModelStatus? result;

  /// The exception thrown by [checkOnDeviceStatus], if any.
  final Exception? error;

  @override
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel() {
    return Stream<OnDeviceModelDownloadProgress>.fromIterable(
      progress.map((double fraction) => OnDeviceModelDownloadProgress(fraction: fraction)),
    );
  }

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus() async {
    if (error != null) {
      throw error!;
    }

    return result!;
  }
}
