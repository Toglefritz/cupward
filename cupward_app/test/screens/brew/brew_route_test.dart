import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/brew_route.dart';
import 'package:cupward/screens/brew/components/recipe_summary_card.dart';
import 'package:cupward/screens/brew/components/scale_panel.dart';
import 'package:cupward/services/scale/scale_service.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies that the brewing screen shows the scale panel only where a scale can be used.
void main() {
  /// Shows the brewing screen with a scale service that reports whether scales are [supported].
  Future<void> showScreen(WidgetTester tester, {required bool supported}) async {
    final ScaleService service = ScaleService(isSupported: supported);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BrewRoute(recipe: BuiltInRecipes.defaultRecipe, scaleService: service),
      ),
    );
  }

  group('BrewRoute', () {
    /// On Android, iOS, and macOS the user connects a scale from the panel.
    testWidgets('shows the scale panel where scales are supported', (WidgetTester tester) async {
      // Act
      await showScreen(tester, supported: true);
      await tester.scrollUntilVisible(find.byType(ScalePanel), 200);

      // Assert
      expect(find.byType(ScalePanel), findsOneWidget);
    });

    /// Browsers cannot connect to a scale, so the brew is followed without the panel.
    testWidgets('leaves out the scale panel where scales are unsupported', (WidgetTester tester) async {
      // Act
      await showScreen(tester, supported: false);
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(RecipeSummaryCard, skipOffstage: false), findsOneWidget);
      expect(find.byType(ScalePanel, skipOffstage: false), findsNothing);
    });
  });
}
