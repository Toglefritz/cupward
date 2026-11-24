## 0.0.2
* Add support for iOS. The plugin uses Apple's Foundation Models framework for the on-device model and a Gemini model from the Firebase SDK for Apple platforms for the cloud, and chooses between them with the same inference modes as on the other platforms.
* Report the on-device model's status on iOS. The system downloads the model when Apple Intelligence is turned on, so `downloadOnDeviceModel` is not supported on iOS.
* Constrain structured output to the schema on iOS, for both the on-device model and the cloud model.
* The on-device model on iOS needs iOS 26 or later. The cloud model needs iOS 27 or later and an app built with Xcode 27 or later. See `doc/ios-on-device-models.md`.

## 0.0.1
* Initial release with support for Android and the web. iOS support is planned.
* Check whether the on-device model is available, downloadable, downloading, or unavailable, and follow its download progress.
* Generate text with `generateText`, or stream it as it is produced with `generateTextStream`. Each result reports whether the on-device or the cloud model produced it.
* Choose where a prompt runs: on-device first, cloud first, only on-device, or only in the cloud.
* Choose the on-device model on Android, between the stable and preview models, and the cloud model for any platform.
* Generate structured output with `generateStructured` and a `ResponseSchema`. Each result reports whether the platform enforced the schema, and whether the output conforms to it.
* Translate native errors into Dart exceptions.
