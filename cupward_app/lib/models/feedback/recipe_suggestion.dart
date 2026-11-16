import 'package:flutter/foundation.dart';

import 'change_direction.dart';
import 'recipe_parameter.dart';

/// One change to try in the next brew, with why it should help.
///
/// [currentValue] and [suggestedValue] are set only for parameters the recipe stores, such as the coffee dose, and only
/// when the suggested value is a small step from the current one. Otherwise the change is described in words alone,
/// in [change].
@immutable
class RecipeSuggestion {
  /// Creates a suggestion to change [parameter] in [direction].
  const RecipeSuggestion({
    required this.parameter,
    required this.direction,
    required this.title,
    required this.change,
    required this.rationale,
    required this.expectedEffect,
    this.currentValue,
    this.suggestedValue,
  });

  /// The variable to change.
  final RecipeParameter parameter;

  /// Which way to change it.
  final ChangeDirection direction;

  /// A short instruction, such as "Grind a little finer".
  final String title;

  /// How much to change it, in words, such as "One or two steps finer on your grinder".
  final String change;

  /// Why the change should help, based on the brew and the tasting notes.
  final String rationale;

  /// How the next cup should taste different.
  final String expectedEffect;

  /// The recipe's value for [parameter], in grams or seconds, or null if the recipe does not store one.
  final double? currentValue;

  /// The value to use next time, in the same unit as [currentValue], or null if the change is described in words only.
  final double? suggestedValue;

  /// Whether the suggestion gives a new recipe value.
  bool get hasValueChange => currentValue != null && suggestedValue != null;

  @override
  bool operator ==(Object other) =>
      other is RecipeSuggestion &&
      other.parameter == parameter &&
      other.direction == direction &&
      other.title == title &&
      other.change == change &&
      other.rationale == rationale &&
      other.expectedEffect == expectedEffect &&
      other.currentValue == currentValue &&
      other.suggestedValue == suggestedValue;

  @override
  int get hashCode =>
      Object.hash(parameter, direction, title, change, rationale, expectedEffect, currentValue, suggestedValue);

  @override
  String toString() => 'RecipeSuggestion(${parameter.name} ${direction.name}: $title)';
}
