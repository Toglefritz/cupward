import 'package:flutter/foundation.dart';

import 'taste_attribute.dart';

/// What the user tasted in a brew, and how they want the next one to change.
///
/// Each [TasteAttribute] can be rated from [minRating] to [maxRating]. Ratings are optional: an attribute the user did
/// not rate is absent from [ratings], rather than given a middle value, so brew feedback never reads a guess as an
/// answer. [goal] is the user's own words about how they would like the next brew to taste, and may be empty.
///
/// The JSON form is below. The scale's bounds are included so the record explains itself when read by brew feedback.
///
/// ```json
/// {
///   "ratingScale": { "min": 1, "max": 5 },
///   "ratings": { "intensity": 2, "bitterness": 4 },
///   "goal": "A little stronger and less bitter."
/// }
/// ```
@immutable
class TastingNotes {
  /// Creates notes with the given [ratings] and [goal].
  ///
  /// Every rating must be from [minRating] to [maxRating].
  TastingNotes({Map<TasteAttribute, int> ratings = const <TasteAttribute, int>{}, this.goal = ''})
      : assert(
          ratings.values.every((int rating) => rating >= minRating && rating <= maxRating),
          'Ratings must be from $minRating to $maxRating',
        ),
        ratings = Map<TasteAttribute, int>.unmodifiable(ratings);

  /// Creates notes from their JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field has the wrong type, an attribute is unknown, or a rating is out of range.
  factory TastingNotes.fromJson(Map<String, dynamic> json) {
    try {
      final Map<String, dynamic> ratings = json['ratings'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return TastingNotes(
        ratings: <TasteAttribute, int>{
          for (final MapEntry<String, dynamic> entry in ratings.entries)
            TasteAttribute.fromName(entry.key): _checkedRating(entry.value),
        },
        goal: json['goal'] as String? ?? '',
      );
    } catch (e) {
      throw FormatException('Failed to parse TastingNotes from JSON: $e');
    }
  }

  /// The lowest rating: none, or very little, of an attribute.
  static const int minRating = 1;

  /// The highest rating: a lot of an attribute.
  static const int maxRating = 5;

  /// The rating of each attribute the user rated.
  final Map<TasteAttribute, int> ratings;

  /// How the user would like the next brew to taste, in their own words, or an empty string.
  final String goal;

  /// Whether the user has rated nothing and written nothing.
  bool get isEmpty => ratings.isEmpty && goal.trim().isEmpty;

  /// Returns a copy with [attribute] rated [rating], or with its rating removed when [rating] is null.
  TastingNotes withRating(TasteAttribute attribute, int? rating) {
    final Map<TasteAttribute, int> updated = Map<TasteAttribute, int>.of(ratings);
    if (rating == null) {
      updated.remove(attribute);
    } else {
      updated[attribute] = rating;
    }
    return TastingNotes(ratings: updated, goal: goal);
  }

  /// Returns a copy with [goal] as the goal.
  TastingNotes withGoal(String goal) => TastingNotes(ratings: ratings, goal: goal);

  /// Converts the notes to their JSON form, described on the class.
  ///
  /// Ratings are listed in the order of [TasteAttribute.values], and the goal is trimmed.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ratingScale': <String, int>{'min': minRating, 'max': maxRating},
        'ratings': <String, int>{
          for (final TasteAttribute attribute in TasteAttribute.values)
            if (ratings.containsKey(attribute)) attribute.name: ratings[attribute]!,
        },
        'goal': goal.trim(),
      };

  /// Reads a rating from JSON and checks that it is a whole number in range. Asserts do not run in release builds.
  static int _checkedRating(Object? value) {
    if (value is! int || value < minRating || value > maxRating) {
      throw ArgumentError('Rating must be a whole number from $minRating to $maxRating, but is $value');
    }
    return value;
  }

  @override
  bool operator ==(Object other) => other is TastingNotes && mapEquals(other.ratings, ratings) && other.goal == goal;

  @override
  int get hashCode {
    final Iterable<int> entries = ratings.entries.map(
      (MapEntry<TasteAttribute, int> entry) => Object.hash(entry.key, entry.value),
    );
    return Object.hash(Object.hashAllUnordered(entries), goal);
  }

  @override
  String toString() => 'TastingNotes(${ratings.length} ratings, goal: ${goal.isEmpty ? 'none' : '"$goal"'})';
}
