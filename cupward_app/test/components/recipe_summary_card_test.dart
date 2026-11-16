import 'package:cupward/components/recipe_stats_row.dart';
import 'package:cupward/components/recipe_summary_card.dart';
import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies that the recipe summary card shows a recipe's name, profile, and formatted targets, and the formatting
/// rules behind them. The card is shown on its own, with the app's colors extension and English strings.
void main() {
  /// Shows [recipe] in the card at the given screen [width].
  Future<void> showCard(WidgetTester tester, BrewRecipe recipe, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RecipeSummaryCard(recipe: recipe)),
      ),
    );
  }

  group('RecipeSummaryCard', () {
    /// The card is the user's reference for the brew, so every target from the concept must be shown.
    testWidgets('shows the name, profile, and targets', (WidgetTester tester) async {
      // Act
      await showCard(tester, BuiltInRecipes.v60PourOver);

      // Assert
      expect(find.text('V60 Pour Over'), findsOneWidget);
      expect(find.text('Balanced & Clean'), findsOneWidget);
      expect(find.text('20.0 g'), findsOneWidget);
      expect(find.text('320 g'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
      expect(find.text('~320 ml'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Yield'), findsOneWidget);
    });

    /// The layout changes with width, and both forms must fit without overflowing on the smallest and largest screens.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768, 1024]) {
        await showCard(tester, BuiltInRecipes.v60PourOver, width: width);

        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });
  });

  group('RecipeStatsRow formatting', () {
    /// Doses are weighed to a tenth of a gram, so the tenth is always shown.
    test('shows a coffee dose with one decimal place', () {
      expect(RecipeStatsRow.formatCoffeeGrams(20, 'en'), '20.0');
      expect(RecipeStatsRow.formatCoffeeGrams(18.5, 'en'), '18.5');
    });

    /// Whole water weights read better without a decimal, and a fraction is still shown when there is one.
    test('shows a water weight without a decimal when it is whole', () {
      expect(RecipeStatsRow.formatWaterGrams(320, 'en'), '320');
      expect(RecipeStatsRow.formatWaterGrams(250.5, 'en'), '250.5');
      expect(RecipeStatsRow.formatWaterGrams(1000, 'en'), '1,000');
    });

    /// Brew times are read as a clock, with seconds always shown as two digits.
    test('shows a brew time as minutes and seconds', () {
      expect(RecipeStatsRow.formatBrewTime(const Duration(minutes: 3)), '3:00');
      expect(RecipeStatsRow.formatBrewTime(const Duration(minutes: 2, seconds: 5)), '2:05');
    });

    /// The yield is an estimate, so it is rounded to whole milliliters.
    test('rounds a yield to whole milliliters', () {
      expect(RecipeStatsRow.formatYieldMilliliters(320, 'en'), '320');
      expect(RecipeStatsRow.formatYieldMilliliters(287.6, 'en'), '288');
    });
  });
}
