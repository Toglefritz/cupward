import 'package:flutter/foundation.dart';

import 'brew_phase.dart';

/// A brewing recipe: what to brew and the targets that a brew follows.
///
/// A recipe describes a brew by its quantities and timing, not by one brewing method, so the same type serves any
/// method the app supports. The name says which method it is, for example "V60 Pour Over".
///
/// All quantities are targets. The brewing screens compare live scale readings against them. The [phases] list the
/// steps of the brew in order, such as prepare, bloom, three pours, and complete for a pour over.
///
/// The JSON form, used for storage, is:
///
/// ```json
/// {
///   "id": "v60-pour-over",
///   "name": "V60 Pour Over",
///   "profile": "Balanced & Clean",
///   "coffeeGrams": 20.0,
///   "waterGrams": 320.0,
///   "brewTimeSeconds": 180,
///   "yieldMilliliters": 320.0,
///   "phases": [
///     { "id": "prepare", "kind": "prepare" },
///     { "id": "bloom", "kind": "bloom" },
///     { "id": "pour-1", "kind": "pour" },
///     { "id": "complete", "kind": "complete" }
///   ]
/// }
/// ```
@immutable
class BrewRecipe {
  /// Creates a recipe. Every quantity must be greater than zero, and [phases] must not be empty. The phases cannot be
  /// checked here, because the constructor is `const`, so [BrewRecipe.fromJson] checks them for stored recipes.
  const BrewRecipe({
    required this.id,
    required this.name,
    required this.profile,
    required this.coffeeGrams,
    required this.waterGrams,
    required this.brewTime,
    required this.yieldMilliliters,
    required this.phases,
  })  : assert(coffeeGrams > 0, 'coffeeGrams must be greater than zero'),
        assert(waterGrams > 0, 'waterGrams must be greater than zero'),
        assert(yieldMilliliters > 0, 'yieldMilliliters must be greater than zero');

  /// Creates a recipe from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or has the wrong type, if a quantity is not greater than zero,
  /// or if there are no phases.
  factory BrewRecipe.fromJson(Map<String, dynamic> json) {
    try {
      return BrewRecipe(
        id: json['id'] as String? ?? (throw ArgumentError('Missing required field: id')),
        name: json['name'] as String? ?? (throw ArgumentError('Missing required field: name')),
        profile: json['profile'] as String? ?? (throw ArgumentError('Missing required field: profile')),
        coffeeGrams: _positive(json, 'coffeeGrams'),
        waterGrams: _positive(json, 'waterGrams'),
        brewTime: Duration(seconds: (json['brewTimeSeconds'] as num).toInt()),
        yieldMilliliters: _positive(json, 'yieldMilliliters'),
        phases: _phases(json),
      );
    } catch (e) {
      throw FormatException('Failed to parse BrewRecipe from JSON: $e');
    }
  }

  /// A stable identifier for the recipe, used to store and look it up. It never changes, even if the name does.
  final String id;

  /// The recipe's display name, which usually names the brewing method, such as "V60 Pour Over".
  final String name;

  /// A short description of the cup the recipe aims for, such as "Balanced & Clean".
  final String profile;

  /// The dose of ground coffee, in grams.
  final double coffeeGrams;

  /// The total water poured over the brew, in grams.
  final double waterGrams;

  /// The target total brew time, from the first pour to the end of the drawdown.
  final Duration brewTime;

  /// The approximate volume of coffee the brew produces, in milliliters.
  ///
  /// This is an estimate, because the grounds keep some of the water and the amount varies with the coffee and the
  /// grind. It is stored with the recipe instead of being derived from the water weight for that reason.
  final double yieldMilliliters;

  /// The phases of the brew, in the order they happen. There is always at least one.
  final List<BrewPhase> phases;

  /// Converts the recipe to its JSON form, described on the class.
  ///
  /// The brew time is stored as whole seconds.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'profile': profile,
        'coffeeGrams': coffeeGrams,
        'waterGrams': waterGrams,
        'brewTimeSeconds': brewTime.inSeconds,
        'yieldMilliliters': yieldMilliliters,
        'phases': phases.map((BrewPhase phase) => phase.toJson()).toList(),
      };

  /// Reads the list of phases from [json], and checks that it is not empty.
  ///
  /// The check is repeated here because the constructor's asserts do not run in release builds.
  static List<BrewPhase> _phases(Map<String, dynamic> json) {
    final Object? value = json['phases'];

    if (value is! List<dynamic>) {
      throw ArgumentError('Missing or non-list field: phases');
    }

    if (value.isEmpty) {
      throw ArgumentError('Field phases must not be empty');
    }

    return value.map((dynamic phase) => BrewPhase.fromJson(phase as Map<String, dynamic>)).toList();
  }

  /// Reads the number under [key] in [json] as a double, and checks that it is greater than zero.
  ///
  /// The check is repeated here because the constructor's asserts do not run in release builds.
  static double _positive(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is! num) {
      throw ArgumentError('Missing or non-numeric field: $key');
    }

    if (value <= 0) {
      throw ArgumentError('Field $key must be greater than zero, but is $value');
    }

    return value.toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is BrewRecipe &&
      other.id == id &&
      other.name == name &&
      other.profile == profile &&
      other.coffeeGrams == coffeeGrams &&
      other.waterGrams == waterGrams &&
      other.brewTime == brewTime &&
      other.yieldMilliliters == yieldMilliliters &&
      listEquals(other.phases, phases);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        profile,
        coffeeGrams,
        waterGrams,
        brewTime,
        yieldMilliliters,
        Object.hashAll(phases),
      );

  @override
  String toString() => 'BrewRecipe($id, $name)';
}
