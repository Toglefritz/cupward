import 'dart:async';
import 'dart:convert';

import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/recipe_ids.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_exception.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_failure.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_parser.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_prompt.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_schema.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_service.dart';
import 'package:cupward/services/recipes/recipe_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import '../brew_feedback/brew_feedback_fixtures.dart';
import 'recipe_generation_fixtures.dart';

/// An auth service that is already signed in, without Firebase.
class _SignedInAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => 'tester';
}

/// An auth service whose sign-in fails, so no save can succeed.
class _OfflineAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => throw Exception('offline');
}

/// An auth service whose sign-in never finishes, so a save never finishes either.
class _StuckAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() => Completer<String>().future;
}

/// Verifies how a recipe is requested, retried with the cloud model, saved under a unique name, and how failures are
/// reported.
void main() {
  late FakeStructuredHybridAi hybridAi;
  late FakeFirebaseFirestore firestore;
  late RecipeRepository recipes;
  late RecipeGenerationService service;

  setUp(() {
    hybridAi = FakeStructuredHybridAi();
    firestore = FakeFirebaseFirestore();
    recipes = RecipeRepository(firestore: firestore, auth: _SignedInAuth());
    service = RecipeGenerationService(hybridAi: hybridAi, recipes: recipes, isSupported: true);
  });

  /// Returns the failure that [request] ends with.
  Future<RecipeGenerationFailure> failureOf(Future<BrewRecipe> request) async {
    try {
      await request;
    } on RecipeGenerationException catch (error) {
      return error.failure;
    }
    fail('The request was expected to fail.');
  }

  group('RecipeGenerationService', () {
    /// The on-device model is asked first, and the recipe it designs is saved for the user.
    test('creates and saves a recipe', () async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));

      // Act
      final BrewRecipe recipe = await service.createRecipe(RecipeGenerationFixtures.pourOverRequest);

      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.preferOnDevice]);
      expect(hybridAi.prompts.single, contains('"method":"kalitaWave"'));
      expect(recipe.name, 'Bold Morning Kalita');
      expect(await recipes.fetch('bold-morning-kalita'), recipe);
    });

    /// An on-device answer that cannot be brewed is asked of the cloud model, which is held to the schema.
    test('asks the cloud model when the on-device recipe cannot be used', () async {
      // Arrange
      final Map<String, dynamic> unusable = RecipeGenerationFixtures.pourOverAnswer()..['waterGrams'] = 100;
      hybridAi.responses
        ..add(BrewFeedbackFixtures.result(unusable))
        ..add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer(), source: InferenceSource.inCloud));

      // Act
      final BrewRecipe recipe = await service.createRecipe(RecipeGenerationFixtures.pourOverRequest);

      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.preferOnDevice, InferenceMode.onlyInCloud]);
      expect(recipe.waterGrams, 350);
    });

    /// The cloud request tells the model why the on-device answer was rejected, and the first request does not.
    test('tells the cloud model why the on-device recipe was rejected', () async {
      // Arrange
      final Map<String, dynamic> noPours = RecipeGenerationFixtures.pourOverAnswer()
        ..['phases'] = <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'prepare'},
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 50, 'durationSeconds': 40},
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 350},
          <String, dynamic>{'kind': 'complete'},
        ];
      hybridAi.responses
        ..add(BrewFeedbackFixtures.result(noPours))
        ..add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer(), source: InferenceSource.inCloud));

      // Act
      await service.createRecipe(RecipeGenerationFixtures.pourOverRequest);

      // Assert
      expect(hybridAi.prompts.first, isNot(contains('previous answer was rejected')));
      expect(hybridAi.prompts.last, contains('previous answer was rejected'));
      expect(hybridAi.prompts.last, contains('were: bloom, bloom.'));
    });

    /// A cloud answer that still cannot be used is reported rather than retried again.
    test('reports an answer that still cannot be used', () async {
      // Arrange
      hybridAi.responses.add(
        BrewFeedbackFixtures.result(null, source: InferenceSource.inCloud, violations: <String>[r'$.name missing']),
      );

      // Act and assert
      expect(
        await failureOf(service.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.invalidResponse,
      );
      expect(hybridAi.modes, hasLength(1));
    });

    /// Each of a user's recipes needs a unique name, so a taken name gets a number.
    test('numbers the name when it is taken', () async {
      // Arrange
      hybridAi.responses
        ..add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()))
        ..add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      await service.createRecipe(RecipeGenerationFixtures.pourOverRequest);

      // Act
      final BrewRecipe second = await service.createRecipe(RecipeGenerationFixtures.pourOverRequest);

      // Assert
      expect(second.name, 'Bold Morning Kalita 2');
      expect(second.id, 'bold-morning-kalita-2');
      expect(await recipes.fetch('bold-morning-kalita-2'), isNotNull);
    });

    /// Failures are reported in terms the screen can explain.
    test('reports failed, unsupported, and unsaved requests', () async {
      // Arrange
      hybridAi.responses
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(const HybridAiNotSupportedException(message: 'not here'))
        ..add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      final RecipeGenerationService offline = RecipeGenerationService(
        hybridAi: hybridAi,
        recipes: RecipeRepository(firestore: firestore, auth: _OfflineAuth()),
        isSupported: true,
      );

      // Act and assert
      expect(
        await failureOf(service.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.requestFailed,
      );
      expect(
        await failureOf(service.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.unsupported,
      );
      expect(
        await failureOf(offline.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.saveFailed,
      );
    });

    /// iOS and macOS cannot run hybrid inference, so the plugin is not called there.
    test('does not call the plugin where hybrid inference is unsupported', () async {
      final RecipeGenerationService unsupported =
          RecipeGenerationService(hybridAi: hybridAi, recipes: recipes, isSupported: false);

      expect(
        await failureOf(unsupported.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.unsupported,
      );
      expect(hybridAi.modes, isEmpty);
    });

    /// The recipe is saved with its method, so the method is there when it is loaded again.
    test('saves the method with the recipe', () async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.immersionAnswer()));
      // Act
      await service.createRecipe(RecipeGenerationFixtures.immersionRequest);
      // Assert
      final BrewRecipe? stored = await recipes.fetch('sweet-press');
      expect(stored?.method, BrewMethod.frenchPress);
    });

    /// When every numbered name is taken too, the failure says so, rather than blaming the connection.
    test('reports a name that is taken in every numbered form', () async {
      // Arrange
      for (int attempt = 1; attempt <= RecipeGenerationService.maxNameAttempts + 1; attempt++) {
        final String name = attempt == 1 ? 'Bold Morning Kalita' : 'Bold Morning Kalita $attempt';
        await firestore.doc('users/tester/recipes/${RecipeIds.fromName(name)}').set(<String, dynamic>{'name': name});
      }
      hybridAi.responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      // Act and assert
      expect(
        await failureOf(service.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.nameTaken,
      );
    });

    /// A request that never answers is given up on, so the screen does not wait forever.
    test('gives up on a request that takes too long', () async {
      // Arrange
      hybridAi.gate = Completer<void>();
      final RecipeGenerationService impatient = RecipeGenerationService(
        hybridAi: hybridAi,
        recipes: recipes,
        isSupported: true,
        requestTimeout: const Duration(milliseconds: 10),
      );
      // Act and assert
      expect(
        await failureOf(impatient.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.requestFailed,
      );
    });

    /// A save that never finishes is reported as a failed save.
    test('gives up on a save that takes too long', () async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      final RecipeGenerationService impatient = RecipeGenerationService(
        hybridAi: hybridAi,
        recipes: RecipeRepository(firestore: firestore, auth: _StuckAuth()),
        isSupported: true,
        saveTimeout: const Duration(milliseconds: 10),
      );
      // Act and assert
      expect(
        await failureOf(impatient.createRecipe(RecipeGenerationFixtures.pourOverRequest)),
        RecipeGenerationFailure.saveFailed,
      );
    });
  });

  group('RecipeGenerationPrompt', () {
    /// The step pattern the model is given must match the method, so the answer fits the brewing screen.
    test('describes the steps for the method', () {
      final String pourOver = RecipeGenerationPrompt.build(RecipeGenerationFixtures.pourOverRequest);
      final String immersion = RecipeGenerationPrompt.build(RecipeGenerationFixtures.immersionRequest);

      expect(pourOver, contains(RecipeGenerationPrompt.pourOverSteps));
      expect(pourOver, contains('Strong, medium-dark roast'));
      expect(immersion, contains(RecipeGenerationPrompt.immersionSteps));
      expect(immersion, contains('"method":"frenchPress"'));
      expect(immersion.length, lessThan(3000));
      expect(pourOver.length, lessThan(3000));
    });

    /// The required steps are spelled out, with the steps that must not appear, and with an example.
    test('lists the required and forbidden steps and gives an example', () {
      expect(RecipeGenerationPrompt.pourOverSteps, contains('Never use a steep step'));
      expect(RecipeGenerationPrompt.pourOverSteps, contains('Always include the bloom'));
      expect(RecipeGenerationPrompt.pourOverSteps, contains('"kind":"bloom"'));
      expect(RecipeGenerationPrompt.immersionSteps, contains('Never use a bloom step'));
      expect(RecipeGenerationPrompt.immersionSteps, contains('"kind":"steep"'));
    });

    /// The examples in the prompt must be answers that the parser would accept.
    test('gives examples the parser accepts', () {
      final RegExp example = RegExp(r'^\[\{.*\}\]$', multiLine: true);
      for (final (String steps, BrewMethod method, double water) in <(String, BrewMethod, double)>[
        (RecipeGenerationPrompt.pourOverSteps, BrewMethod.v60, 320),
        (RecipeGenerationPrompt.immersionSteps, BrewMethod.frenchPress, 450),
      ]) {
        final List<dynamic> phases = jsonDecode(example.firstMatch(steps)!.group(0)!) as List<dynamic>;
        final BrewRecipe recipe = RecipeGenerationParser.parse(
          <String, dynamic>{
            'name': 'Example',
            'profile': 'Balanced',
            'coffeeGrams': water / 15,
            'waterGrams': water,
            'brewTimeSeconds': 240,
            'yieldMilliliters': water - 40,
            'phases': phases,
          },
          method: method,
        );
        expect(recipe.waterGrams, water);
      }
    });

    /// A rejection reason is added to the prompt only when there is one.
    test('adds the reason for a rejection', () {
      final String plain = RecipeGenerationPrompt.build(RecipeGenerationFixtures.pourOverRequest);
      final String corrected = RecipeGenerationPrompt.build(
        RecipeGenerationFixtures.pourOverRequest,
        rejection: 'Too many blooms.',
      );

      expect(plain, isNot(contains('rejected')));
      expect(corrected, contains('previous answer was rejected: Too many blooms.'));
    });
  });

  group('RecipeGenerationSchema', () {
    /// The model answers with the schema's step names, and the parser reads them back as step kinds.
    test('lists the same step kinds as the app', () {
      expect(RecipeGenerationSchema.phaseKindNames, BrewPhaseKind.values.map((BrewPhaseKind k) => k.name).toList());
    });

    /// Well-formed answers pass the same check the plugin applies.
    test('accepts well-formed answers', () {
      expect(RecipeGenerationSchema.schema.validate(RecipeGenerationFixtures.pourOverAnswer()), isEmpty);
      expect(RecipeGenerationSchema.schema.validate(RecipeGenerationFixtures.immersionAnswer()), isEmpty);
    });
  });

  group('BrewMethod', () {
    /// Immersion methods are the ones that steep, which decides the step pattern.
    test('marks the immersion methods', () {
      expect(
        BrewMethod.values.where((BrewMethod method) => method.isImmersion),
        <BrewMethod>[BrewMethod.frenchPress, BrewMethod.aeroPress, BrewMethod.cleverDripper],
      );
    });
  });
}
