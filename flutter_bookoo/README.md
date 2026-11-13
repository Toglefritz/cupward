# flutter_bookoo

[![pub package](https://img.shields.io/pub/v/flutter_bookoo.svg)](https://pub.dev/packages/flutter_bookoo)

A Dart package for connecting Flutter apps to BOOKOO Themis coffee scales over Bluetooth Low Energy (BLE).

`flutter_bookoo` handles device discovery, connection management, and the scale's BLE protocol, then exposes the scale's measurements and controls as a typed Dart API. Your app works with weights, flow rates, and timer state instead of raw bytes and characteristics.

The package currently targets the **BOOKOO Themis Ultra**. Its scale abstraction is designed so that other scales, such as the BOOKOO Themis Mini, can be supported without changing how your app consumes data.

## Features

- Scan for nearby Themis scales and connect to one.
- Stream real-time weight readings.
- Stream flow rate, so you can track how quickly water is being poured.
- Stream the scale's timer state and elapsed time.
- Read battery level and connection state.
- Send commands to the scale, such as tare and timer start, stop, and reset.
- Typed models and streams, with no BLE knowledge required.

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
