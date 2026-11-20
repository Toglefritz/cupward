import 'dart:convert';

import '../../models/recipes/brew_method.dart';
import '../../models/recipes/new_recipe_request.dart';

/// Builds the prompt that asks the AI model to create a recipe for a brewing method and the user's taste.
///
/// The prompt has three parts: how to design the recipe, the step pattern for the method, and the request as compact
/// JSON. The step patterns match what the brewing screen can guide: pour-over brews are prepare, bloom, a few pours,
/// and complete, and immersion brews are prepare, one pour of all the water, steep, and complete. Weights are
/// cumulative from a tared scale, as the brewing screen expects.
///
/// Each step pattern lists the required steps, names the steps that must not be used, and ends with an example, since
/// small on-device models follow an example more reliably than a description. When a previous answer was rejected,
/// the reason is added, so that a repeated request does not make the same mistake.
abstract final class RecipeGenerationPrompt {
  /// The design instructions that come first.
  static const String instructions = '''
You are a coffee brewing coach. Design one starting recipe for a home brewer, for the method and taste below.
Rules:
- Base the ratio on the taste: about 1:15 to 1:17 for pour-over and 1:12 to 1:16 for immersion. A stronger cup uses less water per gram of coffee.
- If a cup size is given, choose the water to match it. Otherwise make one cup of about 300 ml.
- Target weights are the total water on the scale after each step, counted from zero, so they only go up and the last one equals the total water.
- Only bloom and pour steps have a target weight, and each adds at least 10 g of water.
- The brew time covers the whole brew, including every step's durationSeconds.
- The yield is the water less what the grounds hold, about twice the coffee weight.
- The name is short and distinctive. The profile describes the cup in two to four words.''';

  /// The step pattern for pour-over methods.
  static const String pourOverSteps = '''
Steps for this method, in this order and no others:
1. One prepare step.
2. One bloom step with about two to three times the coffee weight in water and a durationSeconds of 30 to 45.
3. Two to four pour steps, each with a targetWeightGrams. Pours have no durationSeconds.
4. One complete step.
Never use a steep step for this method. Never use more than one bloom. Always include the bloom and at least two pours.
Example steps for 20 g of coffee and 320 g of water:
[{"kind":"prepare"},{"kind":"bloom","targetWeightGrams":50,"durationSeconds":40},{"kind":"pour","targetWeightGrams":150},{"kind":"pour","targetWeightGrams":240},{"kind":"pour","targetWeightGrams":320},{"kind":"complete"}]''';

  /// The step pattern for immersion methods.
  static const String immersionSteps = '''
Steps for this method, in this order and no others:
1. One prepare step.
2. One pour step with a targetWeightGrams equal to the total water.
3. One steep step with a durationSeconds for the steeping time.
4. One complete step.
Never use a bloom step for this method. Always include the pour and the steep.
Example steps for 30 g of coffee and 450 g of water:
[{"kind":"prepare"},{"kind":"pour","targetWeightGrams":450},{"kind":"steep","durationSeconds":240},{"kind":"complete"}]''';

  /// Returns the prompt for [request].
  ///
  /// If [rejection] is given, it is the reason the previous answer could not be used, and the prompt tells the model to
  /// avoid that mistake.
  static String build(NewRecipeRequest request, {String? rejection}) {
    final BrewMethod method = request.method;
    final Map<String, Object?> data = <String, Object?>{
      'method': method.name,
      'typicalBrewTimeSeconds': method.typicalBrewTime.inSeconds,
      'taste': request.preferences.trim(),
    };
    final String correction = rejection == null
        ? ''
        : '\n\nYour previous answer was rejected: $rejection\nFix this and follow the steps for this method exactly.';
    return '$instructions\n\n${method.isImmersion ? immersionSteps : pourOverSteps}$correction\n\nRequest (JSON):\n'
        '${jsonEncode(data)}';
  }
}
