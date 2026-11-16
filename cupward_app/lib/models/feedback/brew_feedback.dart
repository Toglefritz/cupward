import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter/foundation.dart';

import 'recipe_suggestion.dart';

/// What brew feedback recommends after a brew: a short read of the cup, one change to try next, and a few ideas for
/// later.
///
/// The [primary] suggestion is the one change to make in the next brew. Changing one variable at a time lets the user
/// taste what that change did, so the [alternatives] are meant for later brews, not to be combined with it.
@immutable
class BrewFeedback {
  /// Creates feedback with a [summary], a [primary] suggestion, and [alternatives], produced by [source].
  const BrewFeedback({
    required this.summary,
    required this.primary,
    required this.alternatives,
    required this.source,
  });

  /// One or two sentences on how the brew went and what the tasting notes suggest.
  final String summary;

  /// The one change to try in the next brew.
  final RecipeSuggestion primary;

  /// Other changes worth trying in later brews, one at a time. May be empty.
  final List<RecipeSuggestion> alternatives;

  /// Which model produced the feedback: the on-device model or the cloud model.
  final InferenceSource source;

  @override
  String toString() => 'BrewFeedback(${primary.parameter.name}, ${alternatives.length} alternatives, ${source.name})';
}
