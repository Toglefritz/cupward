import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/l10n/app_localizations_en.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/components/brew_phase_indicator.dart';
import 'package:cupward/screens/brew/components/brew_phase_labels.dart';
import 'package:cupward/screens/brew/components/brew_phase_marker.dart';
import 'package:cupward/screens/brew/models/brew_phase_status.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies how phases are named, how each phase's status follows from the current phase, and that the indicator
/// shows the phases and announces the brew's progress. The indicator is shown on its own, with English strings.
void main() {
  /// The phases of the V60 pour over, which has every kind of phase and more than one pour.
  final List<BrewPhase> phases = BuiltInRecipes.v60PourOver.phases;

  /// Shows the indicator for [phases] with the brew at [currentIndex], at the given screen [width].
  Future<void> showIndicator(WidgetTester tester, int currentIndex, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BrewPhaseIndicator(phases: phases, currentIndex: currentIndex)),
      ),
    );
  }

  group('BrewPhaseLabels', () {
    /// Pours are numbered among the pours only, so the bloom before them does not shift the numbers.
    test('names each phase by its kind and numbers the pours', () {
      final AppLocalizations strings = AppLocalizationsEn();

      final List<String> labels = <String>[
        for (int index = 0; index < phases.length; index++) BrewPhaseLabels.labelFor(phases, index, strings),
      ];

      expect(labels, <String>['Prepare', 'Bloom', 'Pour 1', 'Pour 2', 'Pour 3', 'Complete']);
    });
  });

  group('BrewPhaseStatus', () {
    /// Phases before the current one are finished and those after it have not started.
    test('follows from the position of the current phase', () {
      expect(BrewPhaseStatus.of(0, 2), BrewPhaseStatus.completed);
      expect(BrewPhaseStatus.of(2, 2), BrewPhaseStatus.current);
      expect(BrewPhaseStatus.of(3, 2), BrewPhaseStatus.upcoming);
    });
  });

  group('BrewPhaseIndicator', () {
    /// Every phase must be visible so the user can see the whole brew ahead of them.
    testWidgets('shows every phase by name', (WidgetTester tester) async {
      // Act
      await showIndicator(tester, 0);

      // Assert
      for (final String label in <String>['Prepare', 'Bloom', 'Pour 1', 'Pour 2', 'Pour 3', 'Complete']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    /// The markers are how the user sees their progress, so each status must be drawn for the right phases.
    testWidgets('marks finished, current, and upcoming phases', (WidgetTester tester) async {
      // Act
      await showIndicator(tester, 2);

      // Assert
      final List<BrewPhaseStatus> statuses = tester
          .widgetList<BrewPhaseMarker>(find.byType(BrewPhaseMarker))
          .map((BrewPhaseMarker marker) => marker.status)
          .toList();
      expect(statuses, <BrewPhaseStatus>[
        BrewPhaseStatus.completed,
        BrewPhaseStatus.completed,
        BrewPhaseStatus.current,
        BrewPhaseStatus.upcoming,
        BrewPhaseStatus.upcoming,
        BrewPhaseStatus.upcoming,
      ]);
    });

    /// Screen readers must hear where the user is in the brew, as one announcement rather than six labels.
    testWidgets('announces the current step to screen readers', (WidgetTester tester) async {
      // Arrange
      final SemanticsHandle handle = tester.ensureSemantics();

      // Act
      await showIndicator(tester, 1);

      // Assert
      expect(find.bySemanticsLabel('Step 2 of 6, Bloom'), findsOneWidget);
      handle.dispose();
    });

    /// Six labels share the width, so the indicator must fit on the narrowest phones as well as on tablets.
    testWidgets('fits on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768]) {
        await showIndicator(tester, 5, width: width);

        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });

    /// A recipe for another method can have a different set of phases, and the indicator must show them as well.
    testWidgets('shows the phases of any recipe', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(412, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: BrewPhaseIndicator(
              phases: <BrewPhase>[
                BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
                BrewPhase(id: 'pour', kind: BrewPhaseKind.pour),
                BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
              ],
              currentIndex: 1,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Pour 1'), findsOneWidget);
      expect(tester.widgetList(find.byType(BrewPhaseMarker)), hasLength(3));
    });
  });
}
