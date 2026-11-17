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
  });
}
