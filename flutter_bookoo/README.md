# flutter_bookoo

[![pub package](https://img.shields.io/pub/v/flutter_bookoo.svg)](https://pub.dev/packages/flutter_bookoo)

A Dart package for connecting Flutter apps to BOOKOO Themis coffee scales over Bluetooth Low Energy (BLE).

`flutter_bookoo` handles device discovery, connection management, and the scale's BLE protocol, then exposes the scale's measurements and controls as a typed Dart API. Your app works with weights, flow rates, and timer state instead of raw bytes and characteristics.

The package currently targets the **BOOKOO Themis Ultra**. Its scale abstraction is designed so that other scales, such as the BOOKOO Themis Mini, can be supported without changing how your app consumes data.

## Features

- Scan for nearby Themis Ultra scales, recognized by their advertised name.
- Connect to a scale and check that it exposes the expected Bluetooth service and characteristics, so an unrelated device is rejected with a clear error.
- Stream live readings about ten times per second. Each reading has the weight in grams, the flow rate in grams per second, the scale's timer, the battery percentage, the standby time, the beeper level, and whether flow smoothing is on.
- Stream the raw notification frames, for diagnostics and for capturing test fixtures.
- Zero the scale with `tare()`.
- Typed models and exceptions, with no BLE knowledge required. Malformed frames are dropped, and the readings stream keeps going.

Controlling the scale's timer, and reading the connection state as a stream, are not available yet.

## Why a package and not a plugin

`flutter_bookoo` contains only Dart code. It has no Android, iOS, macOS, or other platform-specific implementation of its own.

All Bluetooth communication is delegated to [`flutter_splendid_ble`](https://pub.dev/packages/flutter_splendid_ble), which provides the native BLE implementations. This package builds on top of it to interpret what the scale sends and to encode what the scale expects to receive.

## Getting started

### Installation

Add the package to your project:

```sh
flutter pub add flutter_bookoo
```

This adds the latest version to your `pubspec.yaml` and fetches dependencies.

### Platform setup

Because Bluetooth access is provided by `flutter_splendid_ble`, platform configuration follows that package's requirements. In general:

- **Android:** declare the Bluetooth permissions your target API levels require, and request them at runtime before scanning.
- **iOS and macOS:** add a Bluetooth usage description (`NSBluetoothAlwaysUsageDescription`) to your `Info.plist`, and enable the Bluetooth entitlement on macOS.

See the [`flutter_splendid_ble` documentation](https://pub.dev/packages/flutter_splendid_ble) for the complete, current setup steps for each platform.

## Supported scales

| Scale | Status |
| --- | --- |
| BOOKOO Themis Ultra | Supported |
| BOOKOO Themis Mini | Planned |

## Additional information

`flutter_bookoo` is an independent, community-built package. It is not affiliated with, endorsed by, or sponsored by BOOKOO. BOOKOO and Themis are trademarks of their respective owners.

Report bugs and request features through the issue tracker on the package's repository.

## License

Copyright 2026, Splendid Endeavors LLC.

`flutter_bookoo` is licensed under the [Apache License 2.0](LICENSE).
