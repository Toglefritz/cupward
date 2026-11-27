import 'dart:async';

import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/suggestions/components/alternative_suggestion_card.dart';
import 'package:cupward/screens/suggestions/components/primary_suggestion_card.dart';
import 'package:cupward/screens/suggestions/suggestions_route.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_service.dart';
import 'package:cupward/services/recipes/recipe_repository.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/brew_feedback/brew_feedback_fixtures.dart';

/// An auth service that is already signed in, without Firebase.
class _SignedInAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => 'tester';
}

/// The path of the tester's copy of the default recipe.
final String _recipePath = 'users/tester/recipes/${BuiltInRecipes.defaultRecipe.id}';

/// Verifies what the brew feedback screen shows while it waits, once feedback arrives, and when it fails.
void main() {
  late FakeStructuredHybridAi hybridAi;
  late FakeFirebaseFirestore firestore;
  late RecipeRepository recipes;

  setUp(() async {
    hybridAi = FakeStructuredHybridAi();
    firestore = FakeFirebaseFirestore();
    recipes = RecipeRepository(firestore: firestore, auth: _SignedInAuth());
    await recipes.create(BuiltInRecipes.defaultRecipe);
  });

  /// Opens the screen from a home screen, with a service that is [supported] or not, at the given [width].
  Future<void> showScreen(WidgetTester tester, {bool supported = true, double width = 412}) async {
    tester.view.physicalSize = Size(width, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => SuggestionsRoute(
                  record: BrewFeedbackFixtures.brew(),
                  notes: BrewFeedbackFixtures.notes(),
                  feedbackService: BrewFeedbackService(hybridAi: hybridAi, isSupported: supported),
                  recipeRepository: recipes,
                ),
              ),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pump();
  }

  group('SuggestionsRoute', () {
    /// The request runs as soon as the screen opens, and the screen says what it is doing.
    testWidgets('shows progress, then the feedback', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));

      // Act
      await showScreen(tester);

      // Assert: the request is sent with the brew data.
      expect(hybridAi.prompts.single, contains('"goal":"Sweeter and fuller."'));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Your next brew'), findsOneWidget);
      expect(find.text('On-device AI'), findsOneWidget);
      expect(find.text('TRY THIS NEXT'), findsOneWidget);
      expect(find.byType(PrimarySuggestionCard), findsOneWidget);
      expect(find.text('Coffee · More'), findsOneWidget);
      expect(find.text('20.0 g'), findsOneWidget);
      expect(find.text('21.0 g'), findsOneWidget);
      expect(find.text('Ideas for later brews'), findsOneWidget);
      expect(find.byType(AlternativeSuggestionCard), findsNWidgets(2));
      expect(find.text('Grind size · Finer'), findsOneWidget);
    });

    /// The loading card shows until the answer arrives.
    testWidgets('says it is working while it waits', (WidgetTester tester) async {
      // Arrange
      hybridAi
        ..gate = Completer<void>()
        ..responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer(), source: InferenceSource.inCloud));

      // Act
      await showScreen(tester);
      await tester.pump(const Duration(milliseconds: 400));

      // Assert
      expect(find.text('Tasting your brew'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Act
      hybridAi.gate!.complete();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tasting your brew'), findsNothing);
      expect(find.text('Cloud AI'), findsOneWidget);
    });

    /// A failed request can be repeated from the screen.
    testWidgets('offers to try again after a failure', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses
        // The on-device request fails, and so does the cloud request that follows it.
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));

      // Act
      await showScreen(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No feedback yet'), findsOneWidget);
      expect(find.textContaining("Couldn't get brew feedback"), findsOneWidget);

      // Act
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PrimarySuggestionCard), findsOneWidget);
    });

    /// Where feedback cannot run, trying again would not help, so no button is offered.
    testWidgets('explains that feedback is unavailable on this device', (WidgetTester tester) async {
      // Act
      await showScreen(tester, supported: false);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining("isn't available on this device"), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    /// Done ends the flow and returns to the home screen.
    testWidgets('returns home from Done', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));
      await showScreen(tester);
      await tester.pumpAndSettle();

      // Act
      await tester.scrollUntilVisible(find.text('Done'), 300);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SuggestionsRoute), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    /// The screen must fit on the narrowest and widest screens.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768]) {
        hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));
        // A fresh tree, so each width starts from the home screen.
        await tester.pumpWidget(const SizedBox());
        await showScreen(tester, width: width);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });

    /// Saving the main suggestion changes the stored recipe, so the next brew uses it.
    testWidgets('saves the main suggestion to the recipe', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));
      await showScreen(tester);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Update my recipe'));
      await tester.pumpAndSettle();

      // Assert
      expect((await firestore.doc(_recipePath).get()).data()!['coffeeGrams'], 21);
      expect(find.text('Saved to your recipe'), findsOneWidget);
      expect(find.text('Recipe updated: Coffee 21.0 g'), findsOneWidget);
      expect(find.text('Update my recipe'), findsNothing);
    });

    /// Only changes the recipe stores can be saved, so the grind and temperature ideas have no button.
    testWidgets('offers to save only changes with a recipe value', (WidgetTester tester) async {
      // Act
      hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));
      await showScreen(tester);
      await tester.pumpAndSettle();

      // Assert: only the coffee dose, not the grind size or water temperature ideas.
      expect(find.text('Update my recipe'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(PrimarySuggestionCard), matching: find.text('Update my recipe')),
        findsOneWidget,
      );
    });

    /// One change per brew: saving one suggestion removes the option to save another.
    testWidgets('saves one suggestion at a time', (WidgetTester tester) async {
      // Arrange: the second idea is a bloom time with a new value, so it can also be saved.
      final Map<String, dynamic> answer = BrewFeedbackFixtures.answer()
        ..['otherIdeas'] = <Map<String, dynamic>>[
          BrewFeedbackFixtures.suggestion(parameter: 'bloomTime', suggestedValue: 55),
        ];
      hybridAi.responses.add(BrewFeedbackFixtures.result(answer));
      await showScreen(tester);
      await tester.pumpAndSettle();
      expect(find.text('Update my recipe'), findsNWidgets(2));

      // Act: save the idea for later rather than the main suggestion.
      await tester.tap(
        find.descendant(of: find.byType(AlternativeSuggestionCard), matching: find.text('Update my recipe')),
      );
      await tester.pumpAndSettle();

      // Assert
      final Map<String, dynamic> stored = (await firestore.doc(_recipePath).get()).data()!;
      expect(((stored['phases'] as List<dynamic>)[1] as Map<String, dynamic>)['durationSeconds'], 55);
      expect(stored['coffeeGrams'], 20);
      expect(find.text('Update my recipe'), findsNothing);
      expect(find.text('Saved to your recipe'), findsOneWidget);
    });

    /// A refused save says so, and the suggestion can be saved again.
    testWidgets('reports a save that fails', (WidgetTester tester) async {
      // Arrange: the stored recipe is gone, so the update is refused.
      await firestore.doc(_recipePath).delete();
      hybridAi.responses.add(BrewFeedbackFixtures.result(BrewFeedbackFixtures.answer()));
      await showScreen(tester);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Update my recipe'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text("Couldn't update your recipe. Try again."), findsOneWidget);
      expect(find.text('Update my recipe'), findsOneWidget);
    });
  });
}
