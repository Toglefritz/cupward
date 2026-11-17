import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/brew_route.dart';
import 'package:cupward/screens/home/home_route.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:cupward/services/on_device_model/on_device_model_service.dart';
import 'package:cupward/services/on_device_model/on_device_model_state.dart';
import 'package:cupward/services/recipes/recipe_repository.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/on_device_model/fake_hybrid_ai.dart';

/// An auth service that is already signed in, without Firebase.
class _SignedInAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => 'tester';
}

/// Verifies that the home screen checks for the on-device model when it appears and starts a download from the panel.
void main() {
  late FakeHybridAi hybridAi;
  late OnDeviceModelService service;
  late FakeFirebaseFirestore firestore;
  late RecipeRepository recipes;

  setUp(() {
    hybridAi = FakeHybridAi();
    service = OnDeviceModelService(hybridAi: hybridAi, isSupported: true);
    firestore = FakeFirebaseFirestore();
    recipes = RecipeRepository(firestore: firestore, auth: _SignedInAuth());
  });

  tearDown(() => service.dispose());

  /// Shows the home screen with [service].
  Future<void> showHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeRoute(modelService: service, recipeRepository: recipes),
      ),
    );
  }

  group('HomeRoute', () {
    /// The check runs before the first brew, so the user learns about the model up front.
    testWidgets('checks for the model when it appears', (WidgetTester tester) async {
      // Act
      await showHome(tester);
      await tester.pump();

      // Assert
      expect(hybridAi.checkCount, 1);
      expect(find.text('Not downloaded'), findsOneWidget);
      expect(find.text('Start a Brew'), findsOneWidget);
    });

    /// Coming back to the home screen must not repeat a check that already finished.
    testWidgets('does not check again on a later visit', (WidgetTester tester) async {
      // Arrange
      await service.checkStatus();

      // Act
      await showHome(tester);
      await tester.pump();

      // Assert
      expect(hybridAi.checkCount, 1);
    });

    /// Tapping Download starts the download and the panel follows its progress.
    testWidgets('downloads the model from the panel', (WidgetTester tester) async {
      // Arrange
      await showHome(tester);
      await tester.pump();

      // Act
      await tester.tap(find.text('Download'));
      hybridAi.downloadController.add(OnDeviceModelDownloadProgress(fraction: 0.25));
      await tester.pump();

      // Assert
      expect(hybridAi.downloadCount, 1);
      expect(service.state, OnDeviceModelState.downloading);
      expect(find.text('25%'), findsOneWidget);
    });

    /// A brew uses the user's stored recipe, so changes made to it are brewed.
    testWidgets('starts a brew with the stored recipe', (WidgetTester tester) async {
      // Arrange: the user's copy has one more gram of coffee than the built-in recipe.
      final Map<String, dynamic> stored = BuiltInRecipes.defaultRecipe.toJson()..['coffeeGrams'] = 21.0;
      await firestore.doc('users/tester/recipes/${BuiltInRecipes.defaultRecipe.id}').set(stored);
      await showHome(tester);
      await tester.pump();

      // Act
      await tester.tap(find.text('Start a Brew'));
      await tester.pumpAndSettle();

      // Assert
      final BrewRecipe recipe = tester.widget<BrewRoute>(find.byType(BrewRoute)).recipe;
      expect(recipe.coffeeGrams, 21);
    });

    /// The first visit saves the built-in recipe as the user's own, so later changes can be stored.
    testWidgets('saves the built-in recipe for a new user', (WidgetTester tester) async {
      // Act
      await showHome(tester);
      await tester.pump();

      // Assert
      final bool exists = (await firestore.doc('users/tester/recipes/${BuiltInRecipes.defaultRecipe.id}').get()).exists;
      expect(exists, isTrue);
    });

    /// A suggestion saved at the end of a brew is used by the next brew, without restarting the app.
    testWidgets('loads the recipe again after a brew', (WidgetTester tester) async {
      // Arrange: a first brew starts with the built-in recipe.
      await showHome(tester);
      await tester.pump();
      await tester.tap(find.text('Start a Brew'));
      await tester.pumpAndSettle();

      // Act: the brew saves a change, and the user returns home and starts again.
      await firestore.doc('users/tester/recipes/${BuiltInRecipes.defaultRecipe.id}').update(<String, dynamic>{
        'coffeeGrams': 21.0,
      });
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start a Brew'));
      await tester.pumpAndSettle();

      // Assert
      expect(tester.widget<BrewRoute>(find.byType(BrewRoute)).recipe.coffeeGrams, 21);
    });
  });
}
