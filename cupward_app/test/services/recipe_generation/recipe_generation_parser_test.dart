import 'package:cupward/models/recipes/brew_method.dart';
import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:cupward/models/recipes/brew_recipe.dart';
import 'package:cupward/services/recipe_generation/recipe_generation_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recipe_generation_fixtures.dart';

/// Verifies how an AI answer becomes a brewable recipe, what is corrected, and what is rejected.
void main() {
  /// Parses [answer] for a pour-over brew.
  BrewRecipe pourOver(Map<String, dynamic> answer) =>
      RecipeGenerationParser.parse(answer, method: BrewMethod.kalitaWave);

  /// The steps of [answer], replaced with [phases].
  Map<String, dynamic> withPhases(List<Map<String, dynamic>> phases) =>
      RecipeGenerationFixtures.pourOverAnswer()..['phases'] = phases;

  group('RecipeGenerationParser', () {
    /// A complete answer becomes a recipe with step IDs the brewing screen and feedback rely on.
    test('reads a pour-over recipe', () {
      // Act
      final BrewRecipe recipe = pourOver(RecipeGenerationFixtures.pourOverAnswer());

      // Assert
      expect(recipe.id, 'bold-morning-kalita');
      expect(recipe.name, 'Bold Morning Kalita');
      expect(recipe.coffeeGrams, 22);
      expect(recipe.waterGrams, 350);
      expect(recipe.brewTime, const Duration(seconds: 210));
      expect(recipe.phases.map((BrewPhase phase) => phase.id), <String>[
        'prepare',
        'bloom',
        'pour-1',
        'pour-2',
        'pour-3',
        'complete',
      ]);
      expect(recipe.phases[1].duration, const Duration(seconds: 40));
    });

    /// Immersion brews pour all the water at once, then steep.
    test('reads an immersion recipe', () {
      // Act
      final BrewRecipe recipe =
          RecipeGenerationParser.parse(RecipeGenerationFixtures.immersionAnswer(), method: BrewMethod.frenchPress);

      // Assert
      expect(recipe.phases.map((BrewPhase phase) => phase.kind), <BrewPhaseKind>[
        BrewPhaseKind.prepare,
        BrewPhaseKind.pour,
        BrewPhaseKind.steep,
        BrewPhaseKind.complete,
      ]);
      expect(recipe.phases[2].duration, const Duration(minutes: 4));
    });

    /// Small slips are fixed rather than rejected: missing ends, a last target a little off, and an impossible yield.
    test('corrects small slips', () {
      // Arrange
      final Map<String, dynamic> answer = withPhases(<Map<String, dynamic>>[
        <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 55},
        <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 200},
        <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 340},
      ])
        ..['yieldMilliliters'] = 900
        ..['name'] = 'A Very Long Recipe Name That Goes On And On Forever';

      // Act
      final BrewRecipe recipe = pourOver(answer);

      // Assert
      expect(recipe.phases.first.kind, BrewPhaseKind.prepare);
      expect(recipe.phases.last.kind, BrewPhaseKind.complete);
      expect(recipe.phases[3].targetWeightGrams, 350);
      expect(recipe.yieldMilliliters, 306);
      expect(recipe.name.length, lessThanOrEqualTo(RecipeGenerationParser.maxTextLength));
    });

    /// Recipes outside what a home brewer would use, or that the brewing screen cannot guide, are rejected.
    test('rejects recipes that cannot be brewed', () {
      final Map<String, Map<String, dynamic>> bad = <String, Map<String, dynamic>>{
        'too strong': RecipeGenerationFixtures.pourOverAnswer()..['waterGrams'] = 150,
        'no target on a pour': withPhases(<Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour'},
        ]),
        'falling targets': withPhases(<Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 200},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 150},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ]),
        'last target far from the water': withPhases(<Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 200},
        ]),
        'a steep in a pour-over': withPhases(<Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 60},
        ]),
        'an unknown step': withPhases(<Map<String, dynamic>>[
          <String, dynamic>{'kind': 'swirl'},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ]),
      };

      for (final MapEntry<String, Map<String, dynamic>> entry in bad.entries) {
        expect(() => pourOver(entry.value), throwsFormatException, reason: entry.key);
      }
    });

    /// An immersion brew is guided through its steep, so it must have one, with a duration.
    test('rejects an immersion recipe without a timed steep', () {
      final Map<String, dynamic> noSteep = RecipeGenerationFixtures.immersionAnswer()
        ..['phases'] = <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
        ];
      final Map<String, dynamic> untimed = RecipeGenerationFixtures.immersionAnswer()
        ..['phases'] = <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
          <String, dynamic>{'kind': 'steep'},
        ];

      expect(() => RecipeGenerationParser.parse(noSteep, method: BrewMethod.aeroPress), throwsFormatException);
      expect(() => RecipeGenerationParser.parse(untimed, method: BrewMethod.aeroPress), throwsFormatException);
    });

    /// The recipe records the method it was made for, so it can be stored and shown.
    test('records the method', () {
      expect(pourOver(RecipeGenerationFixtures.pourOverAnswer()).method, BrewMethod.kalitaWave);
      expect(
        RecipeGenerationParser.parse(RecipeGenerationFixtures.immersionAnswer(), method: BrewMethod.aeroPress).method,
        BrewMethod.aeroPress,
      );
    });

    /// A steep is timed, not weighed. A target on it could never be reached by pouring, so it is dropped, and the last
    /// pour takes the total water.
    test('drops a target weight on a steep', () {
      // Arrange
      final Map<String, dynamic> answer = RecipeGenerationFixtures.immersionAnswer()
        ..['phases'] = <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 290},
          <String, dynamic>{'kind': 'steep', 'targetWeightGrams': 300, 'durationSeconds': 240},
        ];
      // Act
      final BrewRecipe recipe = RecipeGenerationParser.parse(answer, method: BrewMethod.frenchPress);
      // Assert
      expect(recipe.phases[1].targetWeightGrams, 300);
      expect(recipe.phases[2].targetWeightGrams, isNull);
      expect(recipe.phases[2].duration, const Duration(minutes: 4));
    });

    /// A duration on a pour would make the brewing screen wait after it, which the recipe did not mean.
    test('drops a duration on a pour', () {
      final BrewRecipe recipe = pourOver(
        withPhases(<Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 175, 'durationSeconds': 20},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ]),
      );
      expect(recipe.phases[1].duration, isNull);
    });

    /// The steps must follow the pattern the brewing screen guides for the method.
    test('rejects steps out of order for the method', () {
      final Map<String, List<Map<String, dynamic>>> pourOverBad = <String, List<Map<String, dynamic>>>{
        'a bloom after a pour': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 170},
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 220},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ],
        'two blooms': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 40},
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 80},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ],
        'only a bloom': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 350},
        ],
      };
      for (final MapEntry<String, List<Map<String, dynamic>>> entry in pourOverBad.entries) {
        expect(() => pourOver(withPhases(entry.value)), throwsFormatException, reason: entry.key);
      }
      final Map<String, List<Map<String, dynamic>>> immersionBad = <String, List<Map<String, dynamic>>>{
        'a bloom': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 40},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 240},
        ],
        'a pour after the steep': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 150},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 240},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
        ],
        'two steeps': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 120},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 120},
        ],
        'only a steep': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 240},
        ],
      };
      for (final MapEntry<String, List<Map<String, dynamic>>> entry in immersionBad.entries) {
        final Map<String, dynamic> answer = RecipeGenerationFixtures.immersionAnswer()..['phases'] = entry.value;
        expect(
          () => RecipeGenerationParser.parse(answer, method: BrewMethod.frenchPress),
          throwsFormatException,
          reason: entry.key,
        );
      }
    });

    /// The brewing screen needs a clear rise on the scale to finish a step, so each step must add enough water.
    test('rejects a step that adds too little water', () {
      final Map<String, List<Map<String, dynamic>>> bad = <String, List<Map<String, dynamic>>>{
        'a tiny first step': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'bloom', 'targetWeightGrams': 5},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ],
        'a tiny pour': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 200},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 204},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 350},
        ],
        // 345 passes the rise check, but is snapped to the 350 g of water, only 5 g above the pour before.
        'a last pour that shrinks when it is snapped': <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 345},
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 355},
        ],
      };
      for (final MapEntry<String, List<Map<String, dynamic>>> entry in bad.entries) {
        expect(() => pourOver(withPhases(entry.value)), throwsFormatException, reason: entry.key);
      }
    });

    /// The brew time covers the timed steps, so one shorter than them is raised to their total.
    test('raises a brew time shorter than the timed steps', () {
      final Map<String, dynamic> answer = RecipeGenerationFixtures.immersionAnswer()..['brewTimeSeconds'] = 60;
      final BrewRecipe recipe = RecipeGenerationParser.parse(answer, method: BrewMethod.frenchPress);
      expect(recipe.brewTime, const Duration(minutes: 4));
    });

    /// Timed steps longer than the longest brew are not a slip that can be corrected.
    test('rejects timed steps longer than the longest brew', () {
      final Map<String, dynamic> answer = RecipeGenerationFixtures.immersionAnswer()
        ..['phases'] = <Map<String, dynamic>>[
          <String, dynamic>{'kind': 'pour', 'targetWeightGrams': 300},
          <String, dynamic>{'kind': 'steep', 'durationSeconds': 901},
        ];
      expect(() => RecipeGenerationParser.parse(answer, method: BrewMethod.frenchPress), throwsFormatException);
    });

    /// A yield of less than half the water is not plausible, so it is worked out instead.
    test('replaces an implausibly small yield', () {
      final BrewRecipe recipe = pourOver(RecipeGenerationFixtures.pourOverAnswer()..['yieldMilliliters'] = 20);
      expect(recipe.yieldMilliliters, 306);
    });

    /// Shortening a name must not split an emoji, which Firestore would reject.
    test('shortens a name without splitting an emoji', () {
      final BrewRecipe recipe = pourOver(RecipeGenerationFixtures.pourOverAnswer()..['name'] = '${'a' * 39}☕☕');
      expect(recipe.name, '${'a' * 39}☕');
      final BrewRecipe astral = pourOver(RecipeGenerationFixtures.pourOverAnswer()..['name'] = '${'a' * 39}😀😀');
      expect(astral.name, '${'a' * 39}😀');
    });

    /// A name of only symbols would not give an ID of its own.
    test('rejects a name without letters or digits', () {
      expect(() => pourOver(RecipeGenerationFixtures.pourOverAnswer()..['name'] = '☕ ☕'), throwsFormatException);
    });
  });
}
