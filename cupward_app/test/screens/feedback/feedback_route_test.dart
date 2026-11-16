import 'package:cupward/components/recipe_summary_card.dart';
import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/models/brews/brew_phase_record.dart';
import 'package:cupward/models/brews/brew_record.dart';
import 'package:cupward/models/brews/brew_sample.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/feedback/components/brew_weight_chart.dart';
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

    /// The screen must fit on the narrowest and widest screens.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768, 1024]) {
        await showScreen(tester, _record(samples: _samples), width: width);
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });
  });
}
