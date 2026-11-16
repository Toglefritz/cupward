import 'package:flutter/foundation.dart';

/// When one phase of a brew began.
///
/// A phase ends where the next one begins, and the last one ends with the brew, so only the start is stored. The phase
/// is identified by its `BrewPhase.id` in the recipe. [startedAt] is measured from the start of the brew.
///
/// The JSON form is below.
///
/// ```json
/// { "phaseId": "pour-1", "startedAtMilliseconds": 52300 }
/// ```
@immutable
class BrewPhaseRecord {
  /// Creates a record of the phase [phaseId] beginning [startedAt] after the brew started.
  const BrewPhaseRecord({required this.phaseId, required this.startedAt});

  /// Creates a record from its JSON form, described on the class.
  ///
  /// Throws a [FormatException] if a field is missing or has the wrong type.
  factory BrewPhaseRecord.fromJson(Map<String, dynamic> json) {
    try {
      return BrewPhaseRecord(
        phaseId: json['phaseId'] as String,
        startedAt: Duration(milliseconds: (json['startedAtMilliseconds'] as num).round()),
      );
    } catch (e) {
      throw FormatException('Failed to parse BrewPhaseRecord from JSON: $e');
    }
  }

  /// The ID of the phase in the recipe, such as "bloom".
  final String phaseId;

  /// How long after the start of the brew the phase began.
  final Duration startedAt;

  /// Converts the record to its JSON form, described on the class.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'phaseId': phaseId,
        'startedAtMilliseconds': startedAt.inMilliseconds,
      };

  @override
  bool operator ==(Object other) =>
      other is BrewPhaseRecord && other.phaseId == phaseId && other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(phaseId, startedAt);

  @override
  String toString() => 'BrewPhaseRecord($phaseId, ${startedAt.inMilliseconds} ms)';
}
