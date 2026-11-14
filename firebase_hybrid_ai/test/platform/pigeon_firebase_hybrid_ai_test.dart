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

  _downloadTests();
  _generationTests();

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

    /// The category is the only way the caller chooses between Gemini Nano releases, so it must reach the host.
    test('passes the category to the host', () async {
      // Arrange
      final _FakeHostApi api = _FakeHostApi(
        status: OnDeviceModelStatus(availability: OnDeviceModelAvailability.available),
      );
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(api: api);

      // Act
      await platform.checkOnDeviceStatus(category: OnDeviceModelCategory.previewFast);

      // Assert
      expect(api.lastCategory, OnDeviceModelCategory.previewFast);
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

/// Verifies how [PigeonFirebaseHybridAi] relays download progress and translates stream errors.
///
/// The generated event stream is replaced with a controllable stream.
void _downloadTests() {
  group('downloadOnDeviceModel', () {
    /// Progress from the native side must pass through unchanged and in order.
    test('relays progress events', () async {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        downloadStream: (OnDeviceModelCategory category) =>
            Stream<OnDeviceModelDownloadProgress>.fromIterable(<OnDeviceModelDownloadProgress>[
              OnDeviceModelDownloadProgress(fraction: 0),
              OnDeviceModelDownloadProgress(fraction: 1),
            ]),
      );

      // Act
      final List<double> fractions = await platform
          .downloadOnDeviceModel()
          .map((OnDeviceModelDownloadProgress progress) => progress.fraction)
          .toList();

      // Assert
      expect(fractions, <double>[0, 1]);
    });

    /// Event channels take no parameters, so the category is the channel's instance name. Android registers its
    /// channels under the same names, so a mismatch would listen to a channel that no handler serves.
    test('opens the download stream for the chosen category', () async {
      // Arrange
      OnDeviceModelCategory? requested;
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        downloadStream: (OnDeviceModelCategory category) {
          requested = category;
          return const Stream<OnDeviceModelDownloadProgress>.empty();
        },
      );

      // Act
      await platform.downloadOnDeviceModel(category: OnDeviceModelCategory.preview).toList();

      // Assert
      expect(requested, OnDeviceModelCategory.preview);
      expect(OnDeviceModelCategory.values.map((OnDeviceModelCategory category) => category.name), <String>[
        'stable',
        'preview',
        'previewFast',
      ]);
    });

    /// A platform error on the stream must become the plugin's exception with the original code.
    test('translates platform errors into FirebaseHybridAiException', () async {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        downloadStream: (OnDeviceModelCategory category) => Stream<OnDeviceModelDownloadProgress>.error(
          PlatformException(code: 'download-failed', message: 'No space left.'),
        ),
      );

      // Act
      Object? caught;
      try {
        await platform.downloadOnDeviceModel().toList();
      } on Object catch (error) {
        caught = error;
      }

      // Assert
      expect(caught, isA<FirebaseHybridAiException>());
      expect((caught! as FirebaseHybridAiException).code, 'download-failed');
    });

    /// Platforms that cannot download report the unimplemented code, which must read as unsupported.
    test('translates the unimplemented code into HybridAiNotSupportedException', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        downloadStream: (OnDeviceModelCategory category) =>
            Stream<OnDeviceModelDownloadProgress>.error(PlatformException(code: 'unimplemented')),
      );

      // Act and assert
      expect(platform.downloadOnDeviceModel().toList(), throwsA(isA<HybridAiNotSupportedException>()));
    });
  });
}

/// Verifies how [PigeonFirebaseHybridAi] sends prompts to the host and translates the host's errors.
void _generationTests() {
  group('generateText', () {
    /// The host receives every option, and its result reaches the caller unchanged.
    test('passes the prompt and options to the host and returns its result', () async {
      // Arrange
      final _FakeHostApi api = _FakeHostApi(
        generation: TextGenerationResult(text: 'Nine', source: InferenceSource.onDevice),
      );
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(api: api);

      // Act
      final TextGenerationResult result = await platform.generateText(
        'How many planets?',
        mode: InferenceMode.onlyOnDevice,
        category: OnDeviceModelCategory.preview,
        cloudModel: 'gemini-test',
      );

      // Assert
      expect(result.text, 'Nine');
      expect(result.source, InferenceSource.onDevice);
      expect(api.lastPrompt, 'How many planets?');
      expect(api.lastMode, InferenceMode.onlyOnDevice);
      expect(api.lastCategory, OnDeviceModelCategory.preview);
      expect(api.lastCloudModel, 'gemini-test');
    });

    /// An only-on-device request that the device cannot serve is a condition callers act on, so it gets its own type.
    test('throws OnDeviceModelUnavailableException for the on-device-unavailable code', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(
          error: PlatformException(code: 'on-device-unavailable', message: 'No model'),
        ),
      );

      // Act and assert
      expect(platform.generateText('Hi'), throwsA(isA<OnDeviceModelUnavailableException>()));
    });

    /// A missing Firebase app is reported with the same type as for the other operations.
    test('throws FirebaseNotInitializedException for the firebase-not-initialized code', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(error: PlatformException(code: 'firebase-not-initialized')),
      );

      // Act and assert
      expect(platform.generateText('Hi'), throwsA(isA<FirebaseNotInitializedException>()));
    });

    /// Other failures keep the host's code so callers and logs can tell them apart.
    test('keeps the platform code for other failures', () async {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(
          error: PlatformException(code: 'generation-failed', message: 'Quota exceeded'),
        ),
      );

      // Act
      FirebaseHybridAiException? caught;
      try {
        await platform.generateText('Hi');
      } on FirebaseHybridAiException catch (exception) {
        caught = exception;
      }

      // Assert
      expect(caught?.code, 'generation-failed');
      expect(caught?.message, 'Quota exceeded');
    });
  });
}

/// A host API that returns a preset [status] or throws a preset [error] without using a message channel.
class _FakeHostApi extends FirebaseHybridAiHostApi {
  /// Creates a fake that returns [status], or throws [error] when one is given.
  new({this.status, this.error, this.generation});

  /// The value returned by [generateText], when no [error] is set.
  final TextGenerationResult? generation;

  /// The arguments of the most recent [generateText] call.
  String? lastPrompt;
  InferenceMode? lastMode;
  String? lastCloudModel;

  /// The category received by the most recent call.
  OnDeviceModelCategory? lastCategory;

  /// The value returned by [checkOnDeviceStatus], when no [error] is set.
  final OnDeviceModelStatus? status;

  /// The exception thrown by [checkOnDeviceStatus], if any.
  final PlatformException? error;

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus(OnDeviceModelCategory category) async {
    lastCategory = category;

    if (error != null) {
      throw error!;
    }

    return status!;
  }

  @override
  Future<TextGenerationResult> generateText(
    String prompt,
    InferenceMode mode,
    OnDeviceModelCategory category,
    String cloudModelName,
  ) async {
    lastPrompt = prompt;
    lastMode = mode;
    lastCategory = category;
    lastCloudModel = cloudModelName;

    if (error != null) {
      throw error!;
    }

    return generation!;
  }
}
