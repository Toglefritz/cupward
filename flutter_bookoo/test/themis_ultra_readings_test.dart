/// Tests for the live reading stream on `ThemisUltra`.
///
/// A connected scale is created through `ThemisUltraClient.connect` over a
/// `TestCentral`. Notifications are pushed through the fake as if the scale had
/// sent them, so no hardware is involved.
library;

import 'dart:async';

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_splendid_ble/central/central_platform_interface.dart';
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
  /// it, because characteristic subscriptions go through the singleton.
  setUp(() async {
    central = TestCentral()..setServices(_address, _services());
    CentralPlatformInterface.instance = central;
    final ThemisUltraClient client = ThemisUltraClient(ble: SplendidBleCentral(platform: central));
    scale = await client.connect(const ThemisUltraDevice(name: 'BOOKOO_SC', address: _address, rssi: -50));
  });

  /// Reading delivery and malformed frame handling.
  group('readings', () {
    /// Decoded values must reach listeners in order.
    test('emits decoded readings', () async {
      // Arrange
      final List<BookooScaleReading> received = <BookooScaleReading>[];
      final StreamSubscription<BookooScaleReading> subscription = scale.readings.listen(received.add);
      await pumpEventQueue();

      // Act
      central
        ..emitNotification(buildMeasurementFrame(weightHundredths: 1000, flowHundredths: 150))
        ..emitNotification(buildMeasurementFrame(weightHundredths: 2000, flowHundredths: 200));
      await pumpEventQueue();

      // Assert
      expect(received.map((r) => r.weightGrams), <double>[10, 20]);
      expect(received.first.flowRateGramsPerSecond, 1.5);
      await subscription.cancel();
    });

    /// The core resilience requirement: one bad frame of each kind must not
    /// stop the stream, and the next valid frame must still arrive.
    test('drops malformed frames and still delivers a later valid frame', () async {
      // Arrange
      final List<BookooScaleReading> received = <BookooScaleReading>[];
      final List<Object> errors = <Object>[];
      final StreamSubscription<BookooScaleReading> subscription = scale.readings.listen(
        received.add,
        onError: errors.add,
      );
      await pumpEventQueue();

      final List<int> badChecksum = buildMeasurementFrame(weightHundredths: 999)..[19] ^= 0xFF;
      final List<int> truncated = buildMeasurementFrame(weightHundredths: 999).sublist(0, 9);

      // Act
      central
        ..emitNotification(truncated)
        ..emitNotification(badChecksum)
        ..emitNotification(<int>[])
        ..emitNotification(buildMeasurementFrame(weightHundredths: 4200));
      await pumpEventQueue();

      // Assert
      expect(errors, isEmpty);
      expect(received, hasLength(1));
      expect(received.single.weightGrams, 42);
      await subscription.cancel();
    });

    /// Frames of other message types must be skipped without error.
    test('ignores valid non-measurement frames', () async {
      // Arrange
      final List<BookooScaleReading> received = <BookooScaleReading>[];
      final StreamSubscription<BookooScaleReading> subscription = scale.readings.listen(received.add);
      await pumpEventQueue();
      final List<int> powder = buildMeasurementFrame()..[1] = 0x0F;
      powder[19] = BookooFrameDecoder.checksum(powder);

      // Act
      central
        ..emitNotification(powder)
        ..emitNotification(buildMeasurementFrame(weightHundredths: 100));
      await pumpEventQueue();

      // Assert
      expect(received, hasLength(1));
      await subscription.cancel();
    });
  });

  /// Platform subscription lifecycle.
  group('subscription lifecycle', () {
    /// Several listeners must share one platform subscription, and the last
    /// one leaving must release it.
    test('shares one platform subscription and releases it', () async {
      // Act
      final StreamSubscription<BookooScaleReading> first = scale.readings.listen((_) {});
      final StreamSubscription<List<int>> second = scale.rawFrames.listen((_) {});
      await pumpEventQueue();

      // Assert
      expect(central.subscribeCount, 1);

      // Act
      await first.cancel();
      expect(central.unsubscribeCount, 0);
      await second.cancel();
      await pumpEventQueue();

      // Assert
      expect(central.unsubscribeCount, 1);
    });

    /// Raw frames must be the exact bytes sent, for fixture capture.
    test('rawFrames exposes unmodified bytes', () async {
      // Arrange
      final List<List<int>> received = <List<int>>[];
      final StreamSubscription<List<int>> subscription = scale.rawFrames.listen(received.add);
      await pumpEventQueue();
      final List<int> frame = buildMeasurementFrame(weightHundredths: 123);

      // Act
      central.emitNotification(frame);
      await pumpEventQueue();

      // Assert
      expect(received.single, frame);
      await subscription.cancel();
    });

    /// Disconnecting must end the streams so listeners are not left waiting.
    test('disconnect closes the streams', () async {
      // Arrange
      final Completer<void> done = Completer<void>();
      scale.readings.listen((_) {}, onDone: done.complete);
      await pumpEventQueue();

      // Act
      await scale.disconnect();

      // Assert
      await done.future.timeout(const Duration(seconds: 1));
      expect(central.disconnectedAddresses, <String>[_address]);
    });
  });
}
