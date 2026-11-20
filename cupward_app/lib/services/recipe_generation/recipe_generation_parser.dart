import 'dart:math';

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
/// * The name must have at least one letter or digit, so that it gives a recipe ID of its own.
/// * The steps must follow the method's pattern. A pour-over brew is an optional bloom followed by one or more pours.
///   An immersion brew is one or more pours followed by one steep. Bloom and pour steps need a target weight, and a
///   steep needs a duration.
/// * Each target weight must be at least [minTargetIncrementGrams] more than the one before, so the brewing screen can
///   tell from the scale that the step's water was poured. The last must be close to the total water, and is then set
///   to the total exactly, so the brew ends on the recipe's water.
///
/// Some details are corrected instead of rejected: the preparation and completion steps are put first and last, a
/// steep's target weight and a pour's duration are dropped, since the brewing screen does not use them, a brew time
/// shorter than the timed steps is raised to their total, a yield that is missing or outside half to all of the water
/// is worked out from the water and coffee, and long names are shortened. Step IDs are assigned here, such as
/// `pour-2`, and the recipe ID comes from the name, as `RecipeIds` describes.
abstract final class RecipeGenerationParser {
  /// The longest a recipe name or profile can be, in Unicode code points.
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

  /// The least water, in grams, that each bloom or pour must add to the previous target.
  ///
  /// The brewing screen ends a step only after the scale has risen by `PhaseAdvanceTracker.minimumRise` (5 g) and is
  /// within `PhaseAdvanceTracker.tolerance` (2 g) of the target, so a smaller step could not be finished by pouring.
  static const double minTargetIncrementGrams = 7;

  /// The least yield, as a fraction of the water. Less than this means the model got the yield wrong.
  static const double minYieldFraction = 0.5;

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
    if (!RecipeIds.hasLettersOrDigits(name)) {
      throw FormatException('The name "$name" has no letters or digits.');
    }
    final String profile = _text(data, 'profile');
    final double coffee = _roundTenth(_number(data, 'coffeeGrams', min: minCoffeeGrams, max: maxCoffeeGrams));
    final double water = _roundTenth(_number(data, 'waterGrams', min: minWaterGrams, max: maxWaterGrams));
    final double ratio = water / coffee;
    if (ratio < minRatio || ratio > maxRatio) {
      throw FormatException('The ratio 1:${ratio.toStringAsFixed(1)} is out of range.');
    }
    final int reportedBrewTime =
        _number(data, 'brewTimeSeconds', min: minBrewTimeSeconds.toDouble(), max: maxBrewTimeSeconds.toDouble())
            .round();
    final List<BrewPhase> phases = _phases(data['phases'], method: method, waterGrams: water);
    final int timedSeconds = phases.fold<int>(
      0,
      (int total, BrewPhase phase) => total + (phase.duration?.inSeconds ?? 0),
    );
    if (timedSeconds > maxBrewTimeSeconds) {
      throw FormatException('The timed steps last $timedSeconds seconds, longer than the longest brew.');
    }
    return BrewRecipe(
      id: RecipeIds.fromName(name),
      name: name,
      method: method,
      profile: profile,
      coffeeGrams: coffee,
      waterGrams: water,
      brewTime: Duration(seconds: max(reportedBrewTime, timedSeconds)),
      yieldMilliliters: _yield(data['yieldMilliliters'], coffeeGrams: coffee, waterGrams: water),
      phases: phases,
    );
  }

  /// Returns the reported yield [value] if it is from [minYieldFraction] of the water to all of it, or else an estimate
  /// of the water less twice the coffee, which the grounds hold.
  static double _yield(Object? value, {required double coffeeGrams, required double waterGrams}) {
    final double least = waterGrams * minYieldFraction;
    if (value is num && value >= least && value <= waterGrams) {
      return _roundTenth(value.toDouble());
    }
    return _roundTenth((waterGrams - 2 * coffeeGrams).clamp(least, waterGrams));
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
      final double? target = _optionalPositive(item['targetWeightGrams']);
      final int? seconds = _seconds(item);
      middle.add(
        (
          kind: kind,
          target: kind == BrewPhaseKind.steep ? null : target,
          seconds: kind == BrewPhaseKind.pour ? null : seconds,
        ),
      );
    }
    if (middle.isEmpty || middle.length > maxMiddlePhases) {
      throw FormatException('A recipe needs between 1 and $maxMiddlePhases brewing steps, not ${middle.length}.');
    }
    _checkOrder(middle.map((({BrewPhaseKind kind, double? target, int? seconds}) step) => step.kind).toList(), method);
    final List<double> targets = <double>[];
    for (final ({BrewPhaseKind kind, double? target, int? seconds}) step in middle) {
      final double? target = step.target;
      if (step.kind != BrewPhaseKind.steep && target == null) {
        throw FormatException('Each ${step.kind.name} needs a target weight.');
      }
      if (step.kind == BrewPhaseKind.steep && step.seconds == null) {
        throw const FormatException('A steep needs a duration.');
      }
      if (target != null) {
        targets.add(_roundTenth(target));
      }
    }
    if ((targets.last - waterGrams).abs() > waterGrams * lastTargetTolerance) {
      throw const FormatException('The last target weight must be close to the total water.');
    }
    targets.last = waterGrams;
    double previous = 0;
    for (final double target in targets) {
      if (target - previous < minTargetIncrementGrams) {
        throw FormatException('Each step must add at least $minTargetIncrementGrams g, but one adds '
            '${(target - previous).toStringAsFixed(1)} g.');
      }
      previous = target;
    }
    final Map<BrewPhaseKind, int> counts = <BrewPhaseKind, int>{};
    String idFor(BrewPhaseKind kind) {
      final int count = counts[kind] = (counts[kind] ?? 0) + 1;
      // Pours are always numbered, as the brewing screen names them. Other steps are numbered only if repeated.
      return kind == BrewPhaseKind.pour || count > 1 ? '${kind.name}-$count' : kind.name;
    }

    int targetIndex = 0;
    return <BrewPhase>[
      const BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare),
      for (final ({BrewPhaseKind kind, double? target, int? seconds}) step in middle)
        BrewPhase(
          id: idFor(step.kind),
          kind: step.kind,
          targetWeightGrams: step.target == null ? null : targets[targetIndex++],
          duration: step.seconds == null ? null : Duration(seconds: step.seconds!),
        ),
      const BrewPhase(id: 'complete', kind: BrewPhaseKind.complete),
    ];
  }

  /// Throws a [FormatException] unless the step [kinds], between preparation and completion, follow the pattern for
  /// [method]: an optional bloom and then pours for pour-over methods, or pours and then one steep for immersion.
  static void _checkOrder(List<BrewPhaseKind> kinds, BrewMethod method) {
    final List<BrewPhaseKind> pours = method.isImmersion
        ? kinds.sublist(0, kinds.length - 1)
        : kinds.first == BrewPhaseKind.bloom
            ? kinds.sublist(1)
            : kinds;
    final bool endsRight = !method.isImmersion || kinds.last == BrewPhaseKind.steep;
    if (!endsRight || pours.isEmpty || pours.any((BrewPhaseKind kind) => kind != BrewPhaseKind.pour)) {
      final String received = kinds.map((BrewPhaseKind kind) => kind.name).join(', ');
      throw FormatException(
        method.isImmersion
            ? 'An immersion recipe for ${method.name} must be one or more pours and then a steep, but the steps '
                'between preparation and completion were: $received.'
            : 'A pour-over recipe for ${method.name} must be an optional bloom and then one or more pours, but the '
                'steps between preparation and completion were: $received.',
      );
    }
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

  /// Returns the trimmed text under [key], shortened to [maxTextLength] code points, or throws if it is missing or blank.
  static String _text(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing text for $key.');
    }
    final String trimmed = value.trim();
    if (trimmed.runes.length <= maxTextLength) {
      return trimmed;
    }
    // Shortened by code points rather than UTF-16 units, so that a character outside the Basic Multilingual Plane,
    // such as an emoji, is never split in half.
    return String.fromCharCodes(trimmed.runes.take(maxTextLength)).trimRight();
  }

  /// Rounds [value] to the nearest tenth, the scale's precision.
  static double _roundTenth(double value) => (value * 10).roundToDouble() / 10;
}
