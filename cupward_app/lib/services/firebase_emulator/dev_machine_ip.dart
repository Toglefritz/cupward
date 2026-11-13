// coverage:ignore-file
import 'dart:io';

/// The host address of the machine running the Firebase Emulator Suite.
///
/// Debug builds that opt in to the emulators (`flutter run --dart-define=USE_FIREBASE_EMULATOR=true`) connect to this
/// host instead of the cloud.
///
/// Desktop builds run on the same machine as the emulators, so they use `localhost`. Physical devices and Android
/// emulators must reach the development machine over the network. Android and iOS emulators can use `10.0.2.2`;
/// physical devices need the development machine's LAN IP address. Override it at launch to avoid committing a
/// personal IP:
///
/// `flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.1.42`
///
/// To find the development machine's LAN IP address on macOS, use one of the following:
///
/// * Run `ipconfig getifaddr en0` in a terminal. `en0` is usually the Wi-Fi interface. If it prints nothing, try
///   `en1`, or run `ifconfig | grep "inet "` and pick the `192.168.x.x` or `10.x.x.x` address.
/// * Open System Settings > Wi-Fi, click Details next to the connected network, and read the IP address.
///
/// The device and the development machine must be on the same network, and the machine's firewall must allow incoming
/// connections to the emulator ports (Auth 9099, Firestore 8080).
final String devMachineIP = const String.fromEnvironment('EMULATOR_HOST').isNotEmpty
    ? const String.fromEnvironment('EMULATOR_HOST')
    : (Platform.isMacOS || Platform.isIOS ? 'localhost' : '10.0.2.2');
