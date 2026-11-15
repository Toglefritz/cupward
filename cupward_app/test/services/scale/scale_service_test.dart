import 'dart:async';

import 'package:cupward/services/scale/scale_connection_status.dart';
import 'package:cupward/services/scale/scale_failure.dart';
import 'package:cupward/services/scale/scale_service.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';

/// A client that scans and connects without Bluetooth, driven by the test.
class _FakeClient implements ThemisUltraClient {
  /// The scan stream returned by [scan]. Tests add devices and errors to it, and close it to end the scan.
  StreamController<ThemisUltraDevice> scanController = StreamController<ThemisUltraDevice>();

  /// The scale returned by [connect], or null to make [connect] throw [connectError].
  _FakeScale? scale;

  /// What [connect] throws when [scale] is null.
  Exception connectError = const ThemisConnectionException('timed out');

  @override
  Stream<ThemisUltraDevice> scan({Duration timeout = const Duration(seconds: 15)}) => scanController.stream;

  @override
  Future<ThemisUltra> connect(ThemisUltraDevice device) async {
    final _FakeScale? connected = scale;
    if (connected == null) {
      throw connectError;
    }

    return connected;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A connected scale whose readings the test sends.
class _FakeScale implements ThemisUltra {
  /// Creates a scale for [device].
  _FakeScale(this.device);

  @override
  final ThemisUltraDevice device;

  /// The source of [readings]. Closing it simulates the scale disconnecting.
  final StreamController<BookooScaleReading> readingsController = StreamController<BookooScaleReading>.broadcast();

  /// How many times [tare] was called.
  int tareCount = 0;

  @override
  Stream<BookooScaleReading> get readings => readingsController.stream;

  @override
  Future<void> tare() async => tareCount++;

  @override
  Future<void> disconnect() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A scale as it would appear in a scan.
const ThemisUltraDevice _device = ThemisUltraDevice(name: 'BOOKOO_SC 1234', address: 'AA:BB', rssi: -60);

/// A reading of [grams] with an 80 percent battery.
BookooScaleReading _reading(double grams) => BookooScaleReading(
      elapsed: Duration.zero,
      weightGrams: grams,
      flowRateGramsPerSecond: 0,
      batteryPercent: 80,
      standbyTime: const Duration(minutes: 5),
      beepLevel: 3,
      flowSmoothingEnabled: false,
    );

/// Verifies how the scale service moves between statuses as it scans, connects, receives readings, and loses the
/// connection, using fakes in place of Bluetooth.
void main() {
  late _FakeClient client;
  late ScaleService service;

  setUp(() {
    client = _FakeClient();
    service = ScaleService(client: client, isSupported: true);
  });

  tearDown(() => service.dispose());

  group('ScaleService', () {
    /// In a browser there is no Bluetooth, so the screen must be able to say so and the methods must not fail.
    test('reports unsupported and does nothing where Bluetooth is unavailable', () async {
      // Arrange
      final ScaleService unsupported = ScaleService(client: client, isSupported: false);

      // Act
      await unsupported.startScan();

      // Assert
      expect(unsupported.status, ScaleConnectionStatus.unsupported);
      expect(client.scanController.hasListener, isFalse);
      unsupported.dispose();
    });

    /// Scan results arrive as repeated advertisements, so each scale must be listed once with its latest signal.
    test('lists each scale found by a scan once', () async {
      // Act
      await service.startScan();
      client.scanController
        ..add(_device)
        ..add(const ThemisUltraDevice(name: 'BOOKOO_SC 1234', address: 'AA:BB', rssi: -50));
      await pumpEventQueue();

      // Assert
      expect(service.status, ScaleConnectionStatus.scanning);
      expect(service.devices.length, 1);
      expect(service.devices['AA:BB']?.rssi, -50);
    });

    /// A scan that ends on its own must leave the app ready to search again.
    test('returns to disconnected when the scan ends', () async {
      // Arrange
      await service.startScan();

      // Act
      await client.scanController.close();
      await pumpEventQueue();

      // Assert
      expect(service.status, ScaleConnectionStatus.disconnected);
    });

    /// Bluetooth being off is the most likely failure, and the user can fix it, so it must be told apart.
    test('reports Bluetooth being unavailable during a scan', () async {
      // Arrange
      await service.startScan();

      // Act
      client.scanController.addError(const ThemisBluetoothUnavailableException('adapter off'));
      await pumpEventQueue();

      // Assert
      expect(service.status, ScaleConnectionStatus.disconnected);
      expect(service.failure, ScaleFailure.bluetoothUnavailable);
    });

    /// After connecting, the screen shows the scale's live readings.
    test('connects and passes on readings', () async {
      // Arrange
      client.scale = _FakeScale(_device);

      // Act
      final bool connected = await service.connect(_device);
      client.scale!.readingsController.add(_reading(18.4));
      await pumpEventQueue();

      // Assert
      expect(connected, isTrue);
      expect(service.status, ScaleConnectionStatus.connected);
      expect(service.connectedDevice, _device);
      expect(service.reading?.weightGrams, 18.4);
    });

    /// A failed connection must leave the app ready to try again and say why it failed.
    test('reports a failed connection', () async {
      // Act
      final bool connected = await service.connect(_device);

      // Assert
      expect(connected, isFalse);
      expect(service.status, ScaleConnectionStatus.disconnected);
      expect(service.failure, ScaleFailure.connectionFailed);
    });

    /// A scale that turns off mid-brew must not be shown as still connected with a stale weight.
    test('returns to disconnected when the readings end', () async {
      // Arrange
      client.scale = _FakeScale(_device);
      await service.connect(_device);
      client.scale!.readingsController.add(_reading(18.4));
      await pumpEventQueue();

      // Act
      await client.scale!.readingsController.close();
      await pumpEventQueue();

      // Assert
      expect(service.status, ScaleConnectionStatus.disconnected);
      expect(service.reading, isNull);
      expect(service.connectedDevice, isNull);
    });

    /// Tare is the one command the screen sends, so it must reach the scale.
    test('tares the connected scale', () async {
      // Arrange
      client.scale = _FakeScale(_device);
      await service.connect(_device);

      // Act
      await service.tare();

      // Assert
      expect(client.scale!.tareCount, 1);
    });
  });
}
