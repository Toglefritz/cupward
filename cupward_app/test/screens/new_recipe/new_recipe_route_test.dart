import 'dart:async';

import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/new_recipe_request.dart';
import 'package:cupward/screens/new_recipe/components/brew_method_card.dart';
import 'package:cupward/screens/new_recipe/new_recipe_controller.dart';
import 'package:cupward/screens/new_recipe/new_recipe_route.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_service.dart';
import 'package:cupward/services/recipes/recipe_repository.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/brew_feedback/brew_feedback_fixtures.dart';
import '../../services/recipe_generation/recipe_generation_fixtures.dart';

/// The screen's own scrolling list, rather than the one inside the text field.
final Finder _page = find.byType(Scrollable).first;

/// An auth service that is already signed in, without Firebase.
class _SignedInAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => 'tester';
}

/// Verifies the new recipe form: choosing a method, describing a taste, and when a recipe can be created.
void main() {
  /// Shows the screen at the given [width].
  Future<void> showScreen(WidgetTester tester, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NewRecipeRoute(),
      ),
    );
  }

  /// The controller of the screen.
  NewRecipeController controller(WidgetTester tester) => tester.state<NewRecipeController>(find.byType(NewRecipeRoute));

  /// The "Create recipe" button.
  FilledButton createButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create recipe'));

  group('NewRecipeRoute', () {
    /// Every method is offered as a card, none chosen at first.
    testWidgets('offers every brewing method', (WidgetTester tester) async {
      // Act
      await showScreen(tester);

      // Assert
      expect(find.text('New Recipe'), findsOneWidget);
      expect(find.byType(BrewMethodCard), findsNWidgets(BrewMethod.values.length));
      expect(find.text('French press'), findsOneWidget);
      expect(find.text('About 4½ min'), findsOneWidget);
      expect(controller(tester).selectedMethod, isNull);
    });

    /// Only one method is chosen at a time.
    testWidgets('chooses one method at a time', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester);

      // Act
      await tester.tap(find.text('Chemex'));
      await tester.pump();
      await tester.tap(find.text('AeroPress'));
      await tester.pump();

      // Assert
      expect(controller(tester).selectedMethod, BrewMethod.aeroPress);
      final Iterable<BrewMethodCard> selected = tester
          .widgetList<BrewMethodCard>(find.byType(BrewMethodCard))
          .where((BrewMethodCard card) => card.isSelected);
      expect(selected.single.method, BrewMethod.aeroPress);
    });

    /// A recipe needs both a method and a description of the user's taste.
    testWidgets('enables Create once a method and a taste are given', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester);
      await tester.scrollUntilVisible(find.text('Create recipe'), 300, scrollable: _page);

      // Assert
      expect(createButton(tester).onPressed, isNull);
      expect(find.textContaining('Pick a brewing method'), findsOneWidget);

      // Act: a taste alone is not enough.
      await tester.enterText(find.byType(TextField), 'Strong and full-bodied.');
      await tester.pump();

      // Assert
      expect(createButton(tester).onPressed, isNull);

      // Act
      await tester.scrollUntilVisible(find.text('V60'), -300, scrollable: _page);
      await tester.tap(find.text('V60'));
      await tester.pump();

      // Assert
      expect(createButton(tester).onPressed, isNotNull);
      expect(find.textContaining('Pick a brewing method'), findsNothing);
      expect(
        controller(tester).request,
        const NewRecipeRequest(method: BrewMethod.v60, preferences: 'Strong and full-bodied.'),
      );
    });

    /// Topic chips start a line about each topic, so the user knows what is useful to mention.
    testWidgets('starts a line for a tapped topic', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester);
      await tester.scrollUntilVisible(find.text('Roast'), 300, scrollable: _page);

      // Act
      await tester.tap(find.text('Roast'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '${controller(tester).preferencesController.text}medium');
      await tester.tap(find.text('Cup size'));
      await tester.pump();

      // Assert
      expect(controller(tester).preferencesController.text, 'Roast: medium\nCup size: ');
      expect(controller(tester).preferencesFocus.hasFocus, isTrue);
    });

    /// The grid has two columns on phones and three on wider screens, and fits without overflowing.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768, 1024]) {
        await showScreen(tester, width: width);
        await tester.tap(find.text('Kalita Wave'));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });
  });

  group('creating a recipe', () {
    late FakeStructuredHybridAi hybridAi;
    late RecipeGenerationService service;

    setUp(() {
      hybridAi = FakeStructuredHybridAi();
      service = RecipeGenerationService(
        hybridAi: hybridAi,
        recipes: RecipeRepository(firestore: FakeFirebaseFirestore(), auth: _SignedInAuth()),
        isSupported: true,
      );
    });

    /// Opens the screen from another screen, and returns a completer that receives the result it closes with.
    Future<Completer<BrewRecipe?>> openScreen(WidgetTester tester) async {
      final Completer<BrewRecipe?> result = Completer<BrewRecipe?>();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async => result.complete(
                await Navigator.push<BrewRecipe>(
                  context,
                  MaterialPageRoute<BrewRecipe>(
                    builder: (BuildContext context) => NewRecipeRoute(generationService: service),
                  ),
                ),
              ),
              child: const Text('brew'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('brew'));
      await tester.pumpAndSettle();
      return result;
    }

    /// Fills in the form and taps Create recipe.
    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.text('Kalita Wave'));
      await tester.scrollUntilVisible(find.byType(TextField), 300, scrollable: _page);
      await tester.enterText(find.byType(TextField), 'Strong, about 350 ml.');
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Create recipe'), 300, scrollable: _page);
      await tester.tap(find.text('Create recipe'));
      await tester.pump();
    }

    /// The screen shows progress while the recipe is made, then closes with the saved recipe.
    testWidgets('shows progress, then returns the new recipe', (WidgetTester tester) async {
      // Arrange
      hybridAi
        ..gate = Completer<void>()
        ..responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      final Completer<BrewRecipe?> result = await openScreen(tester);

      // Act
      await submit(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(find.text('Creating your recipe'), findsOneWidget);
      expect(find.textContaining('Building a Kalita Wave recipe'), findsOneWidget);
      expect(find.text('Brewing method'), findsNothing);

      // Act
      hybridAi.gate!.complete();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NewRecipeRoute), findsNothing);
      expect((await result.future)?.name, 'Bold Morning Kalita');
    });

    /// A failure can be retried, or the request edited, without losing what the user entered.
    testWidgets('offers to try again or edit after a failure', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(const FirebaseHybridAiException(code: 'network'))
        ..add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      final Completer<BrewRecipe?> result = await openScreen(tester);

      // Act
      await submit(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No recipe yet'), findsOneWidget);
      expect(find.textContaining("Couldn't create a recipe"), findsOneWidget);

      // Act: editing keeps the form as it was.
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Assert
      expect(controller(tester).selectedMethod, BrewMethod.kalitaWave);
      expect(controller(tester).preferencesController.text, 'Strong, about 350 ml.');

      // Act: create again, fail, then try again.
      await tester.scrollUntilVisible(find.text('Create recipe'), 300, scrollable: _page);
      await tester.tap(find.text('Create recipe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      // Assert
      expect((await result.future)?.id, 'bold-morning-kalita');
    });

    /// The menu in the title card has a switch that limits the request to the on-device model.
    testWidgets('uses only the on-device model when the menu switch is on', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      final Completer<BrewRecipe?> result = await openScreen(tester);
      expect(controller(tester).localOnly, isFalse);

      // Act
      await tester.tap(find.byTooltip('Recipe creation options'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Local AI only'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

      // Act
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert: the menu stays open and shows the new setting.
      expect(controller(tester).localOnly, isTrue);
      expect(find.text('Local AI only'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      // Act
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await submit(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.onlyOnDevice]);
      expect((await result.future)?.name, 'Bold Morning Kalita');
    });

    /// The track is the theme's green, so a selected thumb must not take that color when hovered or pressed.
    testWidgets('keeps the switch thumb visible against the track', (WidgetTester tester) async {
      // Arrange
      await openScreen(tester);
      await tester.tap(find.byTooltip('Recipe creation options'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Act
      final Switch toggle = tester.widget<Switch>(find.byType(Switch));
      final Color track = Theme.of(tester.element(find.byType(Switch))).colorScheme.primary;

      // Assert
      for (final Set<WidgetState> states in <Set<WidgetState>>[
        <WidgetState>{WidgetState.selected},
        <WidgetState>{WidgetState.selected, WidgetState.hovered},
        <WidgetState>{WidgetState.selected, WidgetState.pressed},
      ]) {
        expect(toggle.thumbColor!.resolve(states), Colors.white, reason: '$states');
        expect(toggle.thumbColor!.resolve(states), isNot(track), reason: '$states');
      }
    });

    /// Without the switch, the on-device model is preferred and the cloud model is the fallback.
    testWidgets('prefers the on-device model by default', (WidgetTester tester) async {
      // Arrange
      hybridAi.responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      await openScreen(tester);

      // Act
      await submit(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(hybridAi.modes, <InferenceMode>[InferenceMode.preferOnDevice]);
    });

    /// Leaving while the recipe is created would save a recipe the brewing screen never hears about, so back is
    /// blocked until it is done.
    testWidgets('cannot be left while the recipe is created', (WidgetTester tester) async {
      // Arrange
      hybridAi
        ..gate = Completer<void>()
        ..responses.add(BrewFeedbackFixtures.result(RecipeGenerationFixtures.pourOverAnswer()));
      final Completer<BrewRecipe?> result = await openScreen(tester);
      await submit(tester);
      // Act
      final bool popped = await tester.binding.handlePopRoute();
      // The progress indicator keeps animating, so the screen never settles while the recipe is created.
      await tester.pump(const Duration(milliseconds: 300));
      // Assert
      expect(popped, isTrue);
      expect(find.byType(NewRecipeRoute), findsOneWidget);
      expect(result.isCompleted, isFalse);
      // Act
      hybridAi.gate!.complete();
      await tester.pumpAndSettle();
      // Assert
      expect((await result.future)?.name, 'Bold Morning Kalita');
    });
  });

  group('NewRecipeRequest', () {
    /// The request is what the recipe is built from, so it must survive conversion to JSON and back.
    test('converts to JSON and back, trimming the preferences', () {
      const NewRecipeRequest request = NewRecipeRequest(method: BrewMethod.frenchPress, preferences: '  Rich.  ');

      expect(request.toJson(), <String, dynamic>{'method': 'frenchPress', 'preferences': 'Rich.'});
      expect(
        NewRecipeRequest.fromJson(request.toJson()),
        const NewRecipeRequest(method: BrewMethod.frenchPress, preferences: 'Rich.'),
      );
      const Map<String, dynamic> unknown = <String, dynamic>{'method': 'siphon', 'preferences': ''};
      expect(() => NewRecipeRequest.fromJson(unknown), throwsFormatException);
    });
  });
}
