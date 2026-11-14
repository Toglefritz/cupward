import 'package:flutter/foundation.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

/// A nearby BLE device that looks like a BOOKOO Themis Ultra.
///
/// A device is only a candidate at this point. It is matched by its advertised name, and the GATT layout is verified
/// when connecting with `ThemisUltraClient.connect`.
@immutable
class ThemisUltraDevice {
  /// Creates a candidate from the advertised [name], platform [address], and signal strength [rssi].
  const new({
    required this.name,
    required this.address,
    required this.rssi,
  });

  /// Creates a candidate from a scan result.
  ///
  /// A missing advertised name becomes an empty string.
  factory fromBleDevice(
    BleDevice device,
  ) {
    return ThemisUltraDevice(
      name: device.name ?? '',
      address: device.address,
      rssi: device.rssi,
    );
  }

  /// The advertised local name of the device.
  final String name;

  /// The identifier the platform uses for this device.
  ///
  /// This is a MAC address on Android and a platform-generated UUID on iOS and macOS, so it should not be shown to
  /// users or assumed to be stable across platforms.
  final String address;

  /// The received signal strength in dBm at the time of the scan result.
  final int rssi;

  @override
  bool operator ==(
    Object other,
  ) {
    return other is ThemisUltraDevice && other.name == name && other.address == address && other.rssi == rssi;
  }

  @override
  int get hashCode => Object.hash(
    name,
    address,
    rssi,
  );

  @override
  String toString() => 'ThemisUltraDevice(name: $name, address: $address, rssi: $rssi)';
}
