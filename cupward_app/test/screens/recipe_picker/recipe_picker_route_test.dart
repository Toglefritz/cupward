import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/recipe_picker/recipe_picker_route.dart';
import 'package:cupward/services/auth/auth_service.dart';
import 'package:cupward/services/recipes/recipe_repository.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An auth service that is already signed in, without Firebase.
class _SignedInAuth extends AuthService {
  @override
  Future<String> ensureSignedIn() async => 'tester';
}

/// A repository whose first [failures] requests for the list fail, as when there is no connection.
class _FlakyRepository extends RecipeRepository {
  /// Creates a repository over [firestore] that fails [failures] times.
  _FlakyRepository(FakeFirebaseFirestore firestore, this.failures) : super(firestore: firestore, auth: _SignedInAuth());

  /// How many more requests fail.
  int failures;

  @override
  Future<List<BrewRecipe>> fetchAll() {
    if (failures > 0) {
      failures--;
      return Future<List<BrewRecipe>>.error(Exception('offline'));
    }
    return super.fetchAll();
  }
}

/// Verifies that the recipe list screen lists the user's recipes and hands back the one they choose.
void main() {
  const BrewRecipe v60 = BuiltInRecipes.v60PourOver;
  final BrewRecipe bold = v60.copyWith(id: 'bold-v60', name: 'Bold V60', profile: 'Strong & Rich');

  late FakeFirebaseFirestore firestore;
  late RecipeRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = RecipeRepository(firestore: firestore, auth: _SignedInAuth());
  });

  /// Opens the screen from a button, and returns what it closes with through [result].
  Future<void> show(WidgetTester tester, RecipeRepository recipes, void Function(BrewRecipe?) result) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => result(
              await Navigator.push<BrewRecipe>(
                context,
                MaterialPageRoute<BrewRecipe>(
                  builder: (BuildContext context) => RecipePickerRoute(currentRecipe: v60, recipeRepository: recipes),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('RecipePickerRoute', () {
    /// Every recipe the user has is on the list, and the one on the brewing screen is marked.
    testWidgets('lists the user\'s recipes and marks the current one', (WidgetTester tester) async {
      // Arrange
      await repository.create(v60);
      await repository.create(bold);
      // Act
      await show(tester, repository, (BrewRecipe? _) {});
      // Assert
      expect(find.text('Choose a recipe'), findsOneWidget);
      expect(find.text('V60 Pour Over'), findsOneWidget);
      expect(find.text('Bold V60'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    /// Tapping a recipe closes the screen with it as the choice.
    testWidgets('returns the recipe that is tapped', (WidgetTester tester) async {
      // Arrange
      await repository.create(v60);
      await repository.create(bold);
      BrewRecipe? chosen;
      bool closed = false;
      await show(tester, repository, (BrewRecipe? value) {
        chosen = value;
        closed = true;
      });
      // Act
      // The card's tap area covers its text, so the tap lands on the card, which is the point.
      await tester.tap(find.text('Bold V60'), warnIfMissed: false);
      await tester.pumpAndSettle();
      // Assert
      expect(closed, isTrue);
      expect(chosen?.id, 'bold-v60');
      expect(find.byType(RecipePickerRoute), findsNothing);
    });

    /// The close button leaves the brew as it was, with no choice.
    testWidgets('closes without a choice from the close button', (WidgetTester tester) async {
      // Arrange
      await repository.create(v60);
      await repository.create(bold);
      BrewRecipe? chosen = v60;
      bool closed = false;
      await show(tester, repository, (BrewRecipe? value) {
        chosen = value;
        closed = true;
      });
      // Act
      await tester.tap(find.byTooltip('Close without changing the recipe'));
      await tester.pumpAndSettle();
      // Assert
      expect(closed, isTrue);
      expect(chosen, isNull);
    });

    /// A first launch without a network has not stored the built-in recipe, which must still be on the list.
    testWidgets('lists the current recipe even when it is not stored', (WidgetTester tester) async {
      // Arrange
      await repository.create(bold);
      // Act
      await show(tester, repository, (BrewRecipe? _) {});
      // Assert
      expect(find.text('V60 Pour Over'), findsOneWidget);
      expect(find.text('Bold V60'), findsOneWidget);
    });

    /// A failed load says so, and trying again shows the recipes.
    testWidgets('offers to try again when the recipes cannot be loaded', (WidgetTester tester) async {
      // Arrange
      final _FlakyRepository flaky = _FlakyRepository(firestore, 1);
      await flaky.create(bold);
      // Act
      await show(tester, flaky, (BrewRecipe? _) {});
      // Assert
      expect(find.text('Couldn\'t load your recipes'), findsOneWidget);
      // Act
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Couldn\'t load your recipes'), findsNothing);
      expect(find.text('Bold V60'), findsOneWidget);
    });
  });
}
