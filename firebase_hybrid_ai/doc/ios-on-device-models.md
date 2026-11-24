# On-device and cloud models on iOS
On iOS, the on-device model is the system language model in Apple's Foundation Models framework. The system provides it, so an app does not choose a version or start a download. The cloud model is a Gemini model that the Firebase SDK for Apple platforms plugs into the same framework. This article explains what the plugin does with each, and what a device and a build need.
## What the plugin does
Both models are used through Apple's `LanguageModelSession`. For each request the plugin picks the model from the `InferenceMode` and falls back in the same cases as on Android and the web:
| Mode | Behavior |
| --- | --- |
| `preferOnDevice` | Uses the on-device model. If it is unavailable, or it fails before it produces any text, the request goes to the cloud model. |
| `onlyOnDevice` | Uses the on-device model, and fails with `OnDeviceModelUnavailableException` if it is unavailable. |
| `preferInCloud` | Uses the cloud model. If the device is offline, the request goes to the on-device model. Other cloud failures are reported. |
| `onlyInCloud` | Uses the cloud model only. |
A streamed response does not switch models after its first chunk has been sent, because the person would see two answers joined together.
Every request needs Firebase to be initialized, as on Android, even when it only uses the on-device model. A request without a default Firebase app fails with `FirebaseNotInitializedException`.
## What the device and the build need
| For | Requirement |
| --- | --- |
| The on-device model | iOS 26 or later, on a device that supports Apple Intelligence, with Apple Intelligence turned on in Settings. |
| The cloud model | iOS 27 or later, and an app built with Xcode 27 or later. |
| Both | An app that uses Swift Package Manager for its Flutter plugins. The plugin does not link the Firebase SDK when an app uses CocoaPods, so cloud requests fail there and only the on-device model works. |
On an earlier version of iOS, every request fails with `HybridAiNotSupportedException`. On iOS 26, a request that needs the cloud model fails with a message that says the cloud model needs iOS 27.
Cloud requests go through Firebase AI Logic, so they carry an App Check token like cloud requests on every other platform. Register the debug token in the Firebase console while you develop. Requests that only use the on-device model do not contact Firebase.
## Checking the on-device model
`checkOnDeviceStatus` maps the system's state to the same values as the other platforms:
| System state | `OnDeviceModelAvailability` |
| --- | --- |
| Available | `available`, with `modelName` set to `apple-foundation-models-system-language-model` |
| Apple Intelligence is on, and the model is still downloading | `downloading` |
| The device is not eligible, or Apple Intelligence is off | `unavailable` |
Apple does not let an app turn on Apple Intelligence or start the model download. `unavailable` is therefore never reported as `downloadable`, which on Android means that the app can start a download. To get the model, ask the person to turn on Apple Intelligence in Settings. `downloadOnDeviceModel` always fails with `HybridAiNotSupportedException` on iOS. The `category` argument is ignored, because Apple provides one on-device model.
## Structured output
`generateStructured` builds a Foundation Models schema from the `ResponseSchema` and passes it to the model, so the output is constrained to the schema for both the on-device model and the cloud model. `isSchemaEnforced` is true for these requests.
If the framework cannot build a schema from a valid `ResponseSchema`, the plugin describes the schema in the prompt instead, and `isSchemaEnforced` is false. The plugin validates the output against the schema in both cases. Check `conformsToSchema` before using `data` from a request that is not enforced.
The framework does not keep the order of an object's properties, so the plugin sorts them by name. The order of the properties in the JSON that comes back can differ from the order in the `ResponseSchema`.
## Limits
These come from Firebase's documentation for hybrid inference on Apple platforms, and from Apple's:
- On-device inference works only while the app is in the foreground.
- On-device requests are limited to about 4,096 tokens.
- The on-device model is governed by [Apple's acceptable use requirements for the Foundation Models framework](https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework).
