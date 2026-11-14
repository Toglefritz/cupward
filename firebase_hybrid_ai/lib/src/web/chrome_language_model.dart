import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The name of the global that Chrome uses to expose the Prompt API.
const String _languageModelGlobal = 'LanguageModel';

/// Calls Chrome's `LanguageModel.availability()` and returns the string it resolves to.
///
/// Returns null when the browser has no `LanguageModel` global, so callers can tell a browser without the Prompt
/// API apart from one that reports the model as unavailable.
///
/// The request declares English text input and output. Chrome documents that the options passed to
/// `availability()` must match those used when the model is prompted, because support differs by modality and
/// language. English text is what the Firebase AI Logic web SDK requests for text generation.
///
/// Throws if the browser rejects the call, for example outside a secure context.
Future<String?> readChromeLanguageModelAvailability() async {
  if (!globalContext.has(_languageModelGlobal)) {
    return null;
  }

  final JSObject languageModel = globalContext[_languageModelGlobal]! as JSObject;

  final JSObject options =
      <String, Object?>{
            'expectedInputs': <Object?>[
              <String, Object?>{
                'type': 'text',
                'languages': <String>['en'],
              },
            ],
            'expectedOutputs': <Object?>[
              <String, Object?>{
                'type': 'text',
                'languages': <String>['en'],
              },
            ],
          }.jsify()!
          as JSObject;

  final JSString availability = await languageModel
      .callMethod<JSPromise<JSString>>('availability'.toJS, options)
      .toDart;

  return availability.toDart;
}
