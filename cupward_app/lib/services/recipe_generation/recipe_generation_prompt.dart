import 'dart:convert';

import '../../models/recipes/brew_method.dart';
import '../../models/recipes/new_recipe_request.dart';

/// Builds the prompt that asks the AI model to create a recipe for a brewing method and the user's taste.
///
/// The prompt has three parts: how to design the recipe, the step pattern for the method, and the request as compact
/// JSON. The step patterns match what the brewing screen can guide: pour-over brews are prepare, bloom, a few pours,
/// and complete, and immersion brews are prepare, one pour of all the water, steep, and complete. Weights are
/// cumulative from a tared scale, as the brewing screen expects.
abstract final class RecipeGenerationPrompt {
  /// The design instructions that come first.
  static const String instructions = '''
You are a coffee brewing coach. Design one starting recipe for a home brewer, for the method and taste below.

Rules:
- Base the ratio on the taste: about 1:15 to 1:17 for pour-over and 1:12 to 1:16 for immersion. A stronger cup uses less water per gram of coffee.
- If a cup size is given, choose the water to match it. Otherwise make one cup of about 300 ml.
- Target weights are the total water on the scale after each step, counted from zero, so they only go up and the last one equals the total water.
- The yield is the water less what the grounds hold, about twice the coffee weight.
- The name is short and distinctive. The profile describes the cup in two to four words.''';

  /// The step pattern for pour-over methods.
  static const String pourOverSteps = '''
Steps for this method: prepare; bloom with about two to three times the coffee weight in water and a rest of 30 to 45 seconds; two to four pours; complete.''';

  /// The step pattern for immersion methods.
  static const String immersionSteps = '''
Steps for this method: prepare; one pour of all the water; steep for the steeping time in durationSeconds; complete.''';

  /// Returns the prompt for [request].
  static String build(NewRecipeRequest request) {
    final BrewMethod method = request.method;
    final Map<String, Object?> data = <String, Object?>{
      'method': method.name,
      'typicalBrewTimeSeconds': method.typicalBrewTime.inSeconds,
      'taste': request.preferences.trim(),
    };

    return '$instructions\n\n${method.isImmersion ? immersionSteps : pourOverSteps}\n\nRequest (JSON):\n'
        '${jsonEncode(data)}';
  }
}
