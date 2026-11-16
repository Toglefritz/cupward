import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';

import '../../models/feedback/brew_feedback.dart';
import '../../models/feedback/change_direction.dart';
import '../../models/feedback/recipe_parameter.dart';
import '../../models/feedback/recipe_suggestion.dart';
import '../../models/recipes/brew_phase.dart';
import '../../models/recipes/brew_phase_kind.dart';
import '../../models/recipes/brew_recipe.dart';

/// Turns the AI model's answer, decoded from JSON in the shape of `BrewFeedbackSchema`, into a [BrewFeedback].
///
/// The answer has already been checked against the schema, but the parser still guards what the schema cannot:
///
/// * A suggested value is kept only when it moves the recipe's value the way the suggestion says, and by at most
///   [maxRelativeChange]. A larger or contradictory value is dropped, and the change is shown in words alone, so a
///   slip by the model never becomes a large change to the recipe.
/// * At most [maxAlternatives] other ideas are kept, and any that change the same parameter as the primary suggestion,
///   or a parameter already listed, are left out.
abstract final class BrewFeedbackParser {
  /// The largest change to a recipe value that a suggestion may make, as a fraction of the current value.
  static const double maxRelativeChange = 0.25;

  /// The most other ideas that are shown.
  static const int maxAlternatives = 2;

  /// Returns the feedback in [data], with values compared against [recipe], produced by [source].
  ///
  /// Throws a [FormatException] if the summary or the primary suggestion is missing or malformed.
  static BrewFeedback parse(Object? data, {required BrewRecipe recipe, required InferenceSource source}) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Brew feedback must be a JSON object.');
    }

    final String summary = _requiredText(data, 'summary');
    final RecipeSuggestion primary = _suggestion(data['primarySuggestion'], recipe) ??
        (throw const FormatException('Brew feedback has no valid primary suggestion.'));

    final Set<RecipeParameter> seen = <RecipeParameter>{primary.parameter};
    final List<RecipeSuggestion> alternatives = <RecipeSuggestion>[];
    final Object? ideas = data['otherIdeas'];
    if (ideas is List<dynamic>) {
      for (final Object? idea in ideas) {
        final RecipeSuggestion? suggestion = _suggestion(idea, recipe);
        if (suggestion != null && seen.add(suggestion.parameter)) {
          alternatives.add(suggestion);
        }
        if (alternatives.length == maxAlternatives) {
          break;
        }
      }
    }

    return BrewFeedback(
      summary: summary,
      primary: primary,
      alternatives: List<RecipeSuggestion>.unmodifiable(alternatives),
      source: source,
    );
  }

  /// Returns the recipe's value for [parameter], in grams or seconds, or null if the recipe does not store one.
  static double? currentValue(RecipeParameter parameter, BrewRecipe recipe) {
    final BrewPhase? bloom = _bloom(recipe);
    switch (parameter) {
      case RecipeParameter.coffeeDose:
        return recipe.coffeeGrams;
      case RecipeParameter.waterAmount:
        return recipe.waterGrams;
      case RecipeParameter.bloomWater:
        return bloom?.targetWeightGrams;
      case RecipeParameter.bloomTime:
        return bloom?.duration?.inSeconds.toDouble();
      case RecipeParameter.brewTime:
        return recipe.brewTime.inSeconds.toDouble();
      case RecipeParameter.grindSize:
      case RecipeParameter.pourRate:
      case RecipeParameter.waterTemperature:
        return null;
    }
  }

  /// Returns the suggestion in [value], or null if it is malformed.
  static RecipeSuggestion? _suggestion(Object? value, BrewRecipe recipe) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    try {
      final RecipeParameter parameter = RecipeParameter.tryFromName(_requiredText(value, 'parameter')) ??
          (throw const FormatException('Unknown parameter.'));
      final ChangeDirection direction = ChangeDirection.tryFromName(_requiredText(value, 'direction')) ??
          (throw const FormatException('Unknown direction.'));
      final double? current = parameter.hasRecipeValue ? currentValue(parameter, recipe) : null;
      final Object? suggested = value['suggestedValue'];

      return RecipeSuggestion(
        parameter: parameter,
        direction: direction,
        title: _requiredText(value, 'title'),
        change: _requiredText(value, 'change'),
        rationale: _requiredText(value, 'rationale'),
        expectedEffect: _requiredText(value, 'expectedEffect'),
        currentValue: current,
        suggestedValue: current != null && suggested is num && _isSmallStep(current, suggested.toDouble(), direction)
            ? suggested.toDouble()
            : null,
      );
    } on FormatException {
      return null;
    }
  }

  /// Whether moving from [current] to [suggested] goes in [direction] by no more than [maxRelativeChange].
  static bool _isSmallStep(double current, double suggested, ChangeDirection direction) {
    if (current <= 0 || suggested <= 0) {
      return false;
    }
    final double difference = suggested - current;
    final bool rightWay = direction == ChangeDirection.increase ? difference > 0 : difference < 0;
    return rightWay && difference.abs() / current <= maxRelativeChange;
  }

  /// Returns the recipe's bloom phase, or null if it has none.
  static BrewPhase? _bloom(BrewRecipe recipe) {
    for (final BrewPhase phase in recipe.phases) {
      if (phase.kind == BrewPhaseKind.bloom) {
        return phase;
      }
    }
    return null;
  }

  /// Returns the trimmed text under [key] in [map], and throws a [FormatException] if it is missing or empty.
  static String _requiredText(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing text for $key.');
    }
    return value.trim();
  }
}
