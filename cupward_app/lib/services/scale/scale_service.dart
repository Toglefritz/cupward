import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';

import 'demo_scale_simulator.dart';
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
///
/// In demo mode, started with [startDemo], the service acts as if a scale were connected, on every platform including
/// the web, but its readings come from a [DemoScaleSimulator] instead of Bluetooth. [tare] zeroes the simulated scale,
/// and [simulatePourTo] tells it how much water the brew calls for next, as the person at the kettle would know.
/// [isDemo] says whether demo mode is on, and [stopDemo] or [disconnect] ends it.
class ScaleService extends ChangeNotifier {
  /// Creates a service.
  ///
  /// [client] defaults to a real `ThemisUltraClient`. [isSupported] defaults to whether the app is running outside a
  /// browser. Tests supply both, or subclass the service and override its methods.
  ///
  /// [random] is the source of the small variations in demo readings. Tests supply a seeded one.
  ScaleService({ThemisUltraClient? client, bool? isSupported, Random? random})
      : _client = client,
        _isSupported = isSupported ?? !kIsWeb,
        _random = random,
        _status = (isSupported ?? !kIsWeb) ? ScaleConnectionStatus.disconnected : ScaleConnectionStatus.unsupported;

  /// The service that the app's screens share.
  static final ScaleService instance = ScaleService();

  /// How often the simulated scale sends a reading in demo mode, about as often as the real scale does.
  static const Duration demoReadingInterval = Duration(milliseconds: 100);

  /// Whether the platform can reach a real scale. The status returns to [ScaleConnectionStatus.unsupported] when demo
  /// mode ends if it cannot.
  final bool _isSupported;

  /// The source of randomness for demo readings, or null for an unseeded one.
  final Random? _random;

  /// The simulated scale while demo mode is on, or null when it is off.
  DemoScaleSimulator? _demo;

  /// Sends the simulated scale's readings while demo mode is on.
  Timer? _demoTimer;

  /// Whether demo mode is on, so the readings are simulated rather than coming from a real scale.
  bool get isDemo => _demo != null;

  /// The name recorded with a brew for the simulated scale.
  static const String demoScaleName = 'Cupward demo scale';

  /// The name of the connected scale, the simulated one's in demo mode, or null when none is connected.
  String? get scaleName => isDemo ? demoScaleName : connectedDevice?.name;

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
  /// In demo mode it zeroes the simulated scale.
  Future<void> tare() async {
    final DemoScaleSimulator? demo = _demo;
    if (demo != null) {
      demo.tare();
      return;
    }
    await _scale?.tare();
  }

  /// Disconnects from the connected scale, if there is one, and ends demo mode if it is on.
  Future<void> disconnect() async {
    if (isDemo) {
      stopDemo();
      return;
    }
    final ThemisUltra? scale = _scale;
    await _clearConnection();
    await scale?.disconnect();
  }

  /// Starts demo mode: any real scale is disconnected and any scan stopped, and the service reports a connected scale
  /// whose readings are simulated, with an empty platter on which a brewer is soon set down.
  ///
  /// Does nothing if demo mode is already on. This works on every platform, including those where [status] is
  /// otherwise [ScaleConnectionStatus.unsupported].
  Future<void> startDemo() async {
    if (isDemo) {
      return;
    }
    await stopScan();
    await disconnect();
    final DemoScaleSimulator demo = DemoScaleSimulator(random: _random)..reset();
    _demo = demo;
    _failure = null;
    _demoTimer = Timer.periodic(demoReadingInterval, (Timer _) {
      _reading = demo.advance(demoReadingInterval);
      notifyListeners();
    });
    _setStatus(ScaleConnectionStatus.connected);
  }

  /// Ends demo mode, if it is on, and returns to having no scale connected.
  void stopDemo() {
    if (!isDemo) {
      return;
    }
    _demoTimer?.cancel();
    _demoTimer = null;
    _demo = null;
    _reading = null;
    _setStatus(_isSupported ? ScaleConnectionStatus.disconnected : ScaleConnectionStatus.unsupported);
  }

  /// In demo mode, empties the simulated scale's platter for a new brew. Does nothing otherwise.
  void resetDemo() => _demo?.reset();

  /// In demo mode, pours simulated water until the weight since the tare is about [targetGrams], or holds the weight
  /// if [targetGrams] is null. Does nothing otherwise.
  void simulatePourTo(double? targetGrams) => _demo?.pourTo(targetGrams);

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
    _demoTimer?.cancel();
    unawaited(_scanSubscription?.cancel());
    unawaited(_readingSubscription?.cancel());
    super.dispose();
  }
}
