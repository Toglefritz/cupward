import 'dart:async';
import 'dart:convert';

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
  _streamingTests();
  _structuredTests();

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

/// Verifies how [PigeonFirebaseHybridAi] prepares a streamed request, opens its channel, and translates errors.
void _streamingTests() {
  group('generateTextStream', () {
    /// The host stores the request and returns a token, and the event channel must be opened with that token, because
    /// the token is the only link between the channel and the prepared request.
    test('prepares the request and streams the channel named by the token', () async {
      // Arrange
      final _FakeHostApi api = _FakeHostApi(token: 'token-1');
      String? openedToken;
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: api,
        textStream: (String token) {
          openedToken = token;

          return Stream<TextGenerationChunk>.fromIterable(<TextGenerationChunk>[
            TextGenerationChunk(text: 'a', source: InferenceSource.onDevice),
            TextGenerationChunk(text: 'b', source: InferenceSource.inCloud),
          ]);
        },
      );

      // Act
      final List<TextGenerationChunk> chunks = await platform
          .generateTextStream(
            'Hi',
            mode: InferenceMode.preferInCloud,
            category: OnDeviceModelCategory.preview,
            cloudModel: 'gemini-test',
          )
          .toList();

      // Assert
      expect(openedToken, 'token-1');
      expect(chunks.map((TextGenerationChunk chunk) => chunk.text).toList(), <String>['a', 'b']);
      expect(chunks.last.source, InferenceSource.inCloud);
      expect(api.lastPrompt, 'Hi');
      expect(api.lastMode, InferenceMode.preferInCloud);
      expect(api.lastCategory, OnDeviceModelCategory.preview);
      expect(api.lastCloudModel, 'gemini-test');
    });

    /// A request that nobody listens to must not leave anything registered on the host, so the host call waits for the
    /// listener.
    test('does not call the host until the stream is listened to', () async {
      // Arrange
      final _FakeHostApi api = _FakeHostApi(token: 'token-1');
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: api,
        textStream: (String token) => const Stream<TextGenerationChunk>.empty(),
      );

      // Act
      final Stream<TextGenerationChunk> stream = platform.generateTextStream('Hi');

      // Assert
      expect(api.lastPrompt, isNull);

      await stream.toList();

      expect(api.lastPrompt, 'Hi');
    });

    /// A missing Firebase app is found when the request is prepared, which is before any chunk.
    test('emits FirebaseNotInitializedException when preparing fails', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(error: PlatformException(code: 'firebase-not-initialized')),
        textStream: (String token) => const Stream<TextGenerationChunk>.empty(),
      );

      // Act and assert
      expect(platform.generateTextStream('Hi').toList(), throwsA(isA<FirebaseNotInitializedException>()));
    });

    /// Errors that arrive on the channel are translated, so callers see the same types as for a single response.
    test('translates channel errors', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(token: 'token-1'),
        textStream: (String token) => Stream<TextGenerationChunk>.error(
          PlatformException(code: 'on-device-unavailable', message: 'No model'),
        ),
      );

      // Act and assert
      expect(platform.generateTextStream('Hi').toList(), throwsA(isA<OnDeviceModelUnavailableException>()));
    });

    /// Cancelling must reach the channel subscription, because that is what stops the generation on the host.
    test('cancels the channel subscription when the caller cancels', () async {
      // Arrange
      bool wasCancelled = false;
      final StreamController<TextGenerationChunk> channel = StreamController<TextGenerationChunk>(
        onCancel: () => wasCancelled = true,
      );
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(token: 'token-1'),
        textStream: (String token) => channel.stream,
      );
      final Completer<void> gotFirstChunk = Completer<void>();

      // Act
      final StreamSubscription<TextGenerationChunk> subscription = platform.generateTextStream('Hi').listen((
        TextGenerationChunk chunk,
      ) {
        gotFirstChunk.complete();
      });
      await Future<void>.delayed(Duration.zero);
      channel.add(TextGenerationChunk(text: 'a', source: InferenceSource.onDevice));
      await gotFirstChunk.future;
      await subscription.cancel();

      // Assert
      expect(wasCancelled, isTrue);
    });
  });
}

/// Verifies how [PigeonFirebaseHybridAi] sends a schema to the host and builds the result from the host's text.
void _structuredTests() {
  group('generateStructured', () {
    /// The schema used by these tests.
    const ResponseSchema schema = ResponseSchema.object(
      properties: <String, ResponseSchema>{'fact': ResponseSchema.string()},
    );

    /// The host needs the plain prompt and the schema for requests it can constrain, and a prompt that describes the
    /// schema for the ones it cannot.
    test('sends the prompt, the instructed prompt, and the schema to the host', () async {
      // Arrange
      final _FakeHostApi api = _FakeHostApi(
        structured: StructuredTextResponse(
          text: '{"fact": "x"}',
          source: InferenceSource.inCloud,
          isSchemaEnforced: true,
        ),
      );
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(api: api);

      // Act
      await platform.generateStructured('Tell me a fact.', schema: schema, mode: InferenceMode.onlyInCloud);

      // Assert
      expect(api.lastPrompt, 'Tell me a fact.');
      expect(api.lastInstructedPrompt, startsWith('Tell me a fact.'));
      expect(api.lastInstructedPrompt, contains('JSON Schema'));
      expect(jsonDecode(api.lastSchemaJson!), schema.toJson());
      expect(api.lastMode, InferenceMode.onlyInCloud);
    });

    /// The host reports whether it enforced the schema, and the result must carry that value with the validation.
    test('decodes and validates the host text and keeps the enforcement flag', () async {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(
          structured: StructuredTextResponse(
            text: '```json\n{"fact": "Otters hold hands."}\n```',
            source: InferenceSource.onDevice,
            isSchemaEnforced: false,
          ),
        ),
      );

      // Act
      final StructuredGenerationResult result = await platform.generateStructured('Fact', schema: schema);

      // Assert
      expect(result.isSchemaEnforced, isFalse);
      expect(result.conformsToSchema, isTrue);
      expect(result.data, <String, Object?>{'fact': 'Otters hold hands.'});
      expect(result.source, InferenceSource.onDevice);
    });

    /// Host failures use the same exception types as plain text generation.
    test('translates host errors', () {
      // Arrange
      final PigeonFirebaseHybridAi platform = PigeonFirebaseHybridAi(
        api: _FakeHostApi(error: PlatformException(code: 'on-device-unavailable')),
      );

      // Act and assert
      expect(platform.generateStructured('Fact', schema: schema), throwsA(isA<OnDeviceModelUnavailableException>()));
    });
  });
}

/// A host API that returns a preset [status] or throws a preset [error] without using a message channel.
class _FakeHostApi extends FirebaseHybridAiHostApi {
  /// Creates a fake that returns [status], or throws [error] when one is given.
  new({this.status, this.error, this.generation, this.token = 'token', this.structured});

  /// The value returned by [generateStructured], when no [error] is set.
  final StructuredTextResponse? structured;

  /// The instructed prompt and the schema of the most recent [generateStructured] call.
  String? lastInstructedPrompt;
  String? lastSchemaJson;

  /// The token returned by [prepareTextStream], when no [error] is set.
  final String token;

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

  @override
  Future<String> prepareTextStream(
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

    return token;
  }

  @override
  Future<StructuredTextResponse> generateStructured(
    String prompt,
    String instructedPrompt,
    String schemaJson,
    InferenceMode mode,
    OnDeviceModelCategory category,
    String cloudModelName,
  ) async {
    lastPrompt = prompt;
    lastInstructedPrompt = instructedPrompt;
    lastSchemaJson = schemaJson;
    lastMode = mode;
    lastCategory = category;
    lastCloudModel = cloudModelName;

    if (error != null) {
      throw error!;
    }

    return structured!;
  }
}
