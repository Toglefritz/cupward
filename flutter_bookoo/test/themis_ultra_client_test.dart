/// Tests for scanning and connecting in `ThemisUltraClient`.
///
/// The Bluetooth platform is replaced by `TestCentral`, a fake central that serves scripted devices, services, and
/// connection events. No hardware is involved.
library;

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_central.dart';

const String _ultraAddress = 'AA:BB:CC:DD:EE:01';

/// Builds a scan result with the given [name] and [address].
BleDevice _device(
  String? name,
  String address,
) {
  return BleDevice(
    name: name,
    address: address,
    advertisedServiceUuids: <String>[],
    rssi: -60,
    manufacturerData: null,
  );
}

/// Builds a characteristic on [_ultraAddress].
BleCharacteristic _characteristic(
  String uuid,
  List<BleCharacteristicProperty> properties,
) {
  return BleCharacteristic(
    address: _ultraAddress,
    uuid: uuid,
    properties: properties,
    permissions: null,
  );
}

/// Builds the GATT layout of a healthy Themis Ultra, using 128-bit UUIDs to exercise normalization.
List<BleService> _validServices() {
  return <BleService>[
    BleService(
      serviceUuid: '00000ffe-0000-1000-8000-00805f9b34fb',
      characteristics: <BleCharacteristic>[
        _characteristic(
          '0000ff11-0000-1000-8000-00805f9b34fb',
          <BleCharacteristicProperty>[
            BleCharacteristicProperty.notify,
          ],
        ),
        _characteristic(
          '0000ff12-0000-1000-8000-00805f9b34fb',
          <BleCharacteristicProperty>[
            BleCharacteristicProperty.write,
            BleCharacteristicProperty.noResponse,
          ],
        ),
      ],
    ),
  ];
}

void main() {
  /// Scan behavior: filtering results and reporting unusable Bluetooth.
  group('scan', () {
    /// A mixed environment must yield only BOOKOO-named devices, so an app never offers unrelated peripherals to the
    /// user.
    test('emits only candidates whose names match', () async {
      // Arrange
      final TestCentral central = TestCentral()
        ..addFakeDevice(
          _device(
            'BOOKOO_SC',
            'ultra',
          ),
        )
        ..addFakeDevice(
          _device(
            'bookoo-ultra',
            'lowercase',
          ),
        )
        ..addFakeDevice(
          _device(
            'Fitness Band',
            'band',
          ),
        )
        ..addFakeDevice(
          _device(
            null,
            'unnamed',
          ),
        )
        ..addFakeDevice(
          _device(
            '',
            'empty',
          ),
        );
      final ThemisUltraClient client = ThemisUltraClient(
        ble: SplendidBleCentral(
          platform: central,
        ),
      );

      // Act
      final List<ThemisUltraDevice> found = await client
          .scan(
            timeout: const Duration(
              milliseconds: 400,
            ),
          )
          .toList();

      // Assert
      expect(
        found.map(
          (d) => d.address,
        ),
        <String>[
          'ultra',
          'lowercase',
        ],
      );
      expect(
        found.first.name,
        'BOOKOO_SC',
      );
      expect(
        found.first.rssi,
        -60,
      );
    });

    /// Custom prefixes let callers adapt when a firmware advertises a different name.
    test('honors custom name prefixes', () async {
      // Arrange
      final TestCentral central = TestCentral()
        ..addFakeDevice(
          _device(
            'BOOKOO_SC',
            'a',
          ),
        )
        ..addFakeDevice(
          _device(
            'Themis Ultra',
            'b',
          ),
        );
      final ThemisUltraClient client = ThemisUltraClient(
        ble: SplendidBleCentral(
          platform: central,
        ),
        advertisedNamePrefixes: <String>[
          'themis',
        ],
      );

      // Act
      final List<ThemisUltraDevice> found = await client
          .scan(
            timeout: const Duration(
              milliseconds: 400,
            ),
          )
          .toList();

      // Assert
      expect(
        found.map(
          (d) => d.address,
        ),
        <String>[
          'b',
        ],
      );
    });

    /// A disabled adapter must surface as a typed error, not a silent empty scan.
    test('reports a disabled adapter', () async {
      // Arrange
      final TestCentral central = TestCentral(
        adapterStatus: BluetoothStatus.disabled,
      );
      final ThemisUltraClient client = ThemisUltraClient(
        ble: SplendidBleCentral(
          platform: central,
        ),
      );

      // Act and assert
      await expectLater(
        client.scan(),
        emitsError(
          isA<ThemisBluetoothUnavailableException>(),
        ),
      );
    });

    /// Denied permissions must surface as the same typed error.
    test('reports denied permissions', () async {
      // Arrange
      final TestCentral central = TestCentral(
        permissionStatus: BluetoothPermissionStatus.denied,
      );
      final ThemisUltraClient client = ThemisUltraClient(
        ble: SplendidBleCentral(
          platform: central,
        ),
      );

      // Act and assert
      await expectLater(
        client.scan(),
        emitsError(
          isA<ThemisBluetoothUnavailableException>(),
        ),
      );
    });
  });

  /// Connection behavior: success, GATT verification, and failure cleanup.
  group('connect', () {
    const ThemisUltraDevice device = ThemisUltraDevice(
      name: 'BOOKOO_SC',
      address: _ultraAddress,
      rssi: -60,
    );

    /// Builds a client over [central].
    ThemisUltraClient clientFor(
      TestCentral central,
    ) {
      return ThemisUltraClient(
        ble: SplendidBleCentral(
          platform: central,
        ),
        connectTimeout: const Duration(
          milliseconds: 300,
        ),
        discoveryTimeout: const Duration(
          milliseconds: 300,
        ),
      );
    }

    /// A device with the expected layout must connect and expose its characteristics, whatever UUID format the platform
    /// reports.
    test('connects to a valid device', () async {
      // Arrange
      final TestCentral central = TestCentral()
        ..setServices(
          _ultraAddress,
          _validServices(),
        );

      // Act
      final ThemisUltra scale = await clientFor(
        central,
      ).connect(device);

      // Assert
      expect(
        scale.device,
        device,
      );
      expect(
        ThemisUltraGatt.uuidsMatch(
          scale.commandCharacteristic.uuid,
          ThemisUltraGatt.commandCharacteristicUuid,
        ),
        isTrue,
      );
      expect(
        ThemisUltraGatt.uuidsMatch(
          scale.weightCharacteristic.uuid,
          ThemisUltraGatt.weightCharacteristicUuid,
        ),
        isTrue,
      );
      expect(
        scale.services,
        hasLength(
          1,
        ),
      );
      expect(
        central.disconnectedAddresses,
        isEmpty,
      );
    });

    /// A device without the Themis service must be rejected and released.
    test('rejects a device missing the service', () async {
      // Arrange
      final TestCentral central = TestCentral()
        ..setServices(
          _ultraAddress,
          <BleService>[
            BleService(
              serviceUuid: '180F',
              characteristics: <BleCharacteristic>[],
            ),
          ],
        );

      // Act
      final Future<ThemisUltra> result = clientFor(
        central,
      ).connect(device);

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<ThemisUnsupportedDeviceException>().having(
            (e) => e.problems.single,
            'problem',
            contains(
              'missing service',
            ),
          ),
        ),
      );
      expect(
        central.disconnectedAddresses,
        <String>[
          _ultraAddress,
        ],
      );
    });

    /// Each missing characteristic must be named in a single report.
    test('rejects a device missing characteristics', () async {
      // Arrange
      final TestCentral central = TestCentral()
        ..setServices(
          _ultraAddress,
          <BleService>[
            BleService(
              serviceUuid: '0FFE',
              characteristics: <BleCharacteristic>[],
            ),
          ],
        );

      // Act
      final Future<ThemisUltra> result = clientFor(
        central,
      ).connect(device);

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<ThemisUnsupportedDeviceException>().having(
            (e) => e.problems,
            'problems',
            hasLength(2),
          ),
        ),
      );
      expect(
        central.disconnectedAddresses,
        <String>[
          _ultraAddress,
        ],
      );
    });

    /// A characteristic that exists but lacks the needed capability is just as unusable as a missing one.
    test('rejects characteristics lacking write or notify support', () async {
      // Arrange
      final TestCentral central = TestCentral()
        ..setServices(
          _ultraAddress,
          <BleService>[
            BleService(
              serviceUuid: '0FFE',
              characteristics: <BleCharacteristic>[
                _characteristic('FF11', <BleCharacteristicProperty>[
                  BleCharacteristicProperty.read,
                ]),
                _characteristic('FF12', <BleCharacteristicProperty>[
                  BleCharacteristicProperty.read,
                ]),
              ],
            ),
          ],
        );

      // Act
      final Future<ThemisUltra> result = clientFor(
        central,
      ).connect(device);

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<ThemisUnsupportedDeviceException>().having(
            (e) => e.problems,
            'problems',
            <String>[
              'command characteristic FF12 is not writable',
              'weight characteristic FF11 cannot notify',
            ],
          ),
        ),
      );
    });

    /// A platform-reported failure must carry its detail to the caller.
    test('reports a platform connection failure', () async {
      // Arrange
      const BleConnectionFailure failure = BleConnectionFailure(
        category: BleConnectionFailureCategory.timeout,
      );
      final TestCentral central = TestCentral(
        connectionEvents: <BleConnectionEvent>[
          const BleConnectionEvent(
            state: BleConnectionState.failed,
            failure: failure,
          ),
        ],
      );

      // Act
      final Future<ThemisUltra> result = clientFor(
        central,
      ).connect(device);

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<ThemisConnectionException>().having(
            (e) => e.failure,
            'failure',
            failure,
          ),
        ),
      );
      expect(
        central.disconnectedAddresses,
        <String>[
          _ultraAddress,
        ],
      );
    });

    /// A scale that never answers must not hang the caller.
    test('times out when the device never connects', () async {
      // Arrange
      final TestCentral central = TestCentral(
        connectionEvents: <BleConnectionEvent>[],
      );

      // Act
      final Future<ThemisUltra> result = clientFor(
        central,
      ).connect(device);

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<ThemisConnectionException>(),
        ),
      );
      expect(
        central.disconnectedAddresses,
        <String>[
          _ultraAddress,
        ],
      );
    });
  });

  /// UUID normalization across the formats platforms report.
  group('ThemisUltraGatt.normalizeUuid', () {
    /// All spellings of the same 16-bit UUID must compare equal.
    test('collapses common formats to the short form', () {
      expect(
        ThemisUltraGatt.normalizeUuid(
          'FF12',
        ),
        'ff12',
      );
      expect(
        ThemisUltraGatt.normalizeUuid(
          '0000FF12',
        ),
        'ff12',
      );
      expect(
        ThemisUltraGatt.normalizeUuid(
          '0000ff12-0000-1000-8000-00805F9B34FB',
        ),
        'ff12',
      );
    });

    /// Vendor UUIDs must not be shortened into a false match.
    test('leaves non-base UUIDs intact', () {
      const String vendor = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
      expect(
        ThemisUltraGatt.normalizeUuid(
          vendor,
        ),
        vendor,
      );
    });
  });
}
