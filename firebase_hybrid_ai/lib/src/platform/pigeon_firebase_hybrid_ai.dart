import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../exceptions/firebase_hybrid_ai_exception.dart';
import '../exceptions/firebase_not_initialized_exception.dart';
import '../exceptions/hybrid_ai_not_supported_exception.dart';
import '../exceptions/on_device_model_unavailable_exception.dart';
import '../firebase_hybrid_ai.dart';
import '../messages.g.dart';
import '../messages.g.dart' as pigeon show downloadOnDeviceModel, streamTextGeneration;
import 'firebase_hybrid_ai_platform.dart';

/// The [FirebaseHybridAiPlatform] implementation for Android and iOS.
///
/// Calls reach the native Firebase AI Logic SDKs through the Pigeon-generated [FirebaseHybridAiHostApi] and event
/// streams. This class translates [PlatformException]s into this plugin's exception types, so that callers do not
/// depend on platform error codes.
class PigeonFirebaseHybridAi extends FirebaseHybridAiPlatform {
  /// Creates the implementation.
  ///
  /// [api], [downloadStream], and [textStream] can be supplied to replace the generated host API and event streams in
  /// tests.
  new({
    @visibleForTesting FirebaseHybridAiHostApi? api,
    @visibleForTesting Stream<OnDeviceModelDownloadProgress> Function(OnDeviceModelCategory category)? downloadStream,
    @visibleForTesting Stream<TextGenerationChunk> Function(String token)? textStream,
  }) : _hostApi = api ?? FirebaseHybridAiHostApi(),
       _downloadStream =
           downloadStream ??
           // The category is the channel's instance name, because event channels cannot take parameters.
           ((OnDeviceModelCategory category) => pigeon.downloadOnDeviceModel(instanceName: category.name)),
       _textStream = textStream ?? ((String token) => pigeon.streamTextGeneration(instanceName: token));

  /// The generated client that sends messages to the native code.
  final FirebaseHybridAiHostApi _hostApi;

  /// Opens the generated event stream that carries download progress for a category from the native code.
  final Stream<OnDeviceModelDownloadProgress> Function(OnDeviceModelCategory category) _downloadStream;

  /// Opens the generated event stream that carries the chunks of the prepared request with a token.
  final Stream<TextGenerationChunk> Function(String token) _textStream;

  @override
  Future<OnDeviceModelStatus> checkOnDeviceStatus({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) async {
    try {
      return await _hostApi.checkOnDeviceStatus(category);
    } on PlatformException catch (exception) {
      throw _exceptionFromPlatform(exception);
    }
  }

  @override
  Future<TextGenerationResult> generateText(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) async {
    try {
      return await _hostApi.generateText(prompt, mode, category, cloudModel);
    } on PlatformException catch (exception) {
      throw _exceptionFromPlatform(exception);
    }
  }

  @override
  Stream<TextGenerationChunk> generateTextStream(
    String prompt, {
    InferenceMode mode = InferenceMode.preferOnDevice,
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
    String cloudModel = FirebaseHybridAi.defaultCloudModel,
  }) async* {
    // Pigeon event channels cannot take parameters, so the host first stores the request and returns a token. The
    // token names the event channel that streams this request. The host call runs when the stream is listened to,
    // so a request that nobody listens to leaves nothing registered on the host.
    final String token;

    try {
      token = await _hostApi.prepareTextStream(prompt, mode, category, cloudModel);
    } on PlatformException catch (exception) {
      throw _exceptionFromPlatform(exception);
    }

    // Errors from the event channel arrive as PlatformExceptions and are translated one by one. Cancelling this
    // stream cancels the event channel subscription, which stops the generation on the host.
    yield* _textStream(token).transform(
      StreamTransformer<TextGenerationChunk, TextGenerationChunk>.fromHandlers(
        handleError: (Object error, StackTrace stackTrace, EventSink<TextGenerationChunk> sink) {
          sink.addError(error is PlatformException ? _exceptionFromPlatform(error) : error, stackTrace);
        },
      ),
    );
  }

  @override
  Stream<OnDeviceModelDownloadProgress> downloadOnDeviceModel({
    OnDeviceModelCategory category = OnDeviceModelCategory.stable,
  }) {
    return _downloadStream(category).transform(
      StreamTransformer<OnDeviceModelDownloadProgress, OnDeviceModelDownloadProgress>.fromHandlers(
        handleError: (Object error, StackTrace stackTrace, EventSink<OnDeviceModelDownloadProgress> sink) {
          sink.addError(error is PlatformException ? _exceptionFromPlatform(error) : error, stackTrace);
        },
      ),
    );
  }

  /// Maps a platform error code to the most specific exception type for it.
  ///
  /// Codes that have no dedicated type become a plain [FirebaseHybridAiException].
  FirebaseHybridAiException _exceptionFromPlatform(PlatformException exception) {
    final String? details = exception.details?.toString();

    switch (exception.code) {
      case 'firebase-not-initialized':
        return FirebaseNotInitializedException(message: exception.message, details: details);
      case 'on-device-unavailable':
        return OnDeviceModelUnavailableException(message: exception.message, details: details);
      case 'unimplemented':
        return HybridAiNotSupportedException(message: exception.message, details: details);
      default:
        return FirebaseHybridAiException(code: exception.code, message: exception.message, details: details);
    }
  }
}
