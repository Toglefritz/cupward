import 'package:flutter/foundation.dart';

import 'brew_phase_kind.dart';

/// One phase of a brew, such as the bloom or one of several pours.
///
/// A recipe lists its phases in the order they happen. A phase only says what kind of action it is, so the same type
/// describes the phases of any brewing method.
///
/// The JSON form is:
///
/// ```json
/// { "id": "pour-1", "kind": "pour" }
/// ```
@immutable
class BrewPhase {
  /// Creates a phase of the given [kind], identified within its recipe by [id].
  const BrewPhase({required this.id, required this.kind});

  /// Creates a phase from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or the kind is unknown.
  factory BrewPhase.fromJson(Map<String, dynamic> json) {
    try {
      return BrewPhase(
        id: json['id'] as String? ?? (throw ArgumentError('Missing required field: id')),
        kind: BrewPhaseKind.fromName(json['kind'] as String? ?? (throw ArgumentError('Missing required field: kind'))),
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

  /// Converts the phase to its JSON form, described on the class.
  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'kind': kind.name};

  @override
  bool operator ==(Object other) => other is BrewPhase && other.id == id && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, kind);

  @override
  String toString() => 'BrewPhase($id, ${kind.name})';
}
