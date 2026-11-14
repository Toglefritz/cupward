@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai_web.dart';
import 'package:firebase_hybrid_ai/src/web/web_generation_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the web implementation against a stand-in for Chrome's `LanguageModel` global.
///
/// These tests run in a real browser, so the `dart:js_interop` calls are exercised. The browser's own model is
/// replaced by a stub, which keeps the results independent of whether the machine has Gemini Nano installed.
void main() {
  /// The name of the global that Chrome uses to expose the Prompt API.
  const String globalName = 'LanguageModel';

  /// The browser's real `LanguageModel`, if it has one, kept so it can be restored after each test.
  JSAny? realLanguageModel;

  /// Removes the browser's real `LanguageModel` so that each test controls exactly what the plugin sees.
  setUp(() {
    realLanguageModel = globalContext[globalName];
    globalContext.delete(globalName.toJS);
  });

  /// Removes any stub and restores the real `LanguageModel` so one test cannot affect the next.
  tearDown(() {
    globalContext.delete(globalName.toJS);

    if (realLanguageModel != null) {
      globalContext[globalName] = realLanguageModel;
    }
  });

  group('FirebaseHybridAiWeb.checkOnDeviceStatus', () {
    /// A browser without the Prompt API has no global, which must read as unavailable rather than as an error.
    test('reports unavailable when the browser has no LanguageModel global', () async {
      // Act
      final OnDeviceModelStatus status = await FirebaseHybridAiWeb().checkOnDeviceStatus();

      // Assert
      expect(status.availability, OnDeviceModelAvailability.unavailable);
      expect(status.modelName, isNull);
    });

    /// The string resolved by the browser's promise must reach the caller as the matching enum value.
    test('reports the availability resolved by LanguageModel.availability()', () async {
      // Arrange
      final JSObject languageModel = JSObject();
      languageModel['availability'] = ((JSAny? options) => Future<JSAny?>.value('downloadable'.toJS).toJS).toJS;
      globalContext[globalName] = languageModel;

      // Act
      final OnDeviceModelStatus status = await FirebaseHybridAiWeb().checkOnDeviceStatus();

      // Assert
      expect(status.availability, OnDeviceModelAvailability.downloadable);
    });

    /// Chrome requires matching options on availability() and prompt(), so the declared modalities are part of the
    /// contract with the browser.
    test('declares English text input and output', () async {
      // Arrange
      JSAny? receivedOptions;
      final JSObject languageModel = JSObject();
      languageModel['availability'] = ((JSAny? options) {
        receivedOptions = options;
        return Future<JSAny?>.value('available'.toJS).toJS;
      }).toJS;
      globalContext[globalName] = languageModel;

      // Act
      await FirebaseHybridAiWeb().checkOnDeviceStatus();

      // Assert
      final Object? options = receivedOptions.dartify();
      expect(options, isA<Map<Object?, Object?>>());
      final Map<Object?, Object?> optionsMap = options! as Map<Object?, Object?>;
      expect(optionsMap['expectedInputs'], <Object?>[
        <Object?, Object?>{
          'type': 'text',
          'languages': <Object?>['en'],
        },
      ]);
      expect(optionsMap['expectedOutputs'], <Object?>[
        <Object?, Object?>{
          'type': 'text',
          'languages': <Object?>['en'],
        },
      ]);
    });

    /// A rejected promise must surface as the plugin's own exception so callers have one type to catch.
    test('throws FirebaseHybridAiException when the browser rejects the call', () async {
      // Arrange
      final JSObject languageModel = JSObject();
      languageModel['availability'] = ((JSAny? options) => Future<JSAny?>.error('denied').toJS).toJS;
      globalContext[globalName] = languageModel;

      // Act and assert
      expect(FirebaseHybridAiWeb().checkOnDeviceStatus(), throwsA(isA<FirebaseHybridAiException>()));
    });
  });

  group('FirebaseHybridAiWeb.downloadOnDeviceModel', () {
    /// A browser without the Prompt API has nothing to download, which must read as unsupported.
    test('throws HybridAiNotSupportedException when the browser has no LanguageModel global', () {
      expect(FirebaseHybridAiWeb().downloadOnDeviceModel().toList(), throwsA(isA<HybridAiNotSupportedException>()));
    });

    /// The monitor's downloadprogress events must become progress fractions, and the session that Chrome returns
    /// must be destroyed, because only the downloaded model is wanted.
    test('streams the downloadprogress events and destroys the session', () async {
      // Arrange
      globalContext.callMethod<JSAny?>(
        'eval'.toJS,
        '''
        window.__sessionDestroyed = false;
        window.LanguageModel = {
          availability: async () => 'downloadable',
          create: async (options) => {
            const target = new EventTarget();
            options.monitor(target);
            for (const loaded of [0.25, 0.5]) {
              const event = new Event('downloadprogress');
              event.loaded = loaded;
              target.dispatchEvent(event);
            }
            return { destroy() { window.__sessionDestroyed = true; } };
          },
        };
        '''
            .toJS,
      );

      // Act
      final List<double> fractions = await FirebaseHybridAiWeb()
          .downloadOnDeviceModel()
          .map((OnDeviceModelDownloadProgress progress) => progress.fraction)
          .toList();

      // Assert
      expect(fractions, <double>[0.25, 0.5, 1]);
      expect(globalContext['__sessionDestroyed'], isA<JSBoolean>().having((JSBoolean v) => v.toDart, 'value', true));
    });

    /// A rejected create() must surface as the plugin's exception so callers have one type to catch.
    test('throws FirebaseHybridAiException when Chrome rejects create()', () {
      // Arrange
      globalContext.callMethod<JSAny?>(
        'eval'.toJS,
        '''
        window.LanguageModel = {
          availability: async () => 'downloadable',
          create: async () => { throw new Error('NotAllowedError'); },
        };
        '''
            .toJS,
      );

      // Act and assert
      expect(FirebaseHybridAiWeb().downloadOnDeviceModel().toList(), throwsA(isA<FirebaseHybridAiException>()));
    });
  });

  group('FirebaseHybridAiWeb.generateText', () {
    /// A recorded call to the fake generator.
    late List<Map<String, Object?>> calls;

    /// Creates the web implementation with a browser availability string and a canned SDK response.
    FirebaseHybridAiWeb build({
      required String? availability,
      String source = 'IN_CLOUD',
      Exception? error,
      bool availabilityThrows = false,
    }) {
      calls = <Map<String, Object?>>[];

      return FirebaseHybridAiWeb(
        availabilityReader: () async {
          if (availabilityThrows) {
            throw StateError('rejected');
          }

          return availability;
        },
        generator:
            ({
              required String prompt,
              required InferenceMode mode,
              required String cloudModel,
              required bool initializeDeviceModel,
            }) async {
              calls.add(<String, Object?>{
                'prompt': prompt,
                'mode': mode,
                'cloudModel': cloudModel,
                'initializeDeviceModel': initializeDeviceModel,
              });

              if (error != null) {
                throw error;
              }

              return WebGenerationResponse(text: 'Reply', source: source);
            },
      );
    }

    /// The SDK's source string must become the matching enum value, so callers can tell the device from the cloud.
    test('reports an on-device response as on-device', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available', source: 'ON_DEVICE');

      // Act
      final TextGenerationResult result = await web.generateText('Hi');

      // Assert
      expect(result.text, 'Reply');
      expect(result.source, InferenceSource.onDevice);
    });

    /// A cloud response must never be reported as local, because the source tells users where their prompt went.
    test('reports a cloud response as in-cloud', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available');

      // Act
      final TextGenerationResult result = await web.generateText('Hi');

      // Assert
      expect(result.source, InferenceSource.inCloud);
    });

    /// An installed model is initialized, which the SDK requires before on-device inference.
    test('initializes the device model when it is installed', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available');

      // Act
      await web.generateText('Hi');

      // Assert
      expect(calls.single['initializeDeviceModel'], isTrue);
    });

    /// A model that is not installed must not be initialized, because that starts a download, and the fallback modes
    /// should answer from the cloud instead of waiting for one.
    test('does not initialize a model that is not installed in a fallback mode', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'downloadable');

      // Act
      await web.generateText('Hi');

      // Assert
      expect(calls.single['initializeDeviceModel'], isFalse);
    });

    /// A cloud-only request has no use for the on-device model, so it must not touch it.
    test('does not initialize the device model for cloud-only requests', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available');

      // Act
      await web.generateText('Hi', mode: InferenceMode.onlyInCloud);

      // Assert
      expect(calls.single['initializeDeviceModel'], isFalse);
      expect(calls.single['mode'], InferenceMode.onlyInCloud);
    });

    /// A request that must run on the device fails fast with a specific type, and never reaches the SDK.
    test('throws OnDeviceModelUnavailableException for an only-on-device request without the model', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'downloadable');

      // Act and assert
      await expectLater(
        web.generateText('Hi', mode: InferenceMode.onlyOnDevice),
        throwsA(isA<OnDeviceModelUnavailableException>()),
      );
      expect(calls, isEmpty);
    });

    /// A browser without the Prompt API cannot serve an only-on-device request either.
    test('throws OnDeviceModelUnavailableException when the browser has no Prompt API', () {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: null);

      // Act and assert
      expect(
        web.generateText('Hi', mode: InferenceMode.onlyOnDevice),
        throwsA(isA<OnDeviceModelUnavailableException>()),
      );
    });

    /// A failing availability check must not block a request that the cloud can still serve.
    test('still sends a fallback-mode request when the availability check fails', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: null, availabilityThrows: true);

      // Act
      final TextGenerationResult result = await web.generateText('Hi');

      // Assert
      expect(result.source, InferenceSource.inCloud);
      expect(calls.single['initializeDeviceModel'], isFalse);
    });

    /// The prompt, mode, and cloud model must reach the SDK as given.
    test('passes the prompt, mode, and cloud model to the SDK', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available');

      // Act
      await web.generateText('Question', mode: InferenceMode.preferInCloud, cloudModel: 'gemini-test');

      // Assert
      expect(calls.single['prompt'], 'Question');
      expect(calls.single['mode'], InferenceMode.preferInCloud);
      expect(calls.single['cloudModel'], 'gemini-test');
    });

    /// SDK failures must surface as the plugin's exception with the SDK's text kept for diagnosis.
    test('wraps an SDK failure in FirebaseHybridAiException', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available', error: Exception('quota'));

      // Act
      FirebaseHybridAiException? caught;
      try {
        await web.generateText('Hi');
      } on FirebaseHybridAiException catch (exception) {
        caught = exception;
      }

      // Assert
      expect(caught?.code, 'generation-failed');
      expect(caught?.details, contains('quota'));
    });

    /// A missing Firebase app is reported by the SDK layer and must pass through with its own type.
    test('does not rewrap FirebaseNotInitializedException', () {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available', error: const FirebaseNotInitializedException());

      // Act and assert
      expect(web.generateText('Hi'), throwsA(isA<FirebaseNotInitializedException>()));
    });
  });

  group('FirebaseHybridAiWeb.generateTextStream', () {
    /// The arguments of each call to the fake streamer.
    late List<Map<String, Object?>> calls;

    /// Creates the web implementation with a browser availability string and a stream of SDK chunks.
    FirebaseHybridAiWeb build({
      required String? availability,
      List<WebGenerationResponse> chunks = const <WebGenerationResponse>[
        WebGenerationResponse(text: 'Hel', source: 'ON_DEVICE'),
        WebGenerationResponse(text: 'lo', source: 'ON_DEVICE'),
      ],
      Exception? error,
    }) {
      calls = <Map<String, Object?>>[];

      return FirebaseHybridAiWeb(
        availabilityReader: () async => availability,
        streamer:
            ({
              required String prompt,
              required InferenceMode mode,
              required String cloudModel,
              required bool initializeDeviceModel,
            }) async* {
              calls.add(<String, Object?>{
                'prompt': prompt,
                'mode': mode,
                'cloudModel': cloudModel,
                'initializeDeviceModel': initializeDeviceModel,
              });

              yield* Stream<WebGenerationResponse>.fromIterable(chunks);

              if (error != null) {
                throw error;
              }
            },
      );
    }

    /// Each chunk keeps its own text and source, so that the caller can rebuild the response and show its origin.
    test('emits each chunk with its source', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(
        availability: 'available',
        chunks: const <WebGenerationResponse>[
          WebGenerationResponse(text: 'Hel', source: 'ON_DEVICE'),
          WebGenerationResponse(text: 'lo', source: 'IN_CLOUD'),
        ],
      );

      // Act
      final List<TextGenerationChunk> chunks = await web.generateTextStream('Hi').toList();

      // Assert
      expect(chunks.map((TextGenerationChunk chunk) => chunk.text).join(), 'Hello');
      expect(chunks.first.source, InferenceSource.onDevice);
      expect(chunks.last.source, InferenceSource.inCloud);
    });

    /// The prompt, mode, and cloud model must reach the SDK as given.
    test('passes the prompt, mode, and cloud model to the SDK', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available');

      // Act
      await web.generateTextStream('Question', mode: InferenceMode.preferInCloud, cloudModel: 'gemini-test').toList();

      // Assert
      expect(calls.single['prompt'], 'Question');
      expect(calls.single['mode'], InferenceMode.preferInCloud);
      expect(calls.single['cloudModel'], 'gemini-test');
    });

    /// An installed model is initialized, and one that is not installed is left alone, as for a single response.
    test('initializes the device model only when it is installed', () async {
      // Act
      await build(availability: 'available').generateTextStream('Hi').toList();
      final bool installedFlag = calls.single['initializeDeviceModel']! as bool;

      await build(availability: 'downloadable').generateTextStream('Hi').toList();
      final bool downloadableFlag = calls.single['initializeDeviceModel']! as bool;

      // Assert
      expect(installedFlag, isTrue);
      expect(downloadableFlag, isFalse);
    });

    /// A request that must run on the device fails fast with a specific type and never reaches the SDK.
    test('throws OnDeviceModelUnavailableException for an only-on-device request without the model', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'downloadable');

      // Act and assert
      await expectLater(
        web.generateTextStream('Hi', mode: InferenceMode.onlyOnDevice).toList(),
        throwsA(isA<OnDeviceModelUnavailableException>()),
      );
      expect(calls, isEmpty);
    });

    /// SDK failures must surface as the plugin's exception, with chunks that arrived before it still delivered.
    test('wraps an SDK failure in FirebaseHybridAiException after delivering earlier chunks', () async {
      // Arrange
      final FirebaseHybridAiWeb web = build(availability: 'available', error: Exception('blocked'));
      final List<String> received = <String>[];
      FirebaseHybridAiException? caught;

      // Act
      try {
        await for (final TextGenerationChunk chunk in web.generateTextStream('Hi')) {
          received.add(chunk.text);
        }
      } on FirebaseHybridAiException catch (exception) {
        caught = exception;
      }

      // Assert
      expect(received, <String>['Hel', 'lo']);
      expect(caught?.code, 'generation-failed');
      expect(caught?.details, contains('blocked'));
    });
  });
}
