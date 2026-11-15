import 'package:flutter/foundation.dart';

import 'brew_phase_kind.dart';

/// One phase of a brew, such as the bloom or one of several pours.
///
/// A recipe lists its phases in the order they happen. A phase says what kind of action it is, so the same type
/// describes the phases of any brewing method. It can also carry targets that the brewing screen compares with the
/// scale: a weight to pour to, and how long the phase lasts. Both are optional, because not every phase has them. A
/// preparation step has neither.
///
/// The JSON form is below. The two target fields are left out when a phase does not have them.
///
/// ```json
/// { "id": "bloom", "kind": "bloom", "targetWeightGrams": 60.0, "durationSeconds": 45 }
/// ```
@immutable
class BrewPhase {
  /// Creates a phase of the given [kind], identified within its recipe by [id].
  ///
  /// [targetWeightGrams] and [duration], when given, must be greater than zero. The constructor can only assert the
  /// weight, because durations cannot be compared in a `const` constructor. [BrewPhase.fromJson] checks both, and
  /// checks them in release builds, where asserts do not run.
  const BrewPhase({required this.id, required this.kind, this.targetWeightGrams, this.duration})
      : assert(targetWeightGrams == null || targetWeightGrams > 0, 'targetWeightGrams must be greater than zero');

  /// Creates a phase from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or has the wrong type, the kind is unknown, or a target is
  /// present but not greater than zero.
  factory BrewPhase.fromJson(Map<String, dynamic> json) {
    try {
      final double? durationSeconds = _optionalPositive(json, 'durationSeconds');
      return BrewPhase(
        id: json['id'] as String? ?? (throw ArgumentError('Missing required field: id')),
        kind: BrewPhaseKind.fromName(json['kind'] as String? ?? (throw ArgumentError('Missing required field: kind'))),
        targetWeightGrams: _optionalPositive(json, 'targetWeightGrams'),
        duration: durationSeconds == null ? null : Duration(seconds: durationSeconds.round()),
      );
    } catch (e) {
      throw FormatException('Failed to parse BrewPhase from JSON: $e');
    }
  }

  /// An identifier for the phase that is unique within its recipe and stable, such as "pour-1". Records of a brew
  /// refer to phases by it.
  final String id;

  /// What happens during the phase.
  final BrewPhaseKind kind;

  /// The weight on the scale, in grams, at the end of the phase, or null if the phase has no weight target.
  ///
  /// This is cumulative water weight since the scale was tared in the preparation step, not the amount poured in this
  /// phase. A bloom of 60 g followed by a pour to 160 g means that second pour adds 100 g.
  final double? targetWeightGrams;

  /// How long the phase lasts, or null if it has no set length. For a bloom this is the rest after the water is added.
  final Duration? duration;

  /// Converts the phase to its JSON form, described on the class.
  ///
  /// The duration is stored as whole seconds.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        if (targetWeightGrams != null) 'targetWeightGrams': targetWeightGrams,
        if (duration != null) 'durationSeconds': duration!.inSeconds,
      };

  /// Reads the number under [key] in [json], which may be absent, and checks that it is greater than zero.
  ///
  /// Returns null if the key is absent or null. The check is repeated here because the constructor's asserts do not
  /// run in release builds.
  static double? _optionalPositive(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! num) {
      throw ArgumentError('Non-numeric field: $key');
    }
    if (value <= 0) {
      throw ArgumentError('Field $key must be greater than zero, but is $value');
    }
    return value.toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is BrewPhase &&
      other.id == id &&
      other.kind == kind &&
      other.targetWeightGrams == targetWeightGrams &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(id, kind, targetWeightGrams, duration);

  @override
  String toString() => 'BrewPhase($id, ${kind.name})';
}
