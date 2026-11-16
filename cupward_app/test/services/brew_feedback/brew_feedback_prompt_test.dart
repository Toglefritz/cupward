import 'package:cupward/models/brews/brew_record.dart';
import 'package:cupward/models/brews/brew_sample.dart';
import 'package:cupward/models/feedback/change_direction.dart';
import 'package:cupward/models/feedback/recipe_parameter.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_prompt.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brew_feedback_fixtures.dart';

/// Verifies what the prompt tells the model about the brew, and that it stays small enough for on-device models.
void main() {
  group('BrewFeedbackPrompt', () {
    /// The model compares the brew with the recipe and the tasting notes, so all three must be in the data.
    test('includes the recipe, the brew, and the tasting notes', () {
      // Act
      final Map<String, Object?> data =
          BrewFeedbackPrompt.data(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes());

      // Assert
      final Map<String, Object?> recipe = data['recipe']! as Map<String, Object?>;
      final Map<String, Object?> brew = data['brew']! as Map<String, Object?>;
      expect(recipe['ratio'], '1:16');
      expect(brew['totalTimeSeconds'], 192);
      expect(brew['finalWaterGrams'], 318.4);
      expect((data['tasting']! as Map<String, Object?>)['goal'], 'Sweeter and fuller.');
    });

    /// Each step is summarized rather than listed reading by reading.
    test('summarizes each step', () {
      // Act
      final Map<String, Object?> brew =
          BrewFeedbackPrompt.data(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes())['brew']!
              as Map<String, Object?>;
      final List<Map<String, Object?>> steps = (brew['steps']! as List<Object?>).cast<Map<String, Object?>>();

      // Assert
      expect(steps.first, <String, Object?>{
        'step': 'bloom',
        'durationSeconds': 50,
        'endWeightGrams': 62.0,
        'pouredGrams': 62.0,
        'averagePourRateGramsPerSecond': 6.2,
      });
      expect(steps[1]['pouredGrams'], 99.0);
      expect((brew['weightGramsEvery10Seconds']! as List<Object?>).length, 19);
    });

    /// Without a scale, the model is told so and given no weights.
    test('says when no scale was used', () {
      // Arrange
      final BrewRecord full = BrewFeedbackFixtures.brew();
      final BrewRecord withoutScale = BrewRecord(
        recipe: full.recipe,
        startedAt: full.startedAt,
        totalTime: full.totalTime,
        phases: full.phases,
        samples: const <BrewSample>[],
      );

      // Act
      final Map<String, Object?> brew =
          BrewFeedbackPrompt.data(withoutScale, BrewFeedbackFixtures.notes())['brew']! as Map<String, Object?>;

      // Assert
      expect(brew['scaleUsed'], isFalse);
      expect(brew.containsKey('finalWaterGrams'), isFalse);
      expect(brew.keys.where((String key) => key.startsWith('weightGrams')), isEmpty);
    });

    /// On-device models accept about 4,000 tokens, which is roughly 16,000 characters of English and JSON. The prompt
    /// leaves room for the schema instructions and the answer.
    test('stays well within the on-device token limit', () {
      final String prompt = BrewFeedbackPrompt.build(BrewFeedbackFixtures.brew(), BrewFeedbackFixtures.notes());

      expect(prompt.length, lessThan(5000));
      expect(prompt, contains('exactly one primary change'));
    });
  });

  group('BrewFeedbackSchema', () {
    /// The model answers with the schema's names, and the app reads them back as enum values.
    test('lists the same names as the enums', () {
      expect(BrewFeedbackSchema.parameterNames, RecipeParameter.values.map((RecipeParameter p) => p.name).toList());
      expect(BrewFeedbackSchema.directionNames, ChangeDirection.values.map((ChangeDirection d) => d.name).toList());
    });

    /// A well-formed answer passes the same check the plugin applies.
    test('accepts a well-formed answer', () {
      expect(BrewFeedbackSchema.schema.validate(BrewFeedbackFixtures.answer()), isEmpty);
    });
  });
}
