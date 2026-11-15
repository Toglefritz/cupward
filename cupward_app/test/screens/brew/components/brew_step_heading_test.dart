import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/l10n/app_localizations_en.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/components/brew_phase_labels.dart';
import 'package:cupward/screens/brew/components/brew_step_heading.dart';
import 'package:cupward/theme/brew_step_image.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Verifies the title and instructions for each phase, and that the heading shows the step count, title, and
/// instructions for the current phase. The heading is shown on its own, with English strings.
void main() {
  /// The phases of the V60 pour over, which has every kind of phase and more than one pour.
  final List<BrewPhase> phases = BuiltInRecipes.v60PourOver.phases;

  /// Shows the heading with the brew at [currentIndex], at the given screen [width].
  Future<void> showHeading(WidgetTester tester, int currentIndex, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[CupwardColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BrewStepHeading(phases: phases, currentIndex: currentIndex)),
      ),
    );
  }

  group('BrewPhaseLabels', () {
    /// Each phase needs its own title, and pours are numbered among the pours only.
    test('gives every phase a title', () {
      final AppLocalizations strings = AppLocalizationsEn();

      final List<String> titles = <String>[
        for (int i = 0; i < phases.length; i++) BrewPhaseLabels.titleFor(phases, i, strings),
      ];

      expect(titles, <String>[
        'Prepare to Brew',
        'Bloom',
        'Pour 1',
        'Pour 2',
        'Pour 3',
        'Enjoy Your Coffee',
      ]);
    });

    /// The user reads the instructions mid-brew, so each one must be a single short sentence.
    test('keeps every instruction to one short sentence', () {
      final AppLocalizations strings = AppLocalizationsEn();

      for (int index = 0; index < phases.length; index++) {
        final String instructions = BrewPhaseLabels.instructionsFor(phases, index, strings);

        expect(instructions, isNotEmpty);
        expect(instructions.length, lessThanOrEqualTo(80), reason: instructions);
        expect('.'.allMatches(instructions), hasLength(1), reason: instructions);
      }
    });
  });

  group('BrewPhaseLabels.imageFor', () {
    /// Each pour over step has its own illustration, and pours use the image for their position.
    test('gives every phase of the pour over its own image', () {
      final List<BrewStepImage> images = <BrewStepImage>[
        for (int i = 0; i < phases.length; i++) BrewPhaseLabels.imageFor(phases, i),
      ];

      expect(images, <BrewStepImage>[
        BrewStepImage.prepare,
        BrewStepImage.bloom,
        BrewStepImage.pour1,
        BrewStepImage.pour2,
        BrewStepImage.pour3,
        BrewStepImage.complete,
      ]);
    });

    /// There are only three pour images, so a recipe with more pours must still show one instead of failing.
    test('uses the third pour image for later pours', () {
      const List<BrewPhase> manyPours = <BrewPhase>[
        BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour),
        BrewPhase(id: 'pour-2', kind: BrewPhaseKind.pour),
        BrewPhase(id: 'pour-3', kind: BrewPhaseKind.pour),
        BrewPhase(id: 'pour-4', kind: BrewPhaseKind.pour),
      ];

      expect(BrewPhaseLabels.imageFor(manyPours, 3), BrewStepImage.pour3);
    });
  });

  group('BrewStepHeading', () {
    /// The concept shows the count, the title, and the instructions for the first step.
    testWidgets('shows the count, title, and instructions of the current step', (WidgetTester tester) async {
      // Act
      await showHeading(tester, 0);

      // Assert
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Prepare to Brew'), findsOneWidget);
      expect(find.text('Set up your brewer, place it on the scale, and tare.'), findsOneWidget);
    });

    /// The heading must follow the brew, so a later phase shows its own count and text.
    testWidgets('follows the current phase', (WidgetTester tester) async {
      // Act
      await showHeading(tester, 3);

      // Assert
      expect(find.text('STEP 4 OF 6'), findsOneWidget);
      expect(find.text('Pour 2'), findsOneWidget);
    });

    /// Screen reader users navigate by headings, so the title must be one.
    testWidgets('marks the title as a heading', (WidgetTester tester) async {
      // Arrange
      final SemanticsHandle handle = tester.ensureSemantics();

      // Act
      await showHeading(tester, 0);

      // Assert
      expect(
        tester.getSemantics(find.text('Prepare to Brew')),
        matchesSemantics(label: 'Prepare to Brew', isHeader: true),
      );
      handle.dispose();
    });

    /// The longest title must wrap rather than overflow on the narrowest phones.
    testWidgets('fits every step on narrow and wide screens', (WidgetTester tester) async {
      for (final double width in <double>[320, 412, 768]) {
        for (int index = 0; index < phases.length; index++) {
          await showHeading(tester, index, width: width);

          expect(tester.takeException(), isNull, reason: 'width $width, step $index');
        }
      }
    });
  });
}
