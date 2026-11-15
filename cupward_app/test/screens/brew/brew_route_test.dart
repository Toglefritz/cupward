import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/brew_controller.dart';
import 'package:cupward/screens/brew/brew_route.dart';
import 'package:cupward/screens/brew/components/brew_action_button.dart';
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

  /// Whether the service reports a connected scale.
  bool connected = true;

  /// The latest reading, which tests change through [emit].
  BookooScaleReading? latest;

  @override
  bool get isConnected => connected;

  @override
  BookooScaleReading? get reading => latest;

  /// Sends [value] to listeners as if the scale had reported it.
  void emit(BookooScaleReading value) {
    latest = value;
    notifyListeners();
  }

  /// Reports the scale as lost.
  void disconnectScale() {
    connected = false;
    latest = null;
    notifyListeners();
  }

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

  group('advancing with the scale', () {
    /// The time the screen sees, which the tests move forward together with the fake clock.
    late DateTime clockNow;

    setUp(() => clockNow = DateTime(2025));

    /// A reading of [grams] with the given [flow] in grams per second.
    BookooScaleReading reading(double grams, {double flow = 0}) => BookooScaleReading(
          elapsed: Duration.zero,
          weightGrams: grams,
          flowRateGramsPerSecond: flow,
          batteryPercent: 80,
          standbyTime: const Duration(minutes: 5),
          beepLevel: 3,
          flowSmoothingEnabled: false,
        );

    /// Moves both the screen's clock and the test clock forward by [duration], in small steps.
    Future<void> elapse(WidgetTester tester, Duration duration) async {
      Duration left = duration;
      while (left > Duration.zero) {
        const Duration step = Duration(milliseconds: 100);
        clockNow = clockNow.add(step);
        await tester.pump(step);
        left -= step;
      }
    }

    /// Shows the screen with a connected scale and leaves preparation, so the bloom is the current phase.
    Future<_ConnectedScaleService> startAtBloom(WidgetTester tester) async {
      final _ConnectedScaleService service = _ConnectedScaleService();
      addTearDown(service.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BrewRoute(recipe: BuiltInRecipes.defaultRecipe, scaleService: service, now: () => clockNow),
        ),
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      service.emit(reading(0));
      await tester.pump();
      return service;
    }

    /// Pours to the bloom target and stops, which starts the rest.
    Future<void> pourBloom(WidgetTester tester, _ConnectedScaleService service) async {
      service.emit(reading(30, flow: 4));
      await elapse(tester, const Duration(milliseconds: 500));
      service.emit(reading(60));
      await elapse(tester, const Duration(milliseconds: 1200));
      service.emit(reading(60));
      await tester.pump();
    }

    /// After the bloom water is in, the screen counts the rest, and then offers a window to cancel before moving on.
    testWidgets('rests after the bloom, counts down, and moves on', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = await startAtBloom(tester);

      // Act
      await pourBloom(tester, service);

      // Assert
      expect(find.textContaining('Rest '), findsOneWidget);
      expect(find.text('STEP 2 OF 6'), findsOneWidget);

      await elapse(tester, const Duration(seconds: 45));
      expect(find.textContaining('Next step in'), findsOneWidget);
      expect(find.text('STEP 2 OF 6'), findsOneWidget);

      await elapse(tester, BrewController.advanceWindow + const Duration(milliseconds: 300));
      expect(find.text('STEP 3 OF 6'), findsOneWidget);
    });

    /// Cancelling leaves the user in control of the phase, so the brew stays where it is until the button is tapped.
    testWidgets('stays on the step after Cancel', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = await startAtBloom(tester);
      await pourBloom(tester, service);
      await elapse(tester, const Duration(seconds: 45));

      // Act
      await tester.tap(find.text('Cancel'));
      await elapse(tester, const Duration(seconds: 10));

      // Assert
      expect(find.text('STEP 2 OF 6'), findsOneWidget);
      expect(find.textContaining('Next step in'), findsNothing);

      await tester.tap(find.text('Next step'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 3 OF 6'), findsOneWidget);
    });

    /// A pour ends when the weight reaches its target and the flow stops, with no rest in between.
    testWidgets('moves on from a pour that reaches its target', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = await startAtBloom(tester);
      await tester.tap(find.text('Next step'));
      await tester.pumpAndSettle();
      service.emit(reading(60));
      await tester.pump();
      expect(find.text('STEP 3 OF 6'), findsOneWidget);

      // Act
      service.emit(reading(120, flow: 5));
      await elapse(tester, const Duration(milliseconds: 500));
      service.emit(reading(160));
      await elapse(tester, const Duration(milliseconds: 1200));
      service.emit(reading(160));
      await elapse(tester, BrewController.advanceWindow + const Duration(milliseconds: 300));

      // Assert
      expect(find.text('STEP 4 OF 6'), findsOneWidget);
    });

    /// The manual button must keep working during the countdown, and must not advance a second time afterwards.
    testWidgets('lets the main button advance during the countdown', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = await startAtBloom(tester);
      await tester.tap(find.text('Next step'));
      await tester.pumpAndSettle();
      service.emit(reading(60));
      await tester.pump();
      service.emit(reading(160));
      await elapse(tester, const Duration(milliseconds: 1200));
      service.emit(reading(160));
      await tester.pump();
      expect(find.textContaining('Next step in'), findsOneWidget);

      // Act
      await tester.tap(find.widgetWithText(OutlinedButton, 'Next step'));
      await elapse(tester, const Duration(seconds: 10));

      // Assert
      expect(find.text('STEP 4 OF 6'), findsOneWidget);
    });

    /// Readings that stop arriving must not carry the brew forward, so losing the scale hands control back.
    testWidgets('stops counting down when the scale is lost', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = await startAtBloom(tester);
      await pourBloom(tester, service);
      await elapse(tester, const Duration(seconds: 45));
      expect(find.textContaining('Next step in'), findsOneWidget);

      // Act
      service.disconnectScale();
      await elapse(tester, const Duration(seconds: 10));

      // Assert
      expect(find.text('STEP 2 OF 6'), findsOneWidget);
      expect(find.textContaining('Next step in'), findsNothing);
    });

    /// Where the scale ends the step, the button is only an override, so it recedes into an outlined button. Where only
    /// the user can end the step, it stays the solid green button.
    testWidgets('quiets the main button only while the scale advances the step', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = await startAtBloom(tester);

      // Assert: the bloom advances by itself, so the button is outlined.
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.getSize(find.byType(OutlinedButton)).height, BrewActionButton.quietHeight);

      // Act: cancelling gives the step back to the user.
      await pourBloom(tester, service);
      await elapse(tester, const Duration(seconds: 45));
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Assert
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    /// Preparation has nothing for the scale to measure, so the button that starts the brew must stand out even when
    /// a scale is connected.
    testWidgets('keeps the main button prominent in preparation with a scale connected', (WidgetTester tester) async {
      // Arrange
      final _ConnectedScaleService service = _ConnectedScaleService();
      addTearDown(service.dispose);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BrewRoute(recipe: BuiltInRecipes.defaultRecipe, scaleService: service, now: () => clockNow),
        ),
      );

      // Assert
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
