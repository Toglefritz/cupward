import 'dart:io';

import 'package:cupward/l10n/app_localizations.dart';
import 'package:cupward/l10n/app_localizations_en.dart';
import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/screens/brew/components/brew_phase_labels.dart';
import 'package:cupward/screens/brew/components/brew_step_heading.dart';
import 'package:cupward/theme/brew_step_image.dart';
import 'package:cupward/theme/cupward_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A pour over with a bloom and two pours.
const List<BrewPhase> _twoPours = <BrewPhase>[
  BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
  BrewPhase(id: 'bloom', kind: BrewPhaseKind.bloom, targetWeightGrams: 50),
  BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 180),
  BrewPhase(id: 'pour-2', kind: BrewPhaseKind.pour, targetWeightGrams: 300),
  BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
];

/// An immersion brew: one pour, then a steep.
const List<BrewPhase> _immersion = <BrewPhase>[
  BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
  BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 300),
  BrewPhase(id: 'steep', kind: BrewPhaseKind.steep, duration: Duration(minutes: 4)),
  BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
];

/// Verifies the title, instructions, and illustration for each phase and brewing method, and that the heading shows the
/// step count, title, and instructions for the current phase. The heading is shown on its own, with English strings.
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

  /// An immersion recipe's steep is named and explained like the other steps, in one short sentence.
  test('labels the steep step', () {
    // Arrange
    final AppLocalizations strings = AppLocalizationsEn();
    const List<BrewPhase> phases = <BrewPhase>[
      BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
      BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 300),
      BrewPhase(id: 'steep', kind: BrewPhaseKind.steep, duration: Duration(minutes: 4)),
      BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
    ];

    // Act
    final String instructions = BrewPhaseLabels.instructionsFor(phases, 2, strings);

    // Assert
    expect(BrewPhaseLabels.labelFor(phases, 2, strings), 'Steep');
    expect(BrewPhaseLabels.titleFor(phases, 2, strings), 'Steep');
    expect(BrewPhaseLabels.actionLabelFor(phases, 2, strings), 'Next step');
    expect(
      BrewPhaseLabels.imageFor(method: BrewMethod.frenchPress, phases: phases, index: 2),
      BrewStepImage.frenchPressSteep,
    );
    expect(instructions.length, lessThanOrEqualTo(80));
    expect('.'.allMatches(instructions), hasLength(1));
  });

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
        for (int i = 0; i < phases.length; i++)
          BrewPhaseLabels.imageFor(method: BrewMethod.v60, phases: phases, index: i),
      ];

      expect(images, <BrewStepImage>[
        BrewStepImage.v60Prepare,
        BrewStepImage.v60Bloom,
        BrewStepImage.v60Pour1,
        BrewStepImage.v60Pour2,
        BrewStepImage.v60Pour3,
        BrewStepImage.v60Complete,
      ]);
    });

    /// A method has images for only a few pours, so a recipe with more pours must still show one instead of failing.
    test('uses the last pour image for later pours', () {
      const List<BrewPhase> manyPours = <BrewPhase>[
        BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour),
        BrewPhase(id: 'pour-2', kind: BrewPhaseKind.pour),
        BrewPhase(id: 'pour-3', kind: BrewPhaseKind.pour),
        BrewPhase(id: 'pour-4', kind: BrewPhaseKind.pour),
      ];

      expect(BrewPhaseLabels.imageFor(method: BrewMethod.v60, phases: manyPours, index: 3), BrewStepImage.v60Pour3);
      expect(
        BrewPhaseLabels.imageFor(method: BrewMethod.chemex, phases: manyPours, index: 2),
        BrewStepImage.chemexPour2,
      );
    });

    /// Each method shows its own brewer. The Kalita Wave looks like a V60 in this style, so it shares those images.
    test("shows the brewer of the recipe's method", () {
      List<BrewStepImage> imagesFor(BrewMethod method, List<BrewPhase> phases) => <BrewStepImage>[
            for (int i = 0; i < phases.length; i++) BrewPhaseLabels.imageFor(method: method, phases: phases, index: i),
          ];

      expect(imagesFor(BrewMethod.kalitaWave, _twoPours), imagesFor(BrewMethod.v60, _twoPours));
      expect(imagesFor(BrewMethod.chemex, _twoPours), <BrewStepImage>[
        BrewStepImage.chemexPrepare,
        BrewStepImage.chemexBloom,
        BrewStepImage.chemexPour1,
        BrewStepImage.chemexPour2,
        BrewStepImage.chemexComplete,
      ]);
      expect(imagesFor(BrewMethod.frenchPress, _immersion), <BrewStepImage>[
        BrewStepImage.frenchPressPrepare,
        BrewStepImage.frenchPressPour1,
        BrewStepImage.frenchPressSteep,
        BrewStepImage.frenchPressComplete,
      ]);
      expect(imagesFor(BrewMethod.aeroPress, _immersion), <BrewStepImage>[
        BrewStepImage.aeroPressPrepare,
        BrewStepImage.aeroPressPour1,
        BrewStepImage.aeroPressSteep,
        BrewStepImage.aeroPressComplete,
      ]);
      expect(imagesFor(BrewMethod.cleverDripper, _immersion), <BrewStepImage>[
        BrewStepImage.cleverDripperPrepare,
        BrewStepImage.cleverDripperPour1,
        BrewStepImage.cleverDripperSteep,
        BrewStepImage.cleverDripperComplete,
      ]);
    });
  });

  group('BrewStepImage', () {
    /// A wrong path only shows up as a broken image at run time, so every path must name a bundled file.
    test('names a file in the assets for every image', () {
      for (final BrewStepImage image in BrewStepImage.values) {
        expect(image.path, startsWith('assets/brew_steps/'));
        expect(File(image.path).existsSync(), isTrue, reason: image.path);
      }
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

    /// Each step with a target weight names it, so the user does not have to remember the number from the recipe.
    testWidgets('shows the target weight of the bloom and each pour', (WidgetTester tester) async {
      // Act and assert
      for (final MapEntry<int, String> expected in <int, String>{
        1: 'Target 60 g',
        2: 'Target 160 g',
        3: 'Target 240 g',
        4: 'Target 320 g',
      }.entries) {
        await showHeading(tester, expected.key);
        expect(find.text(expected.value), findsOneWidget, reason: 'step ${expected.key}');
      }
    });

    /// Preparation and completion have no weight to pour to, so no target line is shown.
    testWidgets('shows no target for steps without one', (WidgetTester tester) async {
      for (final int index in <int>[0, 5]) {
        await showHeading(tester, index);
        expect(find.textContaining('Target'), findsNothing, reason: 'step $index');
      }
    });

    /// A target that is not a whole number keeps one decimal place, instead of being rounded to a misleading figure.
    test('shows a fractional target with one decimal place', () {
      const List<BrewPhase> custom = <BrewPhase>[
        BrewPhase(id: 'pour-1', kind: BrewPhaseKind.pour, targetWeightGrams: 62.5),
      ];

      expect(BrewPhaseLabels.targetFor(custom, 0, AppLocalizationsEn()), 'Target 62.5 g');
    });
  });
}
