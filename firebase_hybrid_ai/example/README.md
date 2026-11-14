# firebase_hybrid_ai_example

An example app for the `firebase_hybrid_ai` plugin. It reports the state of the on-device model on the current device or browser, using `FirebaseHybridAi.checkOnDeviceStatus()`.

## Setup

The app needs Firebase configuration files that are generated for your own Firebase project. Follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md) before running it.

## Running

```sh
flutter pub get
flutter run -d <device-id>
```

Use `flutter devices` to list the available devices. The example targets Android devices that support on-device Gemini Nano, and desktop Chrome.

## Tests

`flutter test` runs the widget tests with a fake plugin implementation. `integration_test/plugin_integration_test.dart` runs against the real platform on a device and needs the Firebase configuration files:

```sh
flutter test integration_test -d <device-id>
```
