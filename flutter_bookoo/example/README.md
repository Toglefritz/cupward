# flutter_bookoo_example

An example app for the `flutter_bookoo` package. It scans for nearby BOOKOO Themis Ultra scales, connects to the one you choose, and shows its live readings: the weight, the flow rate, the scale's timer, and the battery level. A Tare button zeroes the scale. An activity log on screen records each scan result, connection step, discovered service and characteristic, and command, so you can follow what the package is doing on real hardware without a debugger. Frame capture records the raw notification frames from the scale as hex and copies them to the clipboard, one frame per line.

## Setup

The app needs a BOOKOO Themis Ultra scale that is turned on and nearby. Bluetooth permissions and usage descriptions are already configured for Android, iOS, and macOS. The first scan asks for Bluetooth permission.

## Running

```sh
flutter pub get
flutter run -d <device-id>
```

Use `flutter devices` to list the available devices. The example targets Android, iOS, and macOS. It does not run on the web, because `flutter_splendid_ble` has no web implementation.

## Capturing frames for tests

Captured frames can be added to the package's decoder tests. Paste them into a `.hex` file under `test/fixtures/frames` in the package, and `flutter test` in the package directory checks that every frame decodes.
