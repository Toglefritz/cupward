# firebase_hybrid_ai

[![pub package](https://img.shields.io/pub/v/firebase_hybrid_ai.svg)](https://pub.dev/packages/firebase_hybrid_ai)

A Flutter plugin that bridges Dart code to the Firebase AI Logic hybrid inference SDKs.

Hybrid inference lets an app run a prompt on a model that lives on the user's device when one is available, and fall back to a cloud-hosted Gemini model when it is not (or the other way around). `firebase_hybrid_ai` brings that capability to Flutter, so a single Dart API can use on-device and cloud models without writing separate native code for each platform.

## Why?

On-device models are fast, private, free to run, and work offline, but they are not available on every device. Cloud models are available everywhere there is a network connection, but they add latency and cost, and they require sending the user's data off the device. Hybrid inference combines the two: the app asks for a response, and the SDK decides where to run it based on what the device supports.

Firebase AI Logic provides this behavior through its native SDKs, each wrapping a different on-device model:

| Platform | On-device model |
| --- | --- |
| Android | Gemini Nano, through the ML Kit Prompt API and AICore |
| iOS | Apple Foundation Models |
| Web | Gemini Nano, through the Chrome Prompt API |

Those SDKs are written in Kotlin, Swift, and JavaScript. A Flutter app cannot call them directly, and each one has its own initialization steps, model availability checks, and inference modes. This plugin wraps all three behind one Dart interface, so your app code does not need to know which platform it is running on.

## Purpose

`firebase_hybrid_ai` is a thin bridge. It does not implement inference, choose models, or add AI behavior of its own. Its job is to:

- Expose the hybrid SDKs' inference modes (prefer on-device, prefer cloud, only on-device, only cloud) as Dart types.
- Report whether the on-device model is available on the current device, and surface its download progress where the platform supports downloads.
- Send prompts and return the response, including streamed responses, along with which source (on-device or cloud) produced it.
- Request responses that match a JSON schema, and report for every response whether the platform enforced the schema and whether the output conforms to it.
- Translate native errors into Dart exceptions.

Anything the underlying SDKs do not support is not available through this plugin. For example, the on-device models handle a limited set of request types, and requests the on-device model cannot serve are handled according to the inference mode you choose. See the Firebase AI Logic documentation for each platform's capabilities and limits.

## Requirements

- A Firebase project with [Firebase AI Logic](https://firebase.google.com/docs/ai-logic) enabled.
- Firebase initialized in your app with `firebase_core`. Firebase AI Logic is protected by Firebase App Check, so your app also needs `firebase_app_check`.
- For on-device inference, a device that supports the platform's on-device model. Devices without support use the cloud model, or receive an error if you chose an on-device-only mode.

## Usage
After Firebase is initialized, create a `FirebaseHybridAi` and send a prompt. The result says which model answered:
```dart
final FirebaseHybridAi ai = FirebaseHybridAi();
final TextGenerationResult result = await ai.generateText('Why is the sky blue?');
print('${result.text} (${result.source.name})');
```
Choose where the prompt runs with `mode`, for example `InferenceMode.onlyOnDevice` to keep it on the device. `generateTextStream` returns the response in chunks, and `generateStructured` takes a `ResponseSchema` and returns JSON that is checked against it. Every method, argument, and exception is documented in the package's API reference, and the [example app](example) uses each of them.

## Choosing the on-device model

Which on-device model an app receives depends on the platform. These guides explain what the plugin controls and what it does not:

- [Android](doc/android-on-device-models.md): choose between the stable model and the preview models, and enroll a device in the AICore Developer Preview.
- [iOS](doc/ios-on-device-models.md): how the plugin uses Apple's on-device model and a Gemini model together, and what the device and the build need.
- [Web (Chrome)](doc/web-on-device-models.md): how Chrome chooses and stores its model, how to see which model is installed, and how Chrome's Gemma 4 flag fits in.

## Additional information

`firebase_hybrid_ai` is an independent, community-developed plugin. It is not affiliated with, endorsed by, or sponsored by Google, Firebase, or Apple. Firebase, Gemini, Gemini Nano, Chrome, and Apple Foundation Models are trademarks of their respective owners.

Report bugs and request features through the issue tracker on the plugin's repository.

## License

Copyright 2026, Splendid Endeavors, LLC.

`firebase_hybrid_ai` is licensed under the [Apache License 2.0](LICENSE).
