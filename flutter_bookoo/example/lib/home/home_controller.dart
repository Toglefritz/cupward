import 'dart:async';

import 'package:flutter_bookoo/flutter_bookoo.dart';
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

  /// Whether a scan is in progress.
  bool isScanning = false;

  /// Whether a connection attempt is in progress.
  bool isConnecting = false;

  /// The active scan subscription, or null when not scanning.
  StreamSubscription<ThemisUltraDevice>? _scanSubscription;

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

    await current.disconnect();
    _log('Disconnected.');
    setState(() => scale = null);
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
    unawaited(scale?.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
