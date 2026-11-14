import 'dart:async';

import 'package:flutter_splendid_ble/central/fake_central_method_channel.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

/// A [FakeCentralMethodChannel] with the extra controls the connection and scan tests need.
///
/// The base fake always reports an enabled adapter and always connects successfully, so this subclass adds configurable
/// adapter status, permission status, scripted connection events, and a record of disconnect calls.
class TestCentral extends FakeCentralMethodChannel {
  /// Creates a central with optional overrides.
  ///
  /// When [connectionEvents] is non-null, [connect] emits exactly those events (after a short delay) instead of the
  /// base fake's behavior. An empty list simulates a device that never answers.
  new({
    this.adapterStatus = BluetoothStatus.enabled,
    this.permissionStatus = BluetoothPermissionStatus.granted,
    this.connectionEvents,
  });

  /// The status returned by [checkBluetoothAdapterStatus].
  final BluetoothStatus adapterStatus;

  /// The status returned by [requestBluetoothPermissions].
  final BluetoothPermissionStatus permissionStatus;

  /// Scripted connection events, or null to use the base fake's behavior.
  final List<BleConnectionEvent>? connectionEvents;

  /// Addresses passed to [disconnect], in call order.
  final List<String> disconnectedAddresses = <String>[];

  @override
  Future<BluetoothStatus> checkBluetoothAdapterStatus() async => adapterStatus;

  @override
  Future<BluetoothPermissionStatus> requestBluetoothPermissions() async => permissionStatus;

  @override
  Future<Stream<BleConnectionEvent>> connect({
    required String deviceAddress,
  }) async {
    final List<BleConnectionEvent>? scripted = connectionEvents;
    if (scripted == null) {
      return await super.connect(
        deviceAddress: deviceAddress,
      );
    }

    // Emit after the caller has had a chance to listen, like a real platform.
    final StreamController<BleConnectionEvent> controller = StreamController<BleConnectionEvent>.broadcast();
    Future<void>.delayed(
      const Duration(
        milliseconds: 20,
      ),
      () {
        scripted.forEach(
          controller.add,
        );
      },
    );
    return controller.stream;
  }

  @override
  Future<void> disconnect(
    String deviceAddress,
  ) async {
    disconnectedAddresses.add(
      deviceAddress,
    );
    await super.disconnect(
      deviceAddress,
    );
  }
}
