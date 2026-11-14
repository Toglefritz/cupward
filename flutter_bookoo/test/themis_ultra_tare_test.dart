/// Tests for `ThemisUltra.tare`.
///
/// A connected scale is created through `ThemisUltraClient.connect` over a
/// `TestCentral`, which records characteristic writes, can fail them on
/// demand, and pushes notifications as if the scale had sent them. No hardware
/// is involved.
library;

import 'dart:async';

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_splendid_ble/central/central_platform_interface.dart';
import 'package:flutter_splendid_ble/central/models/exceptions/bluetooth_write_exception.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frame_builder.dart';
import 'support/test_central.dart';

const String _address = 'AA:BB:CC:DD:EE:01';

/// Builds a valid Themis GATT layout on [_address].
List<BleService> _services() {
  BleCharacteristic characteristic(String uuid, List<BleCharacteristicProperty> properties) {
    return BleCharacteristic(address: _address, uuid: uuid, properties: properties, permissions: null);
  }

  return <BleService>[
    BleService(
      serviceUuid: '0FFE',
      characteristics: <BleCharacteristic>[
        characteristic('FF11', <BleCharacteristicProperty>[BleCharacteristicProperty.notify]),
        characteristic('FF12', <BleCharacteristicProperty>[BleCharacteristicProperty.write]),
      ],
    ),
  ];
}

void main() {
  late TestCentral central;
  late ThemisUltra scale;

  /// Connects a scale over a fresh fake and points the plugin's singleton at
  /// it, because characteristic writes and subscriptions go through the
  /// singleton.
  setUp(() async {
    central = TestCentral()..setServices(_address, _services());
    CentralPlatformInterface.instance = central;
    final ThemisUltraClient client = ThemisUltraClient(ble: SplendidBleCentral(platform: central));
    scale = await client.connect(const ThemisUltraDevice(name: 'BOOKOO_SC', address: _address, rssi: -50));
  });

  /// The write must go to the command characteristic, carry the exact tare
  /// bytes, and use the platform's default (acknowledged) write type.
  test('writes 03 0A 01 00 00 08 to FF12', () async {
    // Act
    await scale.tare();

    // Assert
    expect(central.writes, hasLength(1));
    expect(central.writes.single.characteristicUuid, 'FF12');
    expect(central.writes.single.value, <int>[0x03, 0x0A, 0x01, 0x00, 0x00, 0x08]);
    expect(central.writes.single.writeType, isNull);
  });

  /// A platform write failure must surface as a typed package error.
  test('reports a failed write', () async {
    // Arrange
    central.writeError = BluetoothWriteException('Failed to write BLE characteristic: not connected');

    // Act and assert
    await expectLater(
      scale.tare(),
      throwsA(
        isA<ThemisCommandException>().having(
          (e) => e.message,
          'message',
          contains('not connected'),
        ),
      ),
    );
  });

  /// Commands after disconnecting must fail without reaching the platform.
  test('rejects tare after disconnect', () async {
    // Arrange
    await scale.disconnect();

    // Act and assert
    await expectLater(scale.tare(), throwsA(isA<ThemisCommandException>()));
    expect(central.writes, isEmpty);
  });

  /// Tare and readings share one session: after a tare, the reading stream
  /// keeps running and delivers the near-zero value, then later weight.
  test('readings continue through a tare', () async {
    // Arrange
    final List<BookooScaleReading> received = <BookooScaleReading>[];
    final StreamSubscription<BookooScaleReading> subscription = scale.readings.listen(received.add);
    await pumpEventQueue();
    central.emitNotification(buildMeasurementFrame(weightHundredths: 31250));
    await pumpEventQueue();

    // Act
    await scale.tare();
    central
      ..emitNotification(buildMeasurementFrame(weightHundredths: 3))
      ..emitNotification(buildMeasurementFrame(weightHundredths: 1820));
    await pumpEventQueue();

    // Assert
    expect(received.map((r) => r.weightGrams), <double>[312.5, 0.03, 18.2]);
    expect(central.subscribeCount, 1);
    await subscription.cancel();
  });

  /// A failed tare must not disturb the reading stream, so the app can retry
  /// while still showing live weight.
  test('readings continue after a failed tare', () async {
    // Arrange
    final List<BookooScaleReading> received = <BookooScaleReading>[];
    final StreamSubscription<BookooScaleReading> subscription = scale.readings.listen(received.add);
    await pumpEventQueue();
    central.writeError = BluetoothWriteException('Failed to write BLE characteristic: busy');

    // Act
    await expectLater(scale.tare(), throwsA(isA<ThemisCommandException>()));
    central.writeError = null;
    await scale.tare();
    central.emitNotification(buildMeasurementFrame(weightSign: signMinus, weightHundredths: 2));
    await pumpEventQueue();

    // Assert
    expect(received.single.weightGrams, -0.02);
    expect(central.writes, hasLength(2));
    await subscription.cancel();
  });
}
