@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai_web.dart';
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
}
