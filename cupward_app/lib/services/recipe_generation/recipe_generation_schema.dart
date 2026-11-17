import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';

/// The JSON schema that the AI model is asked to answer with when it creates a recipe.
///
/// The answer is a whole recipe in the app's own terms: a name and a short profile, the coffee and water weights, the
/// brew time, the yield, and the steps. Each step names one kind from a fixed list, so the brewing screen can guide
/// it, with an optional target weight and duration.
///
/// The field descriptions are part of what the model reads, so they also carry instructions, such as the units. They
/// are kept short, because on-device models accept only a few thousand tokens per request.
abstract final class RecipeGenerationSchema {
  /// The names of the step kinds a recipe can use, matching `BrewPhaseKind`.
  static const List<String> phaseKindNames = <String>['prepare', 'bloom', 'pour', 'steep', 'complete'];

  /// One step of the recipe.
  static const ResponseSchema phase = ResponseSchema.object(
    properties: <String, ResponseSchema>{
      'kind': ResponseSchema.enumeration(phaseKindNames, description: 'What happens in the step.'),
      'targetWeightGrams': ResponseSchema.number(
        description: 'The total water on the scale at the end of the step, in grams, counted from zero. Required for '
            'bloom and pour steps.',
      ),
      'durationSeconds': ResponseSchema.integer(
        description: 'How long to wait in the step, in seconds. Required for steep steps; optional for the bloom.',
      ),
    },
    optionalProperties: <String>['targetWeightGrams', 'durationSeconds'],
  );

  /// The whole answer.
  static const ResponseSchema schema = ResponseSchema.object(
    properties: <String, ResponseSchema>{
      'name': ResponseSchema.string(description: 'A short, distinctive recipe name of two to five words.'),
      'profile': ResponseSchema.string(description: 'The cup in two to four words, such as "Bold & Syrupy".'),
      'coffeeGrams': ResponseSchema.number(description: 'The coffee dose, in grams.'),
      'waterGrams': ResponseSchema.number(description: 'The total water, in grams.'),
      'brewTimeSeconds': ResponseSchema.integer(description: 'The total brew time, in seconds.'),
      'yieldMilliliters': ResponseSchema.number(description: 'About how much coffee ends up in the cup, in ml.'),
      'phases': ResponseSchema.array(items: phase, description: 'The steps, in order.'),
    },
  );
}
