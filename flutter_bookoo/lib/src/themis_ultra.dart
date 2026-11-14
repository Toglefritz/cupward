import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import 'models/themis_ultra_device.dart';

/// A connected BOOKOO Themis Ultra whose GATT layout has been verified.
///
/// Instances are created by `ThemisUltraClient.connect`. Holding an instance means the scale exposes the service and
/// characteristics this package needs.
class ThemisUltra {
  /// Creates a connected scale handle.
  ///
  /// Use `ThemisUltraClient.connect` instead of calling this directly, since it performs the connection and the GATT
  /// verification that this type assumes have already succeeded.
  new({
    required this.device,
    required this.services,
    required this.commandCharacteristic,
    required this.weightCharacteristic,
    required this._ble,
  });

  /// The device this handle is connected to.
  final ThemisUltraDevice device;

  /// Every service discovered on the scale, including ones this package does not use. This is useful for diagnostics.
  final List<BleService> services;

  /// The characteristic that accepts commands such as tare and timer control.
  final BleCharacteristic commandCharacteristic;

  /// The characteristic that notifies weight, flow rate, timer, and battery data.
  final BleCharacteristic weightCharacteristic;

  /// The BLE central used for platform calls.
  final SplendidBleCentral _ble;

  /// Disconnects from the scale.
  ///
  /// The handle should not be used afterward. Connect again with `ThemisUltraClient.connect` to resume communication.
  Future<void> disconnect() => _ble.disconnect(
    device.address,
  );

  @override
  String toString() => 'ThemisUltra(device: $device)';
}
