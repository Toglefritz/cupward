import 'dart:async';

import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_connection_exception.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/service_discovery_exception.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import 'exceptions/themis_bluetooth_unavailable_exception.dart';
import 'exceptions/themis_connection_exception.dart';
import 'exceptions/themis_unsupported_device_exception.dart';
import 'gatt/themis_ultra_gatt.dart';
import 'models/themis_ultra_device.dart';
import 'themis_ultra.dart';

/// Finds and connects to BOOKOO Themis Ultra scales.
///
/// This is the entry point of the package. It wraps a [SplendidBleCentral] for all Bluetooth work, so tests can supply
/// a central backed by a fake platform.
///
/// ```dart
/// final ThemisUltraClient client = ThemisUltraClient();
/// final ThemisUltraDevice device = await client.scan().first;
/// final ThemisUltra scale = await client.connect(device);
/// ```
class ThemisUltraClient {
  /// Creates a client.
  ///
  /// [ble] defaults to a [SplendidBleCentral] using the real platform. Scan results are matched against
  /// [advertisedNamePrefixes], which defaults to [ThemisUltraGatt.advertisedNamePrefix]. [connectTimeout] and
  /// [discoveryTimeout] bound the connection and service discovery steps of [connect].
  new({
    SplendidBleCentral? ble,
    this.advertisedNamePrefixes = const <String>[
      ThemisUltraGatt.advertisedNamePrefix,
    ],
    this.connectTimeout = const Duration(
      seconds: 15,
    ),
    this.discoveryTimeout = const Duration(
      seconds: 10,
    ),
  }) : _ble = ble ?? SplendidBleCentral();

  /// Case-insensitive prefixes an advertised name must start with to be treated as a Themis Ultra candidate.
  final List<String> advertisedNamePrefixes;

  /// The longest [connect] waits for the platform to report a connection.
  final Duration connectTimeout;

  /// The longest [connect] waits for service discovery to finish.
  final Duration discoveryTimeout;

  /// The BLE central used for all platform calls.
  final SplendidBleCentral _ble;

  /// Returns whether [device] advertises a name matching [advertisedNamePrefixes].
  ///
  /// The advertised name is the only signal available before connecting. Other BOOKOO scales, such as the Themis Mini,
  /// share the same GATT layout and may match too, so a match means "possibly an Ultra".
  bool isCandidate(
    BleDevice device,
  ) {
    final String? name = device.name?.toLowerCase();
    if (name == null || name.isEmpty) {
      return false;
    }

    return advertisedNamePrefixes.any(
      (
        prefix,
      ) => name.startsWith(
        prefix.toLowerCase(),
      ),
    );
  }

  /// Scans for Themis Ultra candidates.
  ///
  /// Checks that Bluetooth is enabled and permitted, then emits a [ThemisUltraDevice] for each scan result that passes
  /// [isCandidate]. The same device can be emitted more than once when its advertisement changes, so callers that show
  /// a list should key it by [ThemisUltraDevice.address] and keep the latest value.
  ///
  /// The scan stops and the stream closes after [timeout], or sooner when the subscription is cancelled. Errors,
  /// including [ThemisBluetoothUnavailableException], are delivered on the stream.
  Stream<ThemisUltraDevice> scan({
    Duration timeout = const Duration(
      seconds: 15,
    ),
  }) {
    final StreamController<ThemisUltraDevice> controller = StreamController<ThemisUltraDevice>();
    StreamSubscription<BleDevice>? subscription;
    Timer? timer;
    bool stopped = false;

    // Stops the platform scan once. Called on timeout, failure, and cancel.
    Future<void> stop() async {
      if (stopped) {
        return;
      }
      stopped = true;
      timer?.cancel();
      await subscription?.cancel();
      try {
        await _ble.stopScan();
      } on Object {
        // The scan is ending anyway, so a failure to stop adds no information.
      }
    }

    controller
      ..onListen = () async {
        try {
          await _ensureBluetoothReady();
          if (stopped) {
            return;
          }

          final Stream<BleDevice> results = await _ble.startScan();
          if (stopped) {
            // The listener cancelled while the scan was starting.
            await _ble.stopScan();
            return;
          }

          subscription = results.listen(
            (device) {
              if (isCandidate(device)) {
                controller.add(
                  ThemisUltraDevice.fromBleDevice(device),
                );
              }
            },
            onError: controller.addError,
          );

          timer = Timer(timeout, () async {
            await stop();
            await controller.close();
          });
        } on Object catch (error, stackTrace) {
          controller.addError(
            error,
            stackTrace,
          );
          await stop();
          await controller.close();
        }
      }
      ..onCancel = stop;

    return controller.stream;
  }

  /// Connects to [device] and verifies that it exposes a Themis Ultra GATT layout.
  ///
  /// Steps:
  /// 1. Connect and wait for the platform to report a connected state.
  /// 2. Discover services.
  /// 3. Require the Themis service, a writable command characteristic, and a
  /// notifying weight characteristic.
  ///
  /// If any step fails the device is disconnected before the error propagates.
  ///
  /// Throws [ThemisConnectionException] when the connection or discovery fails or times out. Throws
  /// [ThemisUnsupportedDeviceException] when the GATT layout does not match.
  Future<ThemisUltra> connect(
    ThemisUltraDevice device,
  ) async {
    try {
      await _awaitConnected(
        device.address,
      );
      final List<BleService> services = await _discoverServices(
        device.address,
      );
      final ({
        BleCharacteristic command,
        BleCharacteristic weight,
      })
      characteristics = _verifyGatt(
        address: device.address,
        services: services,
      );

      return ThemisUltra(
        device: device,
        services: services,
        commandCharacteristic: characteristics.command,
        weightCharacteristic: characteristics.weight,
        ble: _ble,
      );
    } on Object {
      await _disconnectQuietly(
        device.address,
      );
      rethrow;
    }
  }

  /// Throws [ThemisBluetoothUnavailableException] unless the adapter is enabled and permissions are not denied.
  Future<void> _ensureBluetoothReady() async {
    final BluetoothPermissionStatus permission = await _ble.requestBluetoothPermissions();
    if (permission == BluetoothPermissionStatus.denied) {
      throw const ThemisBluetoothUnavailableException(
        'Bluetooth permission was denied.',
      );
    }

    final BluetoothStatus status = await _ble.checkBluetoothAdapterStatus();
    if (status != BluetoothStatus.enabled) {
      throw ThemisBluetoothUnavailableException(
        'Bluetooth is not enabled (${status.identifier}).',
      );
    }
  }

  /// Starts a connection to [address] and completes when the platform reports it connected.
  ///
  /// A plain `disconnected` event before the connection is established is ignored, since platforms report the prior
  /// state first. A `failed` event, or a `disconnected` event carrying failure detail, ends the attempt.
  Future<void> _awaitConnected(
    String address,
  ) async {
    try {
      final Stream<BleConnectionEvent> events = await _ble.connect(
        deviceAddress: address,
      );
      final BleConnectionEvent result = await events
          .firstWhere(
            (event) => event.state == BleConnectionState.connected || event.isFailure,
          )
          .timeout(
            connectTimeout,
          );

      if (result.state != BleConnectionState.connected) {
        throw ThemisConnectionException(
          'Connection to $address failed (${result.state.identifier}).',
          failure: result.failure,
        );
      }
    } on TimeoutException {
      throw ThemisConnectionException(
        'Timed out connecting to $address after $connectTimeout.',
      );
    } on BluetoothConnectionException catch (error) {
      throw ThemisConnectionException(
        'Connection to $address failed: ${error.message}',
      );
    }
  }

  /// Discovers the services on the connected device at [address].
  Future<List<BleService>> _discoverServices(
    String address,
  ) async {
    try {
      final Stream<List<BleService>> results = await _ble.discoverServices(
        address,
      );
      return await results.first.timeout(
        discoveryTimeout,
      );
    } on TimeoutException {
      throw ThemisConnectionException(
        'Timed out discovering services on $address after $discoveryTimeout.',
      );
    } on ServiceDiscoveryException catch (error) {
      throw ThemisConnectionException(
        'Service discovery on $address failed: ${error.message}',
      );
    }
  }

  /// Checks [services] for the Themis service and the characteristics, and capabilities, this package needs.
  ///
  /// Every problem is collected before throwing so a single failure report describes the whole mismatch.
  ///
  /// Throws [ThemisUnsupportedDeviceException] when anything is missing.
  ({
    BleCharacteristic command,
    BleCharacteristic weight,
  })
  _verifyGatt({
    required String address,
    required List<BleService> services,
  }) {
    final List<String> problems = <String>[];

    final BleService? service = services
        .where(
          (s) => ThemisUltraGatt.uuidsMatch(
            s.serviceUuid,
            ThemisUltraGatt.serviceUuid,
          ),
        )
        .firstOrNull;

    if (service == null) {
      problems.add(
        'missing service ${ThemisUltraGatt.serviceUuid}',
      );
      throw ThemisUnsupportedDeviceException(
        address: address,
        problems: problems,
      );
    }

    final BleCharacteristic? command = _findCharacteristic(
      service,
      ThemisUltraGatt.commandCharacteristicUuid,
    );
    final BleCharacteristic? weight = _findCharacteristic(
      service,
      ThemisUltraGatt.weightCharacteristicUuid,
    );

    if (command == null) {
      problems.add(
        'missing command characteristic ${ThemisUltraGatt.commandCharacteristicUuid}',
      );
    } else if (!command.properties.contains(
          BleCharacteristicProperty.write,
        ) &&
        !command.properties.contains(
          BleCharacteristicProperty.noResponse,
        )) {
      problems.add(
        'command characteristic ${ThemisUltraGatt.commandCharacteristicUuid} is not writable',
      );
    }

    if (weight == null) {
      problems.add(
        'missing weight characteristic ${ThemisUltraGatt.weightCharacteristicUuid}',
      );
    } else if (!weight.properties.contains(
          BleCharacteristicProperty.notify,
        ) &&
        !weight.properties.contains(
          BleCharacteristicProperty.indicate,
        )) {
      problems.add(
        'weight characteristic ${ThemisUltraGatt.weightCharacteristicUuid} cannot notify',
      );
    }

    if (problems.isNotEmpty || command == null || weight == null) {
      throw ThemisUnsupportedDeviceException(
        address: address,
        problems: problems,
      );
    }

    return (
      command: command,
      weight: weight,
    );
  }

  /// Returns the characteristic in [service] matching [uuid], or null.
  BleCharacteristic? _findCharacteristic(
    BleService service,
    String uuid,
  ) {
    return service.characteristics
        .where(
          (c) => ThemisUltraGatt.uuidsMatch(
            c.uuid,
            uuid,
          ),
        )
        .firstOrNull;
  }

  /// Disconnects from [address], ignoring errors.
  ///
  /// Used while unwinding a failed [connect], where the original error is the one worth reporting.
  Future<void> _disconnectQuietly(
    String address,
  ) async {
    try {
      await _ble.disconnect(
        address,
      );
    } on Object {
      // The original failure is more useful to the caller.
    }
  }
}
