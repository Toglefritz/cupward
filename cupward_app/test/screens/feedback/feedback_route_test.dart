import 'package:cupward/components/recipe_summary_card.dart';
import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/brews/brew_phase_record.dart';
import 'package:cupward/models/brews/brew_record.dart';
import 'package:cupward/models/brews/brew_sample.dart';
import 'package:cupward/models/brews/taste_attribute.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/feedback/components/brew_weight_chart.dart';
import 'package:cupward/screens/feedback/components/taste_slider.dart';
import 'package:cupward/screens/feedback/feedback_controller.dart';
import 'package:cupward/screens/feedback/feedback_route.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The phases of a full brew of the default recipe.
const List<BrewPhaseRecord> _phases = <BrewPhaseRecord>[
  BrewPhaseRecord(phaseId: 'bloom', startedAt: Duration.zero),
  BrewPhaseRecord(phaseId: 'pour-1', startedAt: Duration(seconds: 50)),
  BrewPhaseRecord(phaseId: 'pour-2', startedAt: Duration(seconds: 80)),
  BrewPhaseRecord(phaseId: 'pour-3', startedAt: Duration(seconds: 110)),
  BrewPhaseRecord(phaseId: 'complete', startedAt: Duration(seconds: 140)),
];

/// A brew of the default recipe that took [totalTime], with [samples] from the scale.
BrewRecord _record({
  List<BrewSample> samples = const <BrewSample>[],
  Duration totalTime = const Duration(seconds: 192),
}) {
  return BrewRecord(
    recipe: BuiltInRecipes.defaultRecipe,
    startedAt: DateTime(2026, 11, 15, 8, 30),
    totalTime: totalTime,
    phases: _phases,
    samples: samples,
  );
}

/// Readings that pour to each target of the default recipe.
const List<BrewSample> _samples = <BrewSample>[
  BrewSample(elapsed: Duration(seconds: 10), weightGrams: 61, flowGramsPerSecond: 6.2),
  BrewSample(elapsed: Duration(seconds: 50), weightGrams: 61, flowGramsPerSecond: 0),
  BrewSample(elapsed: Duration(seconds: 70), weightGrams: 158, flowGramsPerSecond: 5),
  BrewSample(elapsed: Duration(seconds: 100), weightGrams: 241, flowGramsPerSecond: 4),
  BrewSample(elapsed: Duration(seconds: 130), weightGrams: 318.4, flowGramsPerSecond: 4),
  BrewSample(elapsed: Duration(seconds: 190), weightGrams: 318.4, flowGramsPerSecond: 0),
];

/// The screen's own scrolling list, rather than the one inside the text field.
final Finder _pageScrollable = find.byType(Scrollable).first;

/// Verifies what the feedback screen shows for brews with and without scale readings.
void main() {
  /// Shows the screen for [record] at the given screen [width].
  Future<void> showScreen(WidgetTester tester, BrewRecord record, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeedbackRoute(record: record),
      ),
    );
  }

  group('FeedbackRoute', () {
    /// The recipe is shown first, for reference, followed by how the brew compares with it.
    testWidgets('shows the recipe and the brew against its targets', (WidgetTester tester) async {
      // Arrange
      final SemanticsHandle semantics = tester.ensureSemantics();

      // Act
      await showScreen(tester, _record(samples: _samples));

      // Assert
      expect(find.byType(RecipeSummaryCard), findsOneWidget);
      expect(find.text('Your brew'), findsOneWidget);
      expect(find.text('3:12'), findsOneWidget);
      expect(find.text('Target 3:00'), findsOneWidget);
      expect(find.text('318.4 g'), findsOneWidget);
      expect(find.text('Target 320 g'), findsOneWidget);
      expect(find.text('6.2 g/s'), findsOneWidget);
      expect(find.byType(BrewWeightChart), findsOneWidget);
      expect(tester.getSemantics(find.byType(BrewWeightChart)).label, 'Weight over time. 318 g after 3:12.');
      semantics.dispose();
    });

    /// Each step is listed with how long it took, its final weight, and its target.
    testWidgets('lists each step with its time and weight', (WidgetTester tester) async {
      // Act
      await showScreen(tester, _record(samples: _samples));

      // Assert
      expect(find.text('Step'), findsOneWidget);
      expect(find.text('Bloom'), findsOneWidget);
      expect(find.text('Pour 3'), findsOneWidget);
      expect(find.text('0:50'), findsOneWidget);
      expect(find.text('240 g'), findsOneWidget);
      expect(find.text('241 g'), findsOneWidget);
    });

    /// A brew without a scale still has step times, and the screen says why there are no weights.
    testWidgets('explains a brew without scale readings', (WidgetTester tester) async {
      // Act
      await showScreen(tester, _record());

      // Assert
      expect(find.byType(BrewWeightChart), findsNothing);
      expect(find.textContaining('No scale was connected'), findsOneWidget);
      expect(find.text('Weight'), findsNothing);
      expect(find.text('0:50'), findsOneWidget);
    });

    /// Every attribute starts unrated, so an untouched slider is not mistaken for an answer.
    testWidgets('shows a slider for each taste attribute, all unrated', (WidgetTester tester) async {
      // Act
      await showScreen(tester, _record(samples: _samples));
      await tester.scrollUntilVisible(find.text('Overall'), 300, scrollable: _pageScrollable);

      // Assert
      expect(find.text('Tasting notes'), findsOneWidget);
      expect(find.byType(TasteSlider, skipOffstage: false), findsNWidgets(TasteAttribute.values.length));
      expect(find.text('Not rated', skipOffstage: false), findsNWidgets(TasteAttribute.values.length));
      expect(find.text('Very bitter', skipOffstage: false), findsOneWidget);
    });

    /// Moving a slider rates its attribute, including a tap on the thumb where it rests.
    testWidgets('rates an attribute when its slider is touched', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester, _record(samples: _samples));
      final Finder bitterness = find.descendant(
        of: find.byWidgetPredicate(
          (Widget widget) => widget is TasteSlider && widget.attribute == TasteAttribute.bitterness,
        ),
        matching: find.byType(Slider),
      );
      final Finder intensity = find.descendant(
        of: find.byWidgetPredicate(
          (Widget widget) => widget is TasteSlider && widget.attribute == TasteAttribute.intensity,
        ),
        matching: find.byType(Slider),
      );
      await tester.scrollUntilVisible(bitterness, 300, scrollable: _pageScrollable);

      // Act: drag bitterness to the right end, and tap intensity's resting thumb.
      await tester.drag(bitterness, const Offset(500, 0));
      await tester.tap(intensity);
      await tester.pump();

      // Assert
      final FeedbackController controller = tester.state<FeedbackController>(find.byType(FeedbackRoute));
      expect(controller.tastingNotes.ratings, <TasteAttribute, int>{
        TasteAttribute.bitterness: 5,
        TasteAttribute.intensity: 3,
      });
      expect(find.text('Not rated', skipOffstage: false), findsNWidgets(TasteAttribute.values.length - 2));
    });

    /// The user's own words about the next brew are kept with the ratings.
    testWidgets('keeps the goal for the next brew', (WidgetTester tester) async {
      // Arrange
      await showScreen(tester, _record(samples: _samples));
      await tester.scrollUntilVisible(find.byType(TextField), 300, scrollable: _pageScrollable);

      // Act
      await tester.enterText(find.byType(TextField), 'A little sweeter.');
      await tester.pump();

      // Assert
      expect(find.text('What would you change next time?'), findsOneWidget);
      final FeedbackController controller = tester.state<FeedbackController>(find.byType(FeedbackRoute));
      expect(controller.tastingNotes.goal, 'A little sweeter.');
    });

    /// The screen must fit on the narrowest and widest screens.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768, 1024]) {
        await showScreen(tester, _record(samples: _samples), width: width);
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });
  });
}
