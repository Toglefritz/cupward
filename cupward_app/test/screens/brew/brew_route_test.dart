import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/brew_route.dart';
import 'package:cupward/screens/brew/components/recipe_summary_card.dart';
import 'package:cupward/screens/brew/components/scale_panel.dart';
import 'package:cupward/services/scale/scale_service.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_bookoo/flutter_bookoo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A scale service that reports itself connected and records tare commands, without Bluetooth.
class _ConnectedScaleService extends ScaleService {
  /// Creates a service that is connected, and whose tare command throws if [failTare] is true.
  _ConnectedScaleService({this.failTare = false}) : super(isSupported: true);

  /// Whether [tare] throws, as when the command cannot be written.
  final bool failTare;

  /// How many times [tare] was called.
  int tareCount = 0;

  @override
  bool get isConnected => true;

  @override
  Future<void> tare() async {
    tareCount++;
    if (failTare) {
      throw const ThemisCommandException('write failed');
    }
  }
}

/// Verifies that the brewing screen shows the scale panel only where a scale can be used, and that its main action
/// button advances the brew.
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

  /// Shows the screen with [service] and a navigator that can be popped, as when opened from the home screen.
  Future<void> showWith(WidgetTester tester, ScaleService service) async {
    addTearDown(service.dispose);
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
                builder: (BuildContext context) =>
                    BrewRoute(recipe: BuiltInRecipes.defaultRecipe, scaleService: service),
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

  group('main action button', () {
    /// Each phase kind has its own label, and the button walks the brew from the first step to the last.
    testWidgets('advances through every phase and leaves the screen on the last', (WidgetTester tester) async {
      // Arrange
      await showWith(tester, ScaleService(isSupported: false));

      // Act and assert
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 2 OF 6'), findsOneWidget);

      for (int step = 3; step <= 5; step++) {
        await tester.tap(find.text('Next step'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Next step'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 6 OF 6'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(BrewRoute), findsNothing);
    });

    /// Weights in later phases count water only if the scale is zeroed with the brewer and coffee on it.
    testWidgets('tares a connected scale when leaving preparation', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = _ConnectedScaleService();
      await showWith(tester, service);

      // Act
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next step'));
      await tester.pumpAndSettle();

      // Assert
      expect(service.tareCount, 1);
      expect(find.text('STEP 3 OF 6'), findsOneWidget);
    });

    /// Continuing with a failed tare would leave every later weight wrong, so the brew stays in preparation.
    testWidgets('stays in preparation and says so when the tare fails', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = _ConnectedScaleService(failTare: true);
      await showWith(tester, service);

      // Act
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Assert
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
