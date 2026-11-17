import 'package:flutter/foundation.dart';

import 'brew_method.dart';

/// What the user asked for when creating a new recipe: the brewing method, and their taste preferences in their own
/// words.
///
/// This is the input for building the recipe. The JSON form is below.
///
/// ```json
/// { "method": "v60", "preferences": "A strong cup from a medium-dark roast, about 350 ml." }
/// ```
@immutable
class NewRecipeRequest {
  /// Creates a request for a recipe brewed with [method], shaped by [preferences].
  const NewRecipeRequest({required this.method, required this.preferences});

  /// Creates a request from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or has the wrong type, or the method is unknown.
  factory NewRecipeRequest.fromJson(Map<String, dynamic> json) {
    try {
      return NewRecipeRequest(
        method: BrewMethod.fromName(json['method'] as String),
        preferences: json['preferences'] as String,
      );
    } catch (e) {
      throw FormatException('Failed to parse NewRecipeRequest from JSON: $e');
    }
  }

  /// The longest the preferences can be. Enough for a few sentences, and short enough to keep a prompt focused.
  static const int maxPreferencesLength = 300;

  /// How the recipe will be brewed.
  final BrewMethod method;

  /// How the user likes their coffee, in their own words.
  final String preferences;

  /// Converts the request to its JSON form, described on the class. The preferences are trimmed.
  Map<String, dynamic> toJson() => <String, dynamic>{'method': method.name, 'preferences': preferences.trim()};

  @override
  bool operator ==(Object other) =>
      other is NewRecipeRequest && other.method == method && other.preferences == preferences;

  @override
  int get hashCode => Object.hash(method, preferences);

  @override
  String toString() => 'NewRecipeRequest(${method.name})';
}
