import '../../models/recipes/brew_method.dart';
import '../../models/recipes/brew_phase.dart';
import '../../models/recipes/brew_phase_kind.dart';
import '../../models/recipes/brew_recipe.dart';
import '../../models/recipes/recipe_ids.dart';

/// Turns the AI model's answer, decoded from JSON in the shape of `RecipeGenerationSchema`, into a [BrewRecipe].
///
/// The schema fixes the answer's shape, but not whether it makes a brewable recipe, so the parser checks that too and
/// rejects anything that does not, rather than guessing:
///
/// * The coffee, water, ratio, and brew time must be in ranges that a home brewer would use.
/// * The steps must fit the method: an immersion brew needs a steep, and a pour-over brew needs at least one pour and
///   no steep. Bloom and pour steps need a target weight, and a steep needs a duration.
/// * Target weights must rise from step to step, and the last must be close to the total water. It is then set to the
///   total exactly, so the brew ends on the recipe's water.
///
/// Some details are corrected instead of rejected: the preparation and completion steps are put first and last, a
/// yield that is missing or more than the water is worked out from the water and coffee, and long names are shortened.
/// Step IDs are assigned here, such as `pour-2`, and the recipe ID comes from the name, as `RecipeIds` describes.
abstract final class RecipeGenerationParser {
  /// The longest a recipe name or profile can be.
  static const int maxTextLength = 40;

  /// The coffee dose range, in grams.
  static const double minCoffeeGrams = 5;

  /// The coffee dose range, in grams.
  static const double maxCoffeeGrams = 60;

  /// The total water range, in grams.
  static const double minWaterGrams = 60;

  /// The total water range, in grams.
  static const double maxWaterGrams = 1000;

  /// The water-to-coffee ratio range.
  static const double minRatio = 8;

  /// The water-to-coffee ratio range.
  static const double maxRatio = 20;

  /// The brew time range, in seconds.
  static const int minBrewTimeSeconds = 30;

  /// The brew time range, in seconds.
  static const int maxBrewTimeSeconds = 900;

  /// How far the last target weight may be from the total water, as a fraction of the water, before it is rejected.
  static const double lastTargetTolerance = 0.15;

  /// The most steps a recipe can have between preparation and completion.
  static const int maxMiddlePhases = 20;

  /// Returns the recipe in [data], for a brew with [method].
  ///
  /// Throws a [FormatException] if the answer does not make a brewable recipe.
  static BrewRecipe parse(Object? data, {required BrewMethod method}) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('The recipe must be a JSON object.');
    }

    final String name = _text(data, 'name');
    final String profile = _text(data, 'profile');
    final double coffee = _number(data, 'coffeeGrams', min: minCoffeeGrams, max: maxCoffeeGrams);
    final double water = _number(data, 'waterGrams', min: minWaterGrams, max: maxWaterGrams);
    final double ratio = water / coffee;
    if (ratio < minRatio || ratio > maxRatio) {
      throw FormatException('The ratio 1:${ratio.toStringAsFixed(1)} is out of range.');
    }
    final int brewTime =
        _number(data, 'brewTimeSeconds', min: minBrewTimeSeconds.toDouble(), max: maxBrewTimeSeconds.toDouble())
            .round();

    final Object? reportedYield = data['yieldMilliliters'];
    final double yieldMilliliters = reportedYield is num && reportedYield > 0 && reportedYield <= water
        ? _roundTenth(reportedYield.toDouble())
        : _roundTenth((water - 2 * coffee).clamp(water * 0.5, water));

    return BrewRecipe(
      id: RecipeIds.fromName(name),
      name: name,
      profile: profile,
      coffeeGrams: _roundTenth(coffee),
      waterGrams: _roundTenth(water),
      brewTime: Duration(seconds: brewTime),
      yieldMilliliters: yieldMilliliters,
      phases: _phases(data['phases'], method: method, waterGrams: _roundTenth(water)),
    );
  }

  /// Reads and checks the steps, and returns them with preparation first, completion last, and IDs assigned.
  static List<BrewPhase> _phases(Object? value, {required BrewMethod method, required double waterGrams}) {
    if (value is! List<dynamic>) {
      throw const FormatException('The steps must be a list.');
    }

    final List<({BrewPhaseKind kind, double? target, int? seconds})> middle =
        <({BrewPhaseKind kind, double? target, int? seconds})>[];
    for (final Object? item in value) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Each step must be an object.');
      }
      final BrewPhaseKind kind = _kind(item['kind']);
      if (kind == BrewPhaseKind.prepare || kind == BrewPhaseKind.complete) {
        continue;
      }
      middle.add((kind: kind, target: _optionalPositive(item['targetWeightGrams']), seconds: _seconds(item)));
    }

    if (middle.isEmpty || middle.length > maxMiddlePhases) {
      throw FormatException('A recipe needs between 1 and $maxMiddlePhases brewing steps, not ${middle.length}.');
    }
    final bool hasSteep =
        middle.any((({BrewPhaseKind kind, double? target, int? seconds}) step) => step.kind == BrewPhaseKind.steep);
    final bool hasPour =
        middle.any((({BrewPhaseKind kind, double? target, int? seconds}) step) => step.kind == BrewPhaseKind.pour);
    if (method.isImmersion && !hasSteep) {
      throw FormatException('An immersion recipe for ${method.name} needs a steep.');
    }
    if (!method.isImmersion && (hasSteep || !hasPour)) {
      throw FormatException('A pour-over recipe for ${method.name} needs pours and no steep.');
    }

    double previousTarget = 0;
    int lastTargetIndex = -1;
    for (int index = 0; index < middle.length; index++) {
      final ({BrewPhaseKind kind, double? target, int? seconds}) step = middle[index];
      final bool needsTarget = step.kind == BrewPhaseKind.bloom || step.kind == BrewPhaseKind.pour;
      if (needsTarget && step.target == null) {
        throw FormatException('Each ${step.kind.name} needs a target weight.');
      }
      if (step.kind == BrewPhaseKind.steep && step.seconds == null) {
        throw const FormatException('A steep needs a duration.');
      }
      final double? target = step.target;
      if (target != null) {
        if (target <= previousTarget) {
          throw const FormatException('Target weights must rise from step to step.');
        }
        previousTarget = target;
        lastTargetIndex = index;
      }
    }
    if (lastTargetIndex < 0 || (previousTarget - waterGrams).abs() > waterGrams * lastTargetTolerance) {
      throw const FormatException('The last target weight must be close to the total water.');
    }

    final Map<BrewPhaseKind, int> counts = <BrewPhaseKind, int>{};
    String idFor(BrewPhaseKind kind) {
      final int count = counts[kind] = (counts[kind] ?? 0) + 1;
      // Pours are always numbered, as the brewing screen names them. Other steps are numbered only if repeated.
      return kind == BrewPhaseKind.pour || count > 1 ? '${kind.name}-$count' : kind.name;
    }

    return <BrewPhase>[
      const BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
      for (int index = 0; index < middle.length; index++)
        BrewPhase(
          id: idFor(middle[index].kind),
          kind: middle[index].kind,
          targetWeightGrams: index == lastTargetIndex
              ? waterGrams
              : middle[index].target == null
                  ? null
                  : _roundTenth(middle[index].target!),
          duration: middle[index].seconds == null ? null : Duration(seconds: middle[index].seconds!),
        ),
      const BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
    ];
  }

  /// Returns the step kind named [value], or throws a [FormatException].
  static BrewPhaseKind _kind(Object? value) {
    if (value is String) {
      for (final BrewPhaseKind kind in BrewPhaseKind.values) {
        if (kind.name == value) {
          return kind;
        }
      }
    }
    throw FormatException('Unknown step kind: $value');
  }

  /// Returns the step's duration in whole seconds, or null if it has none. Throws for a duration that is out of range.
  static int? _seconds(Map<String, dynamic> step) {
    final double? seconds = _optionalPositive(step['durationSeconds']);
    if (seconds == null) {
      return null;
    }
    if (seconds > maxBrewTimeSeconds) {
      throw const FormatException('A step cannot last longer than the longest brew.');
    }
    return seconds.round();
  }

  /// Returns [value] as a number if it is one greater than zero, or null if it is absent. Throws for anything else.
  static double? _optionalPositive(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! num || value <= 0) {
      throw FormatException('Expected a number greater than zero, not $value.');
    }
    return value.toDouble();
  }

  /// Returns the number under [key], which must be from [min] to [max].
  static double _number(Map<String, dynamic> map, String key, {required double min, required double max}) {
    final Object? value = map[key];
    if (value is! num || value < min || value > max) {
      throw FormatException('$key must be a number from $min to $max, not $value.');
    }
    return value.toDouble();
  }

  /// Returns the trimmed text under [key], shortened to [maxTextLength], or throws if it is missing or blank.
  static String _text(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing text for $key.');
    }
    final String trimmed = value.trim();
    return trimmed.length <= maxTextLength ? trimmed : trimmed.substring(0, maxTextLength).trimRight();
  }

  /// Rounds [value] to the nearest tenth, the scale's precision.
  static double _roundTenth(double value) => (value * 10).roundToDouble() / 10;
}
