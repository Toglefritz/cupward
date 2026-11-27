import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

import '../../models/brews/brew_record.dart';
import '../../models/brews/tasting_notes.dart';
import '../../models/feedback/brew_feedback.dart';
import '../hybrid_ai/hybrid_ai_support.dart';
import '../on_device_model/on_device_model_service.dart';
import 'brew_feedback_exception.dart';
import 'brew_feedback_failure.dart';
import 'brew_feedback_parser.dart';
import 'brew_feedback_prompt.dart';
import 'brew_feedback_schema.dart';

/// Asks the hybrid AI system for feedback on a brew, in the shape of `BrewFeedbackSchema`.
///
/// The request prefers the on-device model, so the brew data stays on the device when it can, and falls back to the
/// cloud model otherwise. A device that is known to have no on-device model goes straight to the cloud model, and if
/// the on-device request fails outright the request is repeated once with the cloud model. On Android the on-device model cannot be held to a schema, only told about it, so its answer
/// may not match. When an on-device answer does not match, the request is repeated once with the cloud model, which is
/// held to the schema on every platform.
///
/// Hybrid inference runs on Android, iOS, and in the browser. On other platforms the plugin does not support it, so
/// [isSupported] is false there and every request fails with [BrewFeedbackFailure.unsupported]. A device that is too
/// old for the plugin, such as an iPad before iOS 26, fails the same way.
class BrewFeedbackService {
  /// Creates a service.
  ///
  /// [hybridAi] defaults to a real `FirebaseHybridAi`, [isSupported] to whether the plugin runs on this platform, and
  /// [modelService] to the app's shared `OnDeviceModelService`, which says whether the device has an on-device model.
  /// Tests supply their own.
  BrewFeedbackService({FirebaseHybridAi? hybridAi, bool? isSupported, OnDeviceModelService? modelService})
      : _hybridAi = hybridAi ?? FirebaseHybridAi(),
        _modelService = modelService,
        isSupported = isSupported ?? HybridAiSupport.isPlatformSupported;

  /// The plugin that runs the requests.
  final FirebaseHybridAi _hybridAi;

  /// Tells whether the device has an on-device model, or null to use the app's shared service.
  final OnDeviceModelService? _modelService;

  /// Whether the platform can run hybrid inference.
  final bool isSupported;

  /// Returns feedback on [record], informed by the user's [notes].
  ///
  /// Throws a [BrewFeedbackException] if the feedback cannot be produced.
  Future<BrewFeedback> requestFeedback(BrewRecord record, TastingNotes notes) async {
    if (!isSupported) {
      throw const BrewFeedbackException(BrewFeedbackFailure.unsupported);
    }

    final String prompt = BrewFeedbackPrompt.build(record, notes);

    StructuredGenerationResult result = await _generateWithCloudFallback(prompt);
    if (!result.conformsToSchema && result.source == InferenceSource.onDevice) {
      debugPrint('On-device brew feedback did not match the schema, so the cloud model is asked: ${result.violations}');
      result = await _generate(prompt, InferenceMode.onlyInCloud);
    }

    if (!result.conformsToSchema) {
      debugPrint('Brew feedback did not match the schema: ${result.violations}');
      throw const BrewFeedbackException(BrewFeedbackFailure.invalidResponse);
    }

    try {
      return BrewFeedbackParser.parse(result.data, recipe: record.recipe, source: result.source);
    } on FormatException catch (error) {
      debugPrint('Brew feedback could not be read: $error');
      throw const BrewFeedbackException(BrewFeedbackFailure.invalidResponse);
    }
  }

  /// Sends [prompt] in the mode that suits this device, and asks the cloud model once if the on-device request fails.
  ///
  /// Only a request that was allowed to use the on-device model is repeated. A failure on a device without one, or an
  /// unsupported device, is reported as it is.
  Future<StructuredGenerationResult> _generateWithCloudFallback(String prompt) async {
    final InferenceMode mode = HybridAiSupport.modeFor(_modelService ?? OnDeviceModelService.instance);
    try {
      return await _generate(prompt, mode);
    } on BrewFeedbackException catch (error) {
      if (mode != InferenceMode.preferOnDevice || error.failure != BrewFeedbackFailure.requestFailed) {
        rethrow;
      }
      debugPrint('The on-device brew feedback request failed, so the cloud model is asked.');
      return await _generate(prompt, InferenceMode.onlyInCloud);
    }
  }

  /// Sends [prompt] with the schema in [mode], and turns plugin failures into [BrewFeedbackException]s.
  Future<StructuredGenerationResult> _generate(String prompt, InferenceMode mode) async {
    try {
      return await _hybridAi.generateStructured(prompt, schema: BrewFeedbackSchema.schema, mode: mode);
    } on HybridAiNotSupportedException catch (error) {
      debugPrint('Brew feedback is not supported here: $error');
      throw const BrewFeedbackException(BrewFeedbackFailure.unsupported);
    } on Object catch (error) {
      debugPrint('Brew feedback request failed: $error');
      throw const BrewFeedbackException(BrewFeedbackFailure.requestFailed);
    }
  }
}
