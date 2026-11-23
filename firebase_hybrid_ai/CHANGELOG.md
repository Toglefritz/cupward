## 0.0.1
* Initial release with support for Android and the web. iOS support is planned.
* Check whether the on-device model is available, downloadable, downloading, or unavailable, and follow its download progress.
* Generate text with `generateText`, or stream it as it is produced with `generateTextStream`. Each result reports whether the on-device or the cloud model produced it.
* Choose where a prompt runs: on-device first, cloud first, only on-device, or only in the cloud.
* Choose the on-device model on Android, between the stable and preview models, and the cloud model for any platform.
* Generate structured output with `generateStructured` and a `ResponseSchema`. Each result reports whether the platform enforced the schema, and whether the output conforms to it.
* Translate native errors into Dart exceptions.
