import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../exceptions/firebase_not_initialized_exception.dart';
import '../messages.g.dart';
import 'web_generation_response.dart';

/// The globals that `firebase_core_web` creates for the Firebase JavaScript SDK modules. Core is always loaded, and
/// the `ai` module is loaded because this plugin registers it when it starts.
const String _coreGlobal = 'firebase_core';
const String _aiGlobal = 'firebase_ai';

/// The name of each mode in the JavaScript SDK's `InferenceMode` object.
String _sdkModeName(InferenceMode mode) {
  switch (mode) {
    case InferenceMode.preferOnDevice:
      return 'PREFER_ON_DEVICE';
    case InferenceMode.onlyOnDevice:
      return 'ONLY_ON_DEVICE';
    case InferenceMode.preferInCloud:
      return 'PREFER_IN_CLOUD';
    case InferenceMode.onlyInCloud:
      return 'ONLY_IN_CLOUD';
  }
}

/// Creates a generative model from the Firebase AI Logic JavaScript SDK in the given [mode].
///
/// This follows the SDK's hybrid inference setup: it gets the default Firebase app, creates the AI service with the
/// Gemini Developer API backend, and creates a model whose mode is [mode] and whose cloud model is [cloudModel].
///
/// When [initializeDeviceModel] is true, the SDK's `initializeDeviceModel()` is awaited before the model is returned.
/// The SDK requires that call before on-device inference, and it must run in response to a user interaction when it
/// has to download the model. Callers pass true only when the model is installed or when a download is intended.
///
/// Throws a [FirebaseNotInitializedException] if Firebase has not been initialized.
Future<JSObject> _createModel({
  required InferenceMode mode,
  required String cloudModel,
  required bool initializeDeviceModel,
}) async {
  final JSObject? core = globalContext[_coreGlobal] as JSObject?;
  final JSObject? ai = globalContext[_aiGlobal] as JSObject?;

  if (core == null || ai == null) {
    throw const FirebaseNotInitializedException(
      message: 'Firebase must be initialized before text can be generated.',
    );
  }

  final JSObject app;
  try {
    app = core.callMethod<JSObject>('getApp'.toJS);
  } on Object catch (error) {
    throw FirebaseNotInitializedException(
      message: 'Firebase must be initialized before text can be generated.',
      details: error.toString(),
    );
  }

  // `new GoogleAIBackend()` selects the Gemini Developer API, the default backend for Firebase AI Logic.
  final JSObject backend = (ai['GoogleAIBackend']! as JSFunction).callAsConstructor<JSObject>();
  final JSObject aiOptions = JSObject()..['backend'] = backend;
  final JSObject aiService = ai.callMethod<JSObject>('getAI'.toJS, app, aiOptions);

  final JSObject inCloudParams = JSObject()..['model'] = cloudModel.toJS;
  final JSObject modelParams = JSObject()
    ..['mode'] = (ai['InferenceMode']! as JSObject)[_sdkModeName(mode)]
    ..['inCloudParams'] = inCloudParams;

  final JSObject model = ai.callMethod<JSObject>('getGenerativeModel'.toJS, aiService, modelParams);

  if (initializeDeviceModel) {
    await model.callMethod<JSPromise<JSAny?>>('initializeDeviceModel'.toJS).toDart;
  }

  return model;
}

/// Converts one response object from the SDK into a [WebGenerationResponse].
///
/// The SDK's `text()` throws when the prompt or the candidate was blocked, and that error is left to propagate.
WebGenerationResponse _toResponse(JSObject response) {
  final String text = response.callMethod<JSString>('text'.toJS).toDart;
  final String source = (response['inferenceSource'] as JSString?)?.toDart ?? '';

  return WebGenerationResponse(text: text, source: source);
}

/// Sends [prompt] through the Firebase AI Logic JavaScript SDK in the given [mode] and returns the response.
///
/// See [_createModel] for how the model is set up and for [initializeDeviceModel].
///
/// Throws a [FirebaseNotInitializedException] if Firebase has not been initialized, and rethrows whatever the SDK
/// throws for a failed request.
Future<WebGenerationResponse> generateWithFirebaseAiJs({
  required String prompt,
  required InferenceMode mode,
  required String cloudModel,
  required bool initializeDeviceModel,
}) async {
  final JSObject model = await _createModel(
    mode: mode,
    cloudModel: cloudModel,
    initializeDeviceModel: initializeDeviceModel,
  );

  final JSObject result = await model.callMethod<JSPromise<JSObject>>('generateContent'.toJS, prompt.toJS).toDart;

  return _toResponse(result['response']! as JSObject);
}

/// Sends [prompt] through the Firebase AI Logic JavaScript SDK and emits the response chunk by chunk.
///
/// The SDK's `generateContentStream` returns an async generator, which this reads one step at a time with its `next`
/// method. A chunk with no text is skipped. When the subscription is cancelled, or the stream ends for any other
/// reason, the generator's `return` method is called so that the SDK stops reading the response.
///
/// See [_createModel] for how the model is set up and for [initializeDeviceModel]. Throws a
/// [FirebaseNotInitializedException] if Firebase has not been initialized, and rethrows whatever the SDK throws for a
/// failed request.
Stream<WebGenerationResponse> streamWithFirebaseAiJs({
  required String prompt,
  required InferenceMode mode,
  required String cloudModel,
  required bool initializeDeviceModel,
}) async* {
  final JSObject model = await _createModel(
    mode: mode,
    cloudModel: cloudModel,
    initializeDeviceModel: initializeDeviceModel,
  );

  final JSObject result = await model.callMethod<JSPromise<JSObject>>('generateContentStream'.toJS, prompt.toJS).toDart;
  final JSObject generator = result['stream']! as JSObject;

  try {
    while (true) {
      final JSObject step = await generator.callMethod<JSPromise<JSObject>>('next'.toJS).toDart;

      if ((step['done'] as JSBoolean?)?.toDart ?? false) {
        break;
      }

      final WebGenerationResponse chunk = _toResponse(step['value']! as JSObject);

      if (chunk.text.isNotEmpty) {
        yield chunk;
      }
    }
  } finally {
    // Calling `return` on a finished generator does nothing, and on a running one it stops the stream. A failure here
    // must not hide the error that ended the stream.
    try {
      if (generator.has('return')) {
        await generator.callMethod<JSPromise<JSAny?>>('return'.toJS).toDart;
      }
    } on Object {
      // Ignored on purpose.
    }
  }
}
