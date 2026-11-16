import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';

/// The JSON schema that brew feedback asks the AI model to answer with.
///
/// The answer is a short summary of the cup, one primary suggestion, and up to two other ideas for later brews.
/// Each suggestion names one `RecipeParameter` and one `ChangeDirection` from fixed lists, so the app can build its
/// screen from them, and explains itself in short fields of plain text. A new value is given only for parameters the
/// recipe stores.
///
/// The field descriptions are part of what the model reads, so they also carry instructions, such as how long each
/// field should be. They are kept short, because on-device models accept only a few thousand tokens per request.
abstract final class BrewFeedbackSchema {
  /// The names of the parameters a suggestion can change, matching `RecipeParameter`.
  static const List<String> parameterNames = <String>[
    'grindSize',
    'coffeeDose',
    'waterAmount',
    'bloomWater',
    'bloomTime',
    'pourRate',
    'waterTemperature',
    'brewTime',
  ];

  /// The names of the directions a suggestion can take, matching `ChangeDirection`.
  static const List<String> directionNames = <String>['increase', 'decrease'];

  /// One suggested change.
  static const ResponseSchema suggestion = ResponseSchema.object(
    properties: <String, ResponseSchema>{
      'parameter': ResponseSchema.enumeration(parameterNames, description: 'The one variable to change.'),
      'direction': ResponseSchema.enumeration(
        directionNames,
        description: 'Which way to change it. For grindSize, increase means finer and decrease means coarser.',
      ),
      'title': ResponseSchema.string(description: 'The change as a short instruction of at most six words.'),
      'change':
          ResponseSchema.string(description: 'How much to change it, in plain words, such as "Add 1 g of coffee".'),
      'suggestedValue': ResponseSchema.number(
        description: 'The new value: grams for coffeeDose, waterAmount, and bloomWater, or seconds for bloomTime and '
            'brewTime. Leave it out for other parameters.',
      ),
      'rationale': ResponseSchema.string(
        description: 'One or two sentences on why, citing the brew data or the tasting notes.',
      ),
      'expectedEffect': ResponseSchema.string(description: 'One sentence on how the next cup should taste different.'),
    },
    optionalProperties: <String>['suggestedValue'],
  );

  /// The whole answer.
  static const ResponseSchema schema = ResponseSchema.object(
    properties: <String, ResponseSchema>{
      'summary': ResponseSchema.string(
        description: 'One or two sentences on how the brew went and what the tasting notes suggest.',
      ),
      'primarySuggestion': suggestion,
      'otherIdeas': ResponseSchema.array(
        items: suggestion,
        description: 'Up to two other single changes for later brews, each a different parameter from the primary '
            'suggestion.',
      ),
    },
    optionalProperties: <String>['otherIdeas'],
  );
}
