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

/// Sends [prompt] through the Firebase AI Logic JavaScript SDK in the given [mode] and returns the response.
///
/// This follows the SDK's hybrid inference setup: it gets the default Firebase app, creates the AI service with the
/// Gemini Developer API backend, creates a model whose mode is [mode] and whose cloud model is [cloudModel], and
/// calls `generateContent`.
///
/// When [initializeDeviceModel] is true, the SDK's `initializeDeviceModel()` is awaited first. The SDK requires that
/// call before on-device inference, and it must run in response to a user interaction when it has to download the
/// model. Callers pass true only when the model is installed or when a download is intended.
///
/// Throws a [FirebaseNotInitializedException] if Firebase has not been initialized, and rethrows whatever the SDK
/// throws for a failed request.
Future<WebGenerationResponse> generateWithFirebaseAiJs({
  required String prompt,
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

  final JSObject result = await model.callMethod<JSPromise<JSObject>>('generateContent'.toJS, prompt.toJS).toDart;
  final JSObject response = result['response']! as JSObject;

  final String text = response.callMethod<JSString>('text'.toJS).toDart;
  final String source = (response['inferenceSource'] as JSString?)?.toDart ?? '';

  return WebGenerationResponse(text: text, source: source);
}
