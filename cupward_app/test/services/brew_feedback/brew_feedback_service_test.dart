import 'package:cupward/models/feedback/brew_feedback.dart';
import 'package:cupward/models/feedback/recipe_parameter.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_exception.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_failure.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_service.dart';
import 'package:cupward/services/on_device_model/on_device_model_service.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brew_feedback_fixtures.dart';

/// Verifies how the service asks the hybrid AI system for feedback, falls back to the cloud, and reports failures.
void main() {
  late FakeStructuredHybridAi hybridAi;
  late BrewFeedbackService service;

  setUp(() {
    hybridAi = FakeStructuredHybridAi();
    service = BrewFeedbackService(hybridAi: hybridAi, isSupported: true);
  });

  /// Returns the failure that a request ends with.
  Future<BrewFeedbackFailure> failureOf(Future<BrewFeedback> request) async {
    try {
      await request;
    } on BrewFeedbackException catch (error) {
      return error.failure;
    }
    fail('The request was expected to fail.');
  }

  group('BrewFeedbackService', () {
    /// The on-device model is preferred, so the brew data stays on the device when it can.
    test('asks the on-device model first and reads its answer', () async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));

      // Act
      final BrewFeedback feedback =
          await service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes());

      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.preferOnDevice]);
      expect(feedback.source, InferenceSource.onDevice);
      expect(feedback.primary.parameter, RecipeParameter.coffeeDose);
      expect(feedback.primary.suggestedValue, 21);
      expect(feedback.alternatives, hasLength(2));
    });

    /// On Android the on-device model is only told about the schema, so a mismatch is retried with the cloud model.
    test('asks the cloud model when the on-device answer does not match', () async {
      // Arrange
      hybridAi.responses
        ..add(BrewFeedbackFixtures.result(null, violations: <String>[r'$ must be JSON']))
        ..add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer(), source: InferenceSource.inCloud));

      // Act
      final BrewFeedback feedback =
          await service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes());

      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.preferOnDevice, InferenceMode.onlyInCloud]);
      expect(feedback.source, InferenceSource.inCloud);
    });

    /// A cloud answer is held to the schema, so a mismatch there is not retried.
    test('reports an answer that still does not match', () async {
      // Arrange
      hybridAi.responses.add(
        BrewFeedbackFixtures.result(null, source: InferenceSource.inCloud, violations: <String>[r'$.summary missing']),
      );

      // Act and assert
      expect(
        await failureOf(service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())),
        BrewFeedbackFailure.invalidResponse,
      );
      expect(hybridAi.modes, hasLength(1));
    });

    /// An iPad that cannot run Apple Intelligence has no on-device model, so the request goes straight to the cloud.
    test('asks only the cloud model on a device without an on-device model', () async {
      // Arrange
      final OnDeviceModelService noModel = OnDeviceModelService(isSupported: false);
      addTearDown(noModel.dispose);
      await noModel.checkStatus();
      final BrewFeedbackService cloudOnly =
          BrewFeedbackService(hybridAi: hybridAi, isSupported: true, modelService: noModel);
      hybridAi.responses
          .add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer(), source: InferenceSource.inCloud));
      // Act
      final BrewFeedback feedback =
          await cloudOnly.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes());
      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.onlyInCloud]);
      expect(feedback.source, InferenceSource.inCloud);
    });

    /// An on-device request that fails outright, such as one that times out, is repeated once with the cloud model.
    test('asks the cloud model when the on-device request fails', () async {
      // Arrange
      hybridAi.responses
        ..add(const FirebaseHybridAiException(code: 'generation-failed'))
        ..add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer(), source: InferenceSource.inCloud));
      // Act
      final BrewFeedback feedback =
          await service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes());
      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.preferOnDevice, InferenceMode.onlyInCloud]);
      expect(feedback.source, InferenceSource.inCloud);
    });

    /// A device the plugin cannot serve has nothing to fall back to, so the failure is reported at once.
    test('does not repeat a request that the device does not support', () async {
      // Arrange
      hybridAi.responses.add(const HybridAiNotSupportedException(message: 'needs iOS 26'));
      // Act and assert
      expect(
        await failureOf(service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())),
        BrewFeedbackFailure.unsupported,
      );
      expect(hybridAi.modes, hasLength(1));
    });

    /// A request that already went to the cloud is not sent there a second time.
    test('does not repeat a cloud request that fails', () async {
      // Arrange
      final OnDeviceModelService noModel = OnDeviceModelService(isSupported: false);
      addTearDown(noModel.dispose);
      await noModel.checkStatus();
      final BrewFeedbackService cloudOnly =
          BrewFeedbackService(hybridAi: hybridAi, isSupported: true, modelService: noModel);
      hybridAi.responses.add(const FirebaseHybridAiException(code: 'network'));
      // Act and assert
      expect(
        await failureOf(cloudOnly.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())),
        BrewFeedbackFailure.requestFailed,
      );
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.onlyInCloud]);
    });

    /// Plugin failures are reported in terms the screen can explain.
    test('reports failed and unsupported requests', () async {
      // Arrange
      hybridAi.responses
        // The on-device request and the cloud request that follows it both fail.
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(const HybridAiNotSupportedException(message: 'not here'));

      // Act and assert
      expect(
        await failureOf(service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())),
        BrewFeedbackFailure.requestFailed,
      );
      expect(
        await failureOf(service.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())),
        BrewFeedbackFailure.unsupported,
      );
    });

    /// macOS and the other desktop platforms cannot run hybrid inference, so the plugin is not called there.
    test('does not call the plugin where hybrid inference is unsupported', () async {
      // Arrange
      final BrewFeedbackService unsupported = BrewFeedbackService(hybridAi: hybridAi, isSupported: false);

      // Act and assert
      expect(
        await failureOf(unsupported.requestFeedback(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())),
        BrewFeedbackFailure.unsupported,
      );
      expect(hybridAi.modes, isEmpty);
    });
  });
}
