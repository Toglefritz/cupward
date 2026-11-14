@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/src/web/firebase_ai_js.dart';
import 'package:firebase_hybrid_ai/src/web/web_generation_response.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the calls that [generateWithFirebaseAiJs] makes against stand-ins for the Firebase JavaScript SDK
/// modules that `firebase_core_web` loads.
///
/// The stand-ins record what the code passes to them, so the tests check the setup order and the values handed to
/// the SDK without needing a Firebase project or a network connection.
void main() {
  /// Installs `firebase_core` and `firebase_ai` stand-ins that record their calls in `window.__calls`.
  ///
  /// [generateBody] is the JavaScript body of `generateContent`, which receives the prompt as `prompt`.
  ///
  /// [streamBody] is the JavaScript body of an async generator that `generateContentStream` returns as its `stream`.
  /// The default yields two chunks and an empty one. The stand-in sets `window.__streamClosed` when the generator
  /// is closed, which happens when it finishes or when `return` is called on it.
  void installFirebase({
    String generateBody = "return { response: { text: () => 'The answer', inferenceSource: 'ON_DEVICE' } };",
    String streamBody = '''
      try {
        yield { text: () => 'Hel', inferenceSource: 'ON_DEVICE' };
        yield { text: () => '', inferenceSource: 'ON_DEVICE' };
        yield { text: () => 'lo', inferenceSource: 'ON_DEVICE' };
      } finally {
        window.__streamClosed = true;
      }
    ''',
  }) {
    globalContext.callMethod<JSAny?>(
      'eval'.toJS,
      '''
      window.__calls = [];
      window.firebase_core = { getApp: () => { window.__calls.push('getApp'); return { name: '[DEFAULT]' }; } };
      window.firebase_ai = {
        GoogleAIBackend: class GoogleAIBackend {},
        InferenceMode: {
          PREFER_ON_DEVICE: 'prefer_on_device',
          ONLY_ON_DEVICE: 'only_on_device',
          PREFER_IN_CLOUD: 'prefer_in_cloud',
          ONLY_IN_CLOUD: 'only_in_cloud',
        },
        getAI: (app, options) => {
          window.__calls.push('getAI:' + options.backend.constructor.name);
          return { app };
        },
        getGenerativeModel: (ai, params) => {
          window.__calls.push('getGenerativeModel:' + params.mode + ':' + params.inCloudParams.model);
          return {
            initializeDeviceModel: async () => { window.__calls.push('initializeDeviceModel'); },
            generateContent: async (prompt) => { window.__calls.push('generateContent:' + prompt); $generateBody },
            generateContentStream: async (prompt) => {
              window.__calls.push('generateContentStream:' + prompt);
              window.__streamClosed = false;
              return { stream: (async function* () { $streamBody })(), response: Promise.resolve({}) };
            },
          };
        },
      };
      '''
          .toJS,
    );
  }

  /// The calls recorded by the stand-ins, in order.
  List<String> recordedCalls() {
    final JSArray<JSString> calls = globalContext['__calls']! as JSArray<JSString>;

    return calls.toDart.map((JSString call) => call.toDart).toList();
  }

  tearDown(() {
    globalContext
      ..delete('firebase_core'.toJS)
      ..delete('firebase_ai'.toJS)
      ..delete('__calls'.toJS)
      ..delete('__streamClosed'.toJS);
  });

  group('generateWithFirebaseAiJs', () {
    /// The SDK documents this order: app, AI service with the Gemini Developer API backend, model with a mode and
    /// cloud model, then the request. The response's text and source must come back.
    test('sets up the model in the documented order and returns the response', () async {
      // Arrange
      installFirebase();

      // Act
      final WebGenerationResponse response = await generateWithFirebaseAiJs(
        prompt: 'Hello',
        mode: InferenceMode.preferOnDevice,
        cloudModel: 'gemini-test',
        initializeDeviceModel: false,
      );

      // Assert
      expect(recordedCalls(), <String>[
        'getApp',
        'getAI:GoogleAIBackend',
        'getGenerativeModel:prefer_on_device:gemini-test',
        'generateContent:Hello',
      ]);
      expect(response.text, 'The answer');
      expect(response.source, 'ON_DEVICE');
    });

    /// Each mode must reach the SDK under its own name, because the mode decides where the prompt is processed.
    test('maps every inference mode to the SDK mode', () async {
      // Arrange
      const Map<InferenceMode, String> expected = <InferenceMode, String>{
        InferenceMode.preferOnDevice: 'prefer_on_device',
        InferenceMode.onlyOnDevice: 'only_on_device',
        InferenceMode.preferInCloud: 'prefer_in_cloud',
        InferenceMode.onlyInCloud: 'only_in_cloud',
      };

      for (final MapEntry<InferenceMode, String> entry in expected.entries) {
        installFirebase();

        // Act
        await generateWithFirebaseAiJs(
          prompt: 'Hi',
          mode: entry.key,
          cloudModel: 'm',
          initializeDeviceModel: false,
        );

        // Assert
        expect(recordedCalls(), contains('getGenerativeModel:${entry.value}:m'));
      }
    });

    /// The SDK requires this call before on-device inference, and it must finish before the request is sent.
    test('initializes the device model before generating when asked to', () async {
      // Arrange
      installFirebase();

      // Act
      await generateWithFirebaseAiJs(
        prompt: 'Hi',
        mode: InferenceMode.onlyOnDevice,
        cloudModel: 'm',
        initializeDeviceModel: true,
      );

      // Assert
      final List<String> calls = recordedCalls();
      expect(calls.indexOf('initializeDeviceModel'), isNonNegative);
      expect(calls.indexOf('initializeDeviceModel'), lessThan(calls.indexOf('generateContent:Hi')));
    });

    /// Without the request to initialize, the call must not run, because it can start a large download.
    test('does not initialize the device model when not asked to', () async {
      // Arrange
      installFirebase();

      // Act
      await generateWithFirebaseAiJs(
        prompt: 'Hi',
        mode: InferenceMode.preferOnDevice,
        cloudModel: 'm',
        initializeDeviceModel: false,
      );

      // Assert
      expect(recordedCalls(), isNot(contains('initializeDeviceModel')));
    });

    /// Missing Firebase scripts mean Firebase was never initialized, which callers can fix, so it gets its own type.
    test('throws FirebaseNotInitializedException when the Firebase scripts are not loaded', () {
      // Act and assert
      expect(
        generateWithFirebaseAiJs(
          prompt: 'Hi',
          mode: InferenceMode.onlyInCloud,
          cloudModel: 'm',
          initializeDeviceModel: false,
        ),
        throwsA(isA<FirebaseNotInitializedException>()),
      );
    });

    /// `getApp` throws when no default app exists, which is the same condition and must read the same way.
    test('throws FirebaseNotInitializedException when there is no default app', () {
      // Arrange
      installFirebase();
      globalContext.callMethod<JSAny?>(
        'eval'.toJS,
        "window.firebase_core = { getApp: () => { throw new Error('No Firebase App'); } };".toJS,
      );

      // Act and assert
      expect(
        generateWithFirebaseAiJs(
          prompt: 'Hi',
          mode: InferenceMode.onlyInCloud,
          cloudModel: 'm',
          initializeDeviceModel: false,
        ),
        throwsA(isA<FirebaseNotInitializedException>()),
      );
    });
  });

  group('streamWithFirebaseAiJs', () {
    /// Chunks must arrive in order with their sources. A chunk with no text, such as the usage-only chunk at the end
    /// of a stream, carries nothing for the caller and must be skipped.
    test('emits the text chunks in order and skips empty ones', () async {
      // Arrange
      installFirebase();

      // Act
      final List<WebGenerationResponse> chunks = await streamWithFirebaseAiJs(
        prompt: 'Hello',
        mode: InferenceMode.preferOnDevice,
        cloudModel: 'gemini-test',
        initializeDeviceModel: false,
      ).toList();

      // Assert
      expect(chunks.map((WebGenerationResponse chunk) => chunk.text).toList(), <String>['Hel', 'lo']);
      expect(chunks.every((WebGenerationResponse chunk) => chunk.source == 'ON_DEVICE'), isTrue);
      expect(recordedCalls(), contains('generateContentStream:Hello'));
    });

    /// The stream uses the same model setup as a single response, including the mode and the cloud model.
    test('sets up the model the same way as a single response', () async {
      // Arrange
      installFirebase();

      // Act
      await streamWithFirebaseAiJs(
        prompt: 'Hello',
        mode: InferenceMode.preferInCloud,
        cloudModel: 'gemini-test',
        initializeDeviceModel: true,
      ).toList();

      // Assert
      final List<String> calls = recordedCalls();
      expect(calls.take(3), <String>[
        'getApp',
        'getAI:GoogleAIBackend',
        'getGenerativeModel:prefer_in_cloud:gemini-test',
      ]);
      expect(calls.indexOf('initializeDeviceModel'), lessThan(calls.indexOf('generateContentStream:Hello')));
    });

    /// Cancelling must stop the SDK's generator, because that is what stops the generation and releases the model.
    test('closes the SDK stream when the subscription is cancelled', () async {
      // Arrange
      installFirebase();
      final Completer<void> gotFirstChunk = Completer<void>();

      // Act
      final StreamSubscription<WebGenerationResponse> subscription =
          streamWithFirebaseAiJs(
            prompt: 'Hello',
            mode: InferenceMode.onlyInCloud,
            cloudModel: 'gemini-test',
            initializeDeviceModel: false,
          ).listen((WebGenerationResponse chunk) {
            if (!gotFirstChunk.isCompleted) {
              gotFirstChunk.complete();
            }
          });
      await gotFirstChunk.future;
      await subscription.cancel();

      // Assert
      expect((globalContext['__streamClosed']! as JSBoolean).toDart, isTrue);
    });

    /// A failure while reading the stream, such as a blocked response, must reach the caller.
    test('emits an error thrown by the SDK stream', () {
      // Arrange
      installFirebase(
        streamBody: '''
          yield { text: () => 'Hel', inferenceSource: 'ON_DEVICE' };
          throw new Error('Response blocked');
        ''',
      );

      // Act and assert
      expect(
        streamWithFirebaseAiJs(
          prompt: 'Hello',
          mode: InferenceMode.onlyInCloud,
          cloudModel: 'gemini-test',
          initializeDeviceModel: false,
        ).toList(),
        throwsA(anything),
      );
    });

    /// Missing Firebase scripts mean that Firebase was never initialized, which callers can fix.
    test('throws FirebaseNotInitializedException when the Firebase scripts are not loaded', () {
      // Act and assert
      expect(
        streamWithFirebaseAiJs(
          prompt: 'Hi',
          mode: InferenceMode.onlyInCloud,
          cloudModel: 'm',
          initializeDeviceModel: false,
        ).toList(),
        throwsA(isA<FirebaseNotInitializedException>()),
      );
    });
  });
}
