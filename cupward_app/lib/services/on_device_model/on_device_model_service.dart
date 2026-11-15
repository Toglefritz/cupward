import 'dart:async';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

import 'on_device_model_state.dart';

/// Checks whether this device can run the on-device AI model, and downloads the model when the user asks.
///
/// The state belongs to the app rather than to one screen, so a download started on the home screen keeps going, and
/// keeps reporting progress, while the user brews. Screens use the shared [instance], listen to it, and rebuild when it
/// notifies.
///
/// All AI work goes through `firebase_hybrid_ai`, which reports the model on Android and in desktop Chrome. On iOS the
/// plugin reports that hybrid inference is not supported, and on macOS it has no implementation, so on those
/// platforms the state is [OnDeviceModelState.unavailable] and feedback comes from the cloud.
class OnDeviceModelService extends ChangeNotifier {
  /// Creates a service.
  ///
  /// [hybridAi] defaults to a real `FirebaseHybridAi`. [isSupported] defaults to whether the platform can report an
  /// on-device model at all, which is every platform except macOS. [pollInterval] sets how often the service checks
  /// again while a download that it did not start is in progress. Tests supply all three.
  OnDeviceModelService({
    FirebaseHybridAi? hybridAi,
    bool? isSupported,
    this.pollInterval = const Duration(seconds: 5),
  })  : _hybridAi = hybridAi ?? FirebaseHybridAi(),
        _isSupported = isSupported ?? (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS);

  /// The service that the app's screens share.
  static final OnDeviceModelService instance = OnDeviceModelService();

  /// The plugin that reports and downloads the model.
  final FirebaseHybridAi _hybridAi;

  /// Whether the platform can report an on-device model.
  final bool _isSupported;

  /// How often the service checks again while a download that it did not start is in progress.
  final Duration pollInterval;

  /// Where the app stands with the model.
  OnDeviceModelState get state => _state;
  OnDeviceModelState _state = OnDeviceModelState.checking;

  /// Whether [checkStatus] has finished at least once.
  bool get hasChecked => _hasChecked;
  bool _hasChecked = false;

  /// How much of the model has downloaded, from 0.0 to 1.0, or null when the platform has not reported progress, such
  /// as for a download that another app started.
  double? get downloadProgress => _downloadProgress;
  double? _downloadProgress;

  /// Whether the last download failed. It is cleared when the next download starts.
  bool get didDownloadFail => _didDownloadFail;
  bool _didDownloadFail = false;

  /// The running download, or null when none is running.
  StreamSubscription<OnDeviceModelDownloadProgress>? _downloadSubscription;

  /// Checks again while a download that this service did not start is in progress, or null otherwise.
  Timer? _pollTimer;

  /// Whether a check is running, so that overlapping checks do not race.
  bool _isRefreshing = false;

  /// Whether [dispose] has been called, after which a check that was already running must not notify.
  bool _isDisposed = false;

  /// Checks whether the device has the model, and updates [state].
  ///
  /// The state is [OnDeviceModelState.checking] while the check runs. This does nothing while a download started by
  /// [download] is running, because the download reports its own progress.
  Future<void> checkStatus() async {
    if (_downloadSubscription != null) {
      return;
    }

    _setState(OnDeviceModelState.checking);
    await _refresh();
  }

  /// Starts downloading the model, and reports progress through [downloadProgress].
  ///
  /// Call this directly from a user's tap. Chrome only starts a download in response to a user action, so the
  /// download must begin before the handler returns. When the download finishes, the service checks the model again.
  /// If it fails, the state returns to [OnDeviceModelState.downloadable] and [didDownloadFail] is true. This does
  /// nothing unless the state is [OnDeviceModelState.downloadable].
  void download() {
    if (_state != OnDeviceModelState.downloadable) {
      return;
    }

    _didDownloadFail = false;
    _downloadProgress = 0;
    _setState(OnDeviceModelState.downloading);

    _downloadSubscription = _hybridAi.downloadOnDeviceModel().listen(
      (OnDeviceModelDownloadProgress progress) {
        _downloadProgress = progress.fraction.clamp(0, 1);
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('On-device model download failed: $error');
        _downloadSubscription = null;
        _downloadProgress = null;
        _didDownloadFail = true;
        _setState(OnDeviceModelState.downloadable);
      },
      onDone: () {
        _downloadSubscription = null;
        // The state stays at downloading until the check confirms that the model is installed.
        unawaited(_refresh());
      },
      cancelOnError: true,
    );
  }

  /// Asks the platform for the model's status and updates [state] to match.
  Future<void> _refresh() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    final OnDeviceModelState next = await _fetchState();
    _isRefreshing = false;
    if (_isDisposed) {
      return;
    }

    _hasChecked = true;

    if (next != OnDeviceModelState.downloading) {
      _downloadProgress = null;
    }

    _updatePolling(next);
    _setState(next);
  }

  /// Returns the state that the platform reports for the model.
  Future<OnDeviceModelState> _fetchState() async {
    if (!_isSupported) {
      return OnDeviceModelState.unavailable;
    }

    try {
      final OnDeviceModelStatus status = await _hybridAi.checkOnDeviceStatus();

      switch (status.availability) {
        case OnDeviceModelAvailability.available:
          return OnDeviceModelState.available;
        case OnDeviceModelAvailability.downloadable:
          return OnDeviceModelState.downloadable;
        case OnDeviceModelAvailability.downloading:
          return OnDeviceModelState.downloading;
        case OnDeviceModelAvailability.unavailable:
          return OnDeviceModelState.unavailable;
      }
    } on HybridAiNotSupportedException catch (error) {
      debugPrint('On-device model not supported: $error');

      return OnDeviceModelState.unavailable;
    } on Object catch (error) {
      debugPrint('On-device model check failed: $error');

      return OnDeviceModelState.unknown;
    }
  }

  /// Starts checking again at [pollInterval] while a download that this service did not start is in progress, and
  /// stops otherwise.
  ///
  /// Such a download does not report progress to this app, so checking again is the only way to notice that it has
  /// finished.
  void _updatePolling(OnDeviceModelState next) {
    if (next == OnDeviceModelState.downloading && _downloadSubscription == null) {
      _pollTimer ??= Timer.periodic(pollInterval, (Timer timer) => unawaited(_refresh()));
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Changes the state and notifies listeners.
  void _setState(OnDeviceModelState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollTimer?.cancel();
    unawaited(_downloadSubscription?.cancel());
    super.dispose();
  }
}
