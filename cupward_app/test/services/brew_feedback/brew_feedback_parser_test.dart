import 'package:cupward/models/feedback/brew_feedback.dart';
import 'package:cupward/models/feedback/change_direction.dart';
import 'package:cupward/models/feedback/recipe_parameter.dart';
import 'package:cupward/models/feedback/recipe_suggestion.dart';
import 'package:cupward/models/recipes/built_in_recipes.dart';
import 'package:cupward/services/brew_feedback/brew_feedback_parser.dart';
import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brew_feedback_fixtures.dart';

/// Verifies how the AI answer becomes feedback, and the guards that keep suggested changes small.
void main() {
  /// Parses [data] against the default recipe.
  BrewFeedback parse(Object? data) =>
      BrewFeedbackParser.parse(data, recipe: BuiltInRecipes.defaultRecipe, source: InferenceSource.onDevice);

  /// An answer whose primary suggestion is [primary].
  Map<String, dynamic> answerWith(Map<String, dynamic> primary) =>
      BrewFeedbackFixtures.answer()..['primarySuggestion'] = primary;

  group('BrewFeedbackParser', () {
    /// A complete answer becomes feedback with the recipe's current value beside the suggested one.
    test('reads a complete answer', () {
      // Act
      final BrewFeedback feedback = parse(BrewFeedbackFixtures.answer());

      // Assert
      expect(feedback.summary, startsWith('The brew ran'));
      expect(feedback.primary.parameter, RecipeParameter.coffeeDose);
      expect(feedback.primary.direction, ChangeDirection.increase);
      expect(feedback.primary.currentValue, 20);
      expect(feedback.primary.suggestedValue, 21);
      expect(feedback.primary.hasValueChange, isTrue);
      expect(
        feedback.alternatives.map((RecipeSuggestion suggestion) => suggestion.parameter),
        <RecipeParameter>[RecipeParameter.grindSize, RecipeParameter.waterTemperature],
      );
    });

    /// A slip by the model must never become a large change to the recipe.
    test('drops a suggested value that changes too much', () {
      // Act
      final BrewFeedback feedback = parse(answerWith(BrewFeedbackFixtures.suggestion(suggestedValue: 30)));

      // Assert
      expect(feedback.primary.suggestedValue, isNull);
      expect(feedback.primary.hasValueChange, isFalse);
      expect(feedback.primary.change, 'Use 21 g of coffee');
    });

    /// A value that contradicts the stated direction is not trusted.
    test('drops a suggested value that goes the wrong way', () {
      final BrewFeedback feedback = parse(answerWith(BrewFeedbackFixtures.suggestion(suggestedValue: 19)));

      expect(feedback.primary.suggestedValue, isNull);
    });

    /// Times are compared in seconds against the recipe's bloom rest.
    test('reads a bloom time against the recipe', () {
      final BrewFeedback feedback = parse(
        answerWith(BrewFeedbackFixtures.suggestion(parameter: 'bloomTime', suggestedValue: 55)),
      );

      expect(feedback.primary.currentValue, 45);
      expect(feedback.primary.suggestedValue, 55);
    });

    /// The grind is not in the recipe, so a number for it has nothing to compare with.
    test('ignores a value for a parameter the recipe does not store', () {
      final BrewFeedback feedback = parse(
        answerWith(BrewFeedbackFixtures.suggestion(parameter: 'grindSize', suggestedValue: 3)),
      );

      expect(feedback.primary.currentValue, isNull);
      expect(feedback.primary.suggestedValue, isNull);
    });

    /// Ideas for later must each be one different change, and there are at most two.
    test('keeps at most two different other ideas', () {
      // Arrange
      final Map<String, dynamic> answer = BrewFeedbackFixtures.answer()
        ..['otherIdeas'] = <Map<String, dynamic>>[
          BrewFeedbackFixtures.suggestion(),
          BrewFeedbackFixtures.suggestion(parameter: 'pourRate', direction: 'decrease', suggestedValue: null),
          BrewFeedbackFixtures.suggestion(parameter: 'pourRate', suggestedValue: null),
          <String, dynamic>{'parameter': 'flavor'},
          BrewFeedbackFixtures.suggestion(parameter: 'brewTime', direction: 'decrease', suggestedValue: 170),
          BrewFeedbackFixtures.suggestion(parameter: 'waterAmount', suggestedValue: 330),
        ];

      // Act
      final BrewFeedback feedback = parse(answer);

      // Assert
      expect(
        feedback.alternatives.map((RecipeSuggestion suggestion) => suggestion.parameter),
        <RecipeParameter>[RecipeParameter.pourRate, RecipeParameter.brewTime],
      );
    });

    /// Without a usable main suggestion there is nothing to show.
    test('rejects an answer without a valid primary suggestion', () {
      expect(() => parse(answerWith(<String, dynamic>{'parameter': 'coffeeDose'})), throwsFormatException);
      expect(
        () => parse(<String, dynamic>{'primarySuggestion': BrewFeedbackFixtures.suggestion()}),
        throwsFormatException,
      );
      expect(() => parse('not an object'), throwsFormatException);
    });
  });
}
