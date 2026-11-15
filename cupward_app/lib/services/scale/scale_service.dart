import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';

import 'scale_connection_status.dart';
import 'scale_failure.dart';

/// Finds, connects to, and reads from the user's BOOKOO scale, and keeps the connection for the life of the app.
///
/// The connection belongs to the app rather than to one screen, so a scale connected during one brew is still
/// connected when the next brew starts. Screens use the shared [instance], listen to it, and rebuild when it notifies.
/// It notifies when the [status] changes, when scan results change, and with every new [reading], which the scale
/// sends about ten times a second.
///
/// All Bluetooth work goes through `flutter_bookoo`. Its Bluetooth plugin has no web implementation, so in a browser
/// the status is [ScaleConnectionStatus.unsupported] and the other methods do nothing.
class ScaleService extends ChangeNotifier {
  /// Creates a service.
  ///
  /// [client] defaults to a real `ThemisUltraClient`. [isSupported] defaults to whether the app is running outside a
  /// browser. Tests supply both, or subclass the service and override its methods.
  ScaleService({ThemisUltraClient? client, bool? isSupported})
      : _client = client,
        _status = (isSupported ?? !kIsWeb) ? ScaleConnectionStatus.disconnected : ScaleConnectionStatus.unsupported;

  /// The service that the app's screens share.
  static final ScaleService instance = ScaleService();

  /// The client that scans and connects, created on first use so that nothing touches Bluetooth until it is needed.
  ThemisUltraClient? _client;

  /// The client, created the first time it is needed.
  ThemisUltraClient get _scaleClient => _client ??= ThemisUltraClient();

  /// Where the app stands with the scale.
  ScaleConnectionStatus get status => _status;
  ScaleConnectionStatus _status;

  /// The scales found by the current or last scan, by address, with the latest advertisement of each.
  Map<String, ThemisUltraDevice> get devices => Map<String, ThemisUltraDevice>.unmodifiable(_devices);
  final Map<String, ThemisUltraDevice> _devices = <String, ThemisUltraDevice>{};

  /// The connected scale, or null when none is connected.
  ThemisUltraDevice? get connectedDevice => _scale?.device;

  /// The connected scale's handle, or null when none is connected.
  ThemisUltra? _scale;

  /// The latest measurement from the connected scale, or null before the first one arrives and when no scale is
  /// connected.
  BookooScaleReading? get reading => _reading;
  BookooScaleReading? _reading;

  /// Why the last scan or connection attempt failed, or null if it succeeded. It is cleared by the next attempt.
  ScaleFailure? get failure => _failure;
  ScaleFailure? _failure;

  /// The running scan, or null when none is running.
  StreamSubscription<ThemisUltraDevice>? _scanSubscription;

  /// The connected scale's readings, or null when none is connected.
  StreamSubscription<BookooScaleReading>? _readingSubscription;

  /// Whether a scale is connected.
  bool get isConnected => _status == ScaleConnectionStatus.connected;

  /// Starts looking for nearby scales, clearing the results of any earlier scan.
  ///
  /// Results arrive in [devices]. The scan ends on its own after a timeout, after which the status returns to
  /// [ScaleConnectionStatus.disconnected]. A failure, such as Bluetooth being off or permission being denied, ends the
  /// scan and is reported in [failure]. This does nothing unless the status is
  /// [ScaleConnectionStatus.disconnected].
  Future<void> startScan() async {
    if (_status != ScaleConnectionStatus.disconnected) {
      return;
    }

    _devices.clear();
    _failure = null;
    _setStatus(ScaleConnectionStatus.scanning);

    _scanSubscription = _scaleClient.scan().listen(
      (ThemisUltraDevice device) {
        _devices[device.address] = device;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = _classify(error);
        unawaited(stopScan());
      },
      onDone: () {
        _scanSubscription = null;

        if (_status == ScaleConnectionStatus.scanning) {
          _setStatus(ScaleConnectionStatus.disconnected);
        }
      },
    );
  }

  /// Stops the running scan, if there is one. The results found so far stay in [devices].
  Future<void> stopScan() async {
    final StreamSubscription<ThemisUltraDevice>? subscription = _scanSubscription;
    _scanSubscription = null;

    if (_status == ScaleConnectionStatus.scanning) {
      _setStatus(ScaleConnectionStatus.disconnected);
    }

    await subscription?.cancel();
  }

  /// Connects to [device], which came from a scan, and starts receiving its readings.
  ///
  /// The scan is stopped first, because some platforms connect unreliably while scanning. Returns whether the
  /// connection succeeded. On failure, the status returns to [ScaleConnectionStatus.disconnected] and the reason is in
  /// [failure].
  Future<bool> connect(ThemisUltraDevice device) async {
    if (_status == ScaleConnectionStatus.connecting || _status == ScaleConnectionStatus.connected) {
      return false;
    }

    await stopScan();
    _failure = null;
    _setStatus(ScaleConnectionStatus.connecting);

    try {
      final ThemisUltra scale = await _scaleClient.connect(device);

      _scale = scale;
      _readingSubscription = scale.readings.listen(
        (BookooScaleReading reading) {
          _reading = reading;
          notifyListeners();
        },
        onError: (Object error) => debugPrint('Scale reading error: $error'),
        // The readings end when the scale disconnects, so the app shows that it is no longer connected.
        onDone: _onConnectionLost,
      );
      _setStatus(ScaleConnectionStatus.connected);

      return true;
    } on Object catch (error) {
      _failure = _classify(error);
      _setStatus(ScaleConnectionStatus.disconnected);

      return false;
    }
  }

  /// Zeroes the scale's weight, for example with an empty brewer on it.
  ///
  /// Throws a `ThemisCommandException` if the command cannot be written, and does nothing when no scale is connected.
  Future<void> tare() async {
    await _scale?.tare();
  }

  /// Disconnects from the connected scale, if there is one.
  Future<void> disconnect() async {
    final ThemisUltra? scale = _scale;
    await _clearConnection();
    await scale?.disconnect();
  }

  /// Forgets the connection after its readings end without [disconnect] being called.
  void _onConnectionLost() {
    if (_scale != null) {
      unawaited(_clearConnection());
    }
  }

  /// Stops listening to the connected scale and returns to [ScaleConnectionStatus.disconnected].
  Future<void> _clearConnection() async {
    final StreamSubscription<BookooScaleReading>? subscription = _readingSubscription;
    _readingSubscription = null;
    _scale = null;
    _reading = null;

    if (_status == ScaleConnectionStatus.connected) {
      _setStatus(ScaleConnectionStatus.disconnected);
    }

    await subscription?.cancel();
  }

  /// Changes the status and notifies listeners.
  void _setStatus(ScaleConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  /// The kind of failure that [error] represents. The error itself is written to the debug log.
  static ScaleFailure _classify(Object error) {
    debugPrint('Scale error: $error');

    if (error is ThemisBluetoothUnavailableException) {
      return ScaleFailure.bluetoothUnavailable;
    }

    if (error is ThemisUnsupportedDeviceException) {
      return ScaleFailure.unsupportedDevice;
    }

    return error is ThemisConnectionException ? ScaleFailure.connectionFailed : ScaleFailure.unknown;
  }

  @override
  void dispose() {
    unawaited(_scanSubscription?.cancel());
    unawaited(_readingSubscription?.cancel());
    super.dispose();
  }
}
