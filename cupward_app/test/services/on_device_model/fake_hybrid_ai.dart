import 'dart:async';

import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';

/// A stand-in for the plugin that reports the model status and download progress that a test sets.
class FakeHybridAi implements FirebaseHybridAi {
  /// What [checkOnDeviceStatus] returns next, as an availability.
  OnDeviceModelAvailability availability = OnDeviceModelAvailability.downloadable;

  /// What [checkOnDeviceStatus] throws instead of returning, or null to return [availability].
  Exception? checkError;

  /// How many times [checkOnDeviceStatus] was called.
  int checkCount = 0;

  /// The source of the stream that [downloadOnDeviceModel] returns. Tests add progress and errors to it, and close it
  /// to finish the download.
  StreamController<OnDeviceModelDownloadProgress> downloadController =
      StreamController<OnDeviceModelDownloadProgress>();

  /// How many times [downloadOnDeviceModel] was listened to.
  int downloadCount = 0;

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) async {
    checkCount++;
    final Exception? error = checkError;
    if (error != null) {
      throw error;
    }

    return OnDeviceModelStatus(availability: availability);
  }

  @override
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) {
    downloadCount++;

    return downloadController.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
