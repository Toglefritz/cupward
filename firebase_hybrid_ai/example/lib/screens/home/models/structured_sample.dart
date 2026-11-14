import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

/// An example prompt paired with the schema that its response must match.
///
/// The three [samples] each exercise different schema types, so together they show what a structured response can
/// hold.
@immutable
class StructuredSample {
  /// Creates a sample with a short [label], the [prompt] that is sent, and the [schema] of the response.
  const new({required this.label, required this.prompt, required this.schema});

  /// The name shown on the sample's chip.
  final String label;

  /// The prompt that fills the text field when the sample is chosen.
  final String prompt;

  /// The schema that the response must match.
  final ResponseSchema schema;

  /// An animal fact, which uses strings and an enumeration.
  static const StructuredSample animalFact = StructuredSample(
    label: 'Animal fact',
    prompt: 'Tell me a surprising fact about an animal.',
    schema: ResponseSchema.object(
      description: 'A fact about an animal',
      properties: <String, ResponseSchema>{
        'animal': ResponseSchema.string(description: 'The common name of the animal'),
        'category': ResponseSchema.enumeration(
          <String>['habitat', 'diet', 'behavior', 'anatomy', 'lifespan'],
          description: 'What the fact is about',
        ),
        'fact': ResponseSchema.string(description: 'The fact, in one sentence'),
      },
    ),
  );

  /// A recipe idea, which uses an integer and an array.
  static const StructuredSample recipeIdea = StructuredSample(
    label: 'Recipe idea',
    prompt: 'Suggest a simple weeknight dinner.',
    schema: ResponseSchema.object(
      description: 'A recipe idea',
      properties: <String, ResponseSchema>{
        'name': ResponseSchema.string(description: 'The name of the dish'),
        'servings': ResponseSchema.integer(description: 'How many people the recipe serves'),
        'ingredients': ResponseSchema.array(
          items: ResponseSchema.string(description: 'One ingredient with its quantity'),
          description: 'The ingredients',
        ),
      },
    ),
  );

  /// A sentiment classification of a short review, which uses an enumeration and a number.
  static const StructuredSample reviewSentiment = StructuredSample(
    label: 'Review sentiment',
    prompt:
        'Classify the sentiment of this review: "The battery lasts all day and the screen is bright, but the speakers '
        'are tinny and it took two weeks to arrive."',
    schema: ResponseSchema.object(
      description: 'The sentiment of a product review',
      properties: <String, ResponseSchema>{
        'sentiment': ResponseSchema.enumeration(
          <String>['positive', 'negative', 'mixed', 'neutral'],
          description: 'The overall sentiment',
        ),
        'confidence': ResponseSchema.number(description: 'How confident the classification is, from 0 to 1'),
        'summary': ResponseSchema.string(description: 'A one-sentence summary of the review'),
      },
    ),
  );

  /// The samples offered, in display order.
  static const List<StructuredSample> samples = <StructuredSample>[animalFact, recipeIdea, reviewSentiment];
}
