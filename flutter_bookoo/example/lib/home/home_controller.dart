import 'dart:async';

import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';
import 'package:material_ui/material_ui.dart';

import 'home_route.dart';
import 'home_view.dart';

/// State and actions for [HomeRoute].
///
/// Owns a [ThemisUltraClient], the list of scan results, the connected scale, and a running log that is shown on screen
/// so hardware checks can be read without a debugger.
class HomeController extends State<HomeRoute> {
  /// The client under test.
  final ThemisUltraClient client = ThemisUltraClient();

  /// Scan results keyed by device address, holding the latest advertisement.
  final Map<String, ThemisUltraDevice> devices = <String, ThemisUltraDevice>{};

  /// Messages describing what the app and package have done, oldest first.
  final List<String> logLines = <String>[];

  /// The connected scale, or null when not connected.
  ThemisUltra? scale;

  /// The latest reading from the connected scale, or null before the first.
  BookooScaleReading? reading;

  /// Whether raw frames are currently being recorded for fixtures.
  bool isCapturing = false;

  /// Hex-encoded raw frames recorded while [isCapturing], one per entry.
  final List<String> capturedFrames = <String>[];

  /// Whether a scan is in progress.
  bool isScanning = false;

  /// Whether a connection attempt is in progress.
  bool isConnecting = false;

  /// The active scan subscription, or null when not scanning.
  StreamSubscription<ThemisUltraDevice>? _scanSubscription;

  /// The subscription to decoded readings, or null when not connected.
  StreamSubscription<BookooScaleReading>? _readingSubscription;

  /// The subscription to raw frames, or null when not connected.
  StreamSubscription<List<int>>? _frameSubscription;

  /// Starts a scan, replacing any previous results.
  void onScanPressed() {
    if (isScanning) {
      return;
    }

    setState(() {
      devices.clear();
      isScanning = true;
    });
    _log('Scanning for BOOKOO devices.');

    _scanSubscription = client.scan().listen(
      (ThemisUltraDevice device) {
        _log('Found ${device.name} (${device.address}), RSSI ${device.rssi}.');
        setState(() => devices[device.address] = device);
      },
      onError: (Object error) {
        _log('Scan error: $error');
        setState(() => isScanning = false);
      },
      onDone: () {
        _log('Scan finished with ${devices.length} candidate(s).');
        setState(() => isScanning = false);
      },
    );
  }

  /// Connects to [device], then logs the services and characteristics found.
  Future<void> onDeviceSelected(ThemisUltraDevice device) async {
    if (isConnecting || scale != null) {
      return;
    }

    await _scanSubscription?.cancel();
    setState(() {
      isScanning = false;
      isConnecting = true;
    });
    _log('Connecting to ${device.name}.');

    try {
      final ThemisUltra connected = await client.connect(device);
      _log('Connected. GATT layout verified.');
      _logServices(connected.services);
      setState(() => scale = connected);
      _startListening(connected);
    } on ThemisException catch (error) {
      _log('Connect failed: $error');
    } finally {
      if (mounted) {
        setState(() => isConnecting = false);
      }
    }
  }

  /// Disconnects from the current scale.
  Future<void> onDisconnectPressed() async {
    final ThemisUltra? current = scale;
    if (current == null) {
      return;
    }

    await _stopListening();
    await current.disconnect();
    _log('Disconnected.');
    setState(() {
      scale = null;
      reading = null;
      isCapturing = false;
    });
  }

  /// Toggles recording of raw frames. Starting a capture clears earlier frames.
  void onCaptureToggled() {
    setState(() {
      isCapturing = !isCapturing;
      if (isCapturing) {
        capturedFrames.clear();
      }
    });

    _log(
      isCapturing
          ? 'Capture started.'
          : 'Capture stopped with ${capturedFrames.length} frame(s).',
    );
  }

  /// Copies the captured frames to the clipboard, one hex frame per line.
  ///
  /// This is the format read by the fixture test in `test/fixtures/frames`.
  Future<void> onCopyFramesPressed() async {
    await Clipboard.setData(ClipboardData(text: capturedFrames.join('\n')));
    _log('Copied ${capturedFrames.length} frame(s) to the clipboard.');
  }

  /// Starts listening to decoded readings and raw frames from [connected].
  void _startListening(ThemisUltra connected) {
    _readingSubscription = connected.readings.listen(
      (BookooScaleReading value) => setState(() => reading = value),
      onError: (Object error) => _log('Reading error: $error'),
    );

    _frameSubscription = connected.rawFrames.listen((List<int> frame) {
      if (isCapturing) {
        capturedFrames.add(_toHex(frame));
      }
    }, onError: (Object error) => debugPrint('Raw frame error: $error'));
  }

  /// Cancels the reading and frame subscriptions.
  Future<void> _stopListening() async {
    await _readingSubscription?.cancel();
    await _frameSubscription?.cancel();
    _readingSubscription = null;
    _frameSubscription = null;
  }

  /// Formats [bytes] as lowercase hex with no separators.
  String _toHex(List<int> bytes) {
    return bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Writes every service, characteristic, and its properties to the log.
  void _logServices(List<BleService> services) {
    for (final BleService service in services) {
      _log('Service ${service.serviceUuid}');
      for (final BleCharacteristic characteristic in service.characteristics) {
        final String properties = characteristic.properties
            .map((BleCharacteristicProperty property) => property.name)
            .join(', ');
        _log('  ${characteristic.uuid} [$properties]');
      }
    }
  }

  /// Appends [message] to the on-screen log and the debug console.
  void _log(String message) {
    debugPrint(message);
    if (mounted) {
      setState(() => logLines.add(message));
    }
  }

  @override
  void dispose() {
    unawaited(_scanSubscription?.cancel());
    unawaited(_stopListening());
    unawaited(scale?.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
