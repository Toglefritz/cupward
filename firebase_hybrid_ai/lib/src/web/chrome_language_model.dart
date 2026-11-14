import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The name of the global that Chrome uses to expose the Prompt API.
const String _languageModelGlobal = 'LanguageModel';

/// Builds the options that declare English text input and output.
///
/// Chrome documents that the options passed to `availability()` must match those used when the model is prompted or
/// created, because support differs by modality and language. English text is what the Firebase AI Logic web SDK
/// requests for text generation.
JSObject _languageModelOptions() {
  return <String, Object?>{
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
}

/// Calls Chrome's `LanguageModel.availability()` and returns the string it resolves to.
///
/// Returns null when the browser has no `LanguageModel` global, so callers can tell a browser without the Prompt
/// API apart from one that reports the model as unavailable.
///
/// Throws if the browser rejects the call, for example outside a secure context.
Future<String?> readChromeLanguageModelAvailability() async {
  if (!globalContext.has(_languageModelGlobal)) {
    return null;
  }

  final JSObject languageModel = globalContext[_languageModelGlobal]! as JSObject;

  final JSString availability = await languageModel
      .callMethod<JSPromise<JSString>>('availability'.toJS, _languageModelOptions())
      .toDart;

  return availability.toDart;
}

/// Downloads Chrome's on-device model by creating a Prompt API session, and streams the download progress.
///
/// Creating a session is what makes Chrome start the download. Chrome only allows that after the user has interacted
/// with the page, so this must be listened to from a user-initiated handler. Progress arrives from the
/// `downloadprogress` event of the monitor that is passed to `create()`, as a fraction from 0 to 1. The session is
/// destroyed as soon as it exists, because only the downloaded model is wanted and an open session keeps the model
/// loaded in memory. The stream emits 1.0 and closes after that. If Chrome rejects the call, the stream emits the
/// error and closes.
///
/// The browser must have a `LanguageModel` global. Callers check for that first with
/// [readChromeLanguageModelAvailability].
Stream<double> downloadChromeLanguageModel() {
  late final StreamController<double> controller;

  controller = StreamController<double>(
    onListen: () async {
      try {
        final JSObject languageModel = globalContext[_languageModelGlobal]! as JSObject;
        final JSObject options = _languageModelOptions();

        // Chrome calls the monitor with an event target, and the target fires `downloadprogress` as bytes arrive.
        options['monitor'] = ((JSObject monitor) {
          monitor.callMethod<JSAny?>(
            'addEventListener'.toJS,
            'downloadprogress'.toJS,
            ((JSObject event) {
              final JSAny? loaded = event['loaded'];

              if (loaded.isA<JSNumber>()) {
                controller.add((loaded! as JSNumber).toDartDouble.clamp(0.0, 1.0));
              }
            }).toJS,
          );
        }).toJS;

        final JSObject session = await languageModel.callMethod<JSPromise<JSObject>>('create'.toJS, options).toDart;
        session.callMethod<JSAny?>('destroy'.toJS);

        controller.add(1);
      } on Object catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        await controller.close();
      }
    },
  );

  return controller.stream;
}
