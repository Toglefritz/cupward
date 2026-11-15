import 'package:cupward/services/on_device_model/on_device_model_service.dart';
import 'package:cupward/services/on_device_model/on_device_model_state.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_hybrid_ai.dart';

/// Verifies how the on-device model service reports the model's status and runs a download, using a fake in place of
/// the plugin.
void main() {
  late FakeHybridAi hybridAi;
  late OnDeviceModelService service;

  setUp(() {
    hybridAi = FakeHybridAi();
    service = OnDeviceModelService(hybridAi: hybridAi, isSupported: true, pollInterval: const Duration(seconds: 1));
  });

  tearDown(() => service.dispose());

  group('OnDeviceModelService', () {
    /// Each platform availability must map to the state the home screen shows for it.
    test('reports each availability the platform returns', () async {
      final Map<OnDeviceModelAvailability, OnDeviceModelState> expected =
          <OnDeviceModelAvailability, OnDeviceModelState>{
        OnDeviceModelAvailability.available: OnDeviceModelState.available,
        OnDeviceModelAvailability.downloadable: OnDeviceModelState.downloadable,
        OnDeviceModelAvailability.unavailable: OnDeviceModelState.unavailable,
      };

      for (final MapEntry<OnDeviceModelAvailability, OnDeviceModelState> entry in expected.entries) {
        // Arrange
        hybridAi.availability = entry.key;

        // Act
        await service.checkStatus();

        // Assert
        expect(service.state, entry.value, reason: entry.key.name);
        expect(service.hasChecked, isTrue);
      }
    });

    /// iOS reports that hybrid inference is not supported, which means the device cannot run the model, not that
    /// the check failed.
    test('reports unavailable when the platform does not support hybrid inference', () async {
      // Arrange
      hybridAi.checkError = const HybridAiNotSupportedException(message: 'not on iOS');

      // Act
      await service.checkStatus();

      // Assert
      expect(service.state, OnDeviceModelState.unavailable);
    });

    /// Any other failure leaves the answer open, so the user can try again.
    test('reports unknown when the check fails', () async {
      // Arrange
      hybridAi.checkError = const FirebaseHybridAiException(code: 'internal');

      // Act
      await service.checkStatus();

      // Assert
      expect(service.state, OnDeviceModelState.unknown);
    });

    /// macOS has no plugin implementation, so the service must not call it there.
    test('reports unavailable without calling the plugin where unsupported', () async {
      // Arrange
      final OnDeviceModelService unsupported = OnDeviceModelService(hybridAi: hybridAi, isSupported: false);

      // Act
      await unsupported.checkStatus();

      // Assert
      expect(unsupported.state, OnDeviceModelState.unavailable);
      expect(hybridAi.checkCount, 0);
      unsupported.dispose();
    });

    /// The panel shows a progress bar that follows the platform's reports, then the model as ready.
    test('reports download progress and checks again when it finishes', () async {
      // Arrange
      await service.checkStatus();

      // Act
      service.download();
      hybridAi.downloadController.add(OnDeviceModelDownloadProgress(fraction: 0.4));
      await pumpEventQueue();

      // Assert
      expect(service.state, OnDeviceModelState.downloading);
      expect(service.downloadProgress, 0.4);

      // Act
      hybridAi.availability = OnDeviceModelAvailability.available;
      await hybridAi.downloadController.close();
      await pumpEventQueue();

      // Assert
      expect(service.state, OnDeviceModelState.available);
      expect(service.downloadProgress, isNull);
    });

    /// A failed download must let the user try again and say that it failed.
    test('returns to downloadable when the download fails', () async {
      // Arrange
      await service.checkStatus();
      service.download();

      // Act
      hybridAi.downloadController.addError(const FirebaseHybridAiException(code: 'network'));
      await pumpEventQueue();

      // Assert
      expect(service.state, OnDeviceModelState.downloadable);
      expect(service.didDownloadFail, isTrue);
    });

    /// Downloading only makes sense when the platform says the model can be downloaded.
    test('does not download unless the model is downloadable', () async {
      // Arrange
      hybridAi.availability = OnDeviceModelAvailability.available;
      await service.checkStatus();

      // Act
      service.download();

      // Assert
      expect(hybridAi.downloadCount, 0);
      expect(service.state, OnDeviceModelState.available);
    });

    /// A download that the app did not start reports no progress, so the service checks again until it finishes.
    testWidgets('checks again while a download it did not start is in progress', (WidgetTester tester) async {
      // Arrange
      hybridAi.availability = OnDeviceModelAvailability.downloading;
      await service.checkStatus();
      expect(service.state, OnDeviceModelState.downloading);
      expect(service.downloadProgress, isNull);

      // Act
      hybridAi.availability = OnDeviceModelAvailability.available;
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(service.state, OnDeviceModelState.available);
      final int checks = hybridAi.checkCount;
      await tester.pump(const Duration(seconds: 3));
      expect(hybridAi.checkCount, checks, reason: 'polling stops once the download is done');
    });
  });
}
