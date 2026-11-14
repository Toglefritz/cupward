import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_splendid_ble/flutter_splendid_ble.dart';

import 'exceptions/themis_exception.dart';
import 'models/bookoo_scale_reading.dart';
import 'models/themis_ultra_device.dart';
import 'protocol/bookoo_frame_decoder.dart';

/// A connected BOOKOO Themis Ultra whose GATT layout has been verified.
///
/// Instances are created by `ThemisUltraClient.connect`. Holding an instance
/// means the scale exposes the service and characteristics this package needs.
class ThemisUltra {
  /// Creates a connected scale handle.
  ///
  /// Use `ThemisUltraClient.connect` instead of calling this directly, since
  /// it performs the connection and the GATT verification that this type
  /// assumes have already succeeded.
  new({
    required this.device,
    required this.services,
    required this.commandCharacteristic,
    required this.weightCharacteristic,
    required this._ble,
  }) {
    _frames = StreamController<List<int>>.broadcast(onListen: _onFirstListener, onCancel: _onLastListenerCancelled);
  }

  /// The device this handle is connected to.
  final ThemisUltraDevice device;

  /// Every service discovered on the scale, including ones this package does
  /// not use. This is useful for diagnostics.
  final List<BleService> services;

  /// The characteristic that accepts commands such as tare and timer control.
  final BleCharacteristic commandCharacteristic;

  /// The characteristic that notifies weight, flow rate, timer, and battery
  /// data.
  final BleCharacteristic weightCharacteristic;

  /// The BLE central used for platform calls.
  final SplendidBleCentral _ble;

  /// Broadcast stream of raw notification payloads from the weight
  /// characteristic.
  ///
  /// The platform subscription is opened when the first listener attaches to
  /// [rawFrames] or [readings], and closed when the last one cancels.
  late final StreamController<List<int>> _frames;

  /// The platform subscription feeding [_frames], or null when idle.
  ///
  /// Cancelled in [_onLastListenerCancelled].
  // ignore: cancel_subscriptions
  StreamSubscription<BleCharacteristicValue>? _platformSubscription;

  /// Incremented each time the platform subscription is started or torn down,
  /// so a slow start can detect that it was cancelled in the meantime.
  int _subscriptionGeneration = 0;

  /// Whether [disconnect] has been called.
  bool _disconnected = false;

  /// The raw bytes of every notification from the weight characteristic.
  ///
  /// This is a diagnostic stream for capturing frames, for example to build
  /// test fixtures. Use [readings] for decoded values.
  Stream<List<int>> get rawFrames => _frames.stream;

  /// Live measurements from the scale.
  ///
  /// This is a broadcast stream. Listening starts notifications on the scale,
  /// and cancelling the last listener stops them. Frames that fail validation
  /// are dropped, and later frames still arrive. Frames that are valid but not
  /// measurements are ignored.
  ///
  /// Errors from starting the platform subscription are delivered as stream
  /// errors, unchanged from the platform.
  late final Stream<BookooScaleReading> readings = rawFrames.expand((frame) {
    try {
      final BookooScaleReading? reading = BookooFrameDecoder.decode(frame);

      return reading == null ? const <BookooScaleReading>[] : <BookooScaleReading>[reading];
    } on ThemisException catch (error) {
      debugPrint('Dropped frame: $error');
      return const <BookooScaleReading>[];
    }
  });

  /// Opens the platform subscription when the first listener attaches.
  void _onFirstListener() {
    final int generation = ++_subscriptionGeneration;
    unawaited(_startSubscription(generation));
  }

  /// Subscribes to [weightCharacteristic] unless [generation] is stale.
  Future<void> _startSubscription(int generation) async {
    try {
      final Stream<BleCharacteristicValue> stream = await weightCharacteristic.subscribe();
      if (generation != _subscriptionGeneration || _frames.isClosed) {
        // Every listener left while the subscription was starting.
        weightCharacteristic.unsubscribe();
        return;
      }

      _platformSubscription = stream.listen(
        (value) => _frames.add(value.value),
        onError: _frames.addError,
      );
    } on Object catch (error, stackTrace) {
      if (!_frames.isClosed) {
        _frames.addError(error, stackTrace);
      }
    }
  }

  /// Closes the platform subscription when the last listener cancels.
  void _onLastListenerCancelled() {
    _subscriptionGeneration++;
    final StreamSubscription<BleCharacteristicValue>? subscription = _platformSubscription;
    _platformSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
      weightCharacteristic.unsubscribe();
    }
  }

  /// Disconnects from the scale and ends [readings] and [rawFrames].
  ///
  /// The handle should not be used afterward. Connect again with
  /// `ThemisUltraClient.connect` to resume communication. Calling this more
  /// than once has no further effect.
  Future<void> disconnect() async {
    if (_disconnected) {
      return;
    }
    _disconnected = true;

    _onLastListenerCancelled();
    await _frames.close();
    await _ble.disconnect(device.address);
  }

  @override
  String toString() => 'ThemisUltra(device: $device)';
}
