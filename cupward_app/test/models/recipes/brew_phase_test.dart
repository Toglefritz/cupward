import 'package:cupward/models/recipes/brew_phase.dart';
import 'package:cupward/models/recipes/brew_phase_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the JSON form of [BrewPhase], in particular its optional weight and duration targets. No dependencies are
/// mocked.
void main() {
  group('BrewPhase JSON', () {
    /// A phase with targets must come back unchanged after being stored.
    test('round-trips a phase with targets', () {
      // Arrange
      const BrewPhase phase = BrewPhase(
        id: 'bloom',
        kind: BrewPhaseKind.bloom,
        targetWeightGrams: 60,
        duration: Duration(seconds: 45),
      );

      // Act
      final BrewPhase decoded = BrewPhase.fromJson(phase.toJson());

      // Assert
      expect(decoded, phase);
      expect(phase.toJson(), <String, dynamic>{
        'id': 'bloom',
        'kind': 'bloom',
        'targetWeightGrams': 60.0,
        'durationSeconds': 45,
      });
    });

    /// Phases without targets keep the original two-field form, so recipes stored before targets existed still load.
    test('leaves out targets that are not set and reads phases that lack them', () {
      // Arrange
      const BrewPhase phase = BrewPhase(id: 'prepare', kind: BrewPhaseKind.prepare);

      // Act
      final BrewPhase decoded = BrewPhase.fromJson(const <String, dynamic>{'id': 'prepare', 'kind': 'prepare'});

      // Assert
      expect(phase.toJson(), <String, dynamic>{'id': 'prepare', 'kind': 'prepare'});
      expect(decoded.targetWeightGrams, isNull);
      expect(decoded.duration, isNull);
      expect(decoded, phase);
    });

    /// A zero or negative target can never be reached, so stored data with one is rejected.
    test('throws a FormatException for a target that is not greater than zero', () {
      expect(
        () => BrewPhase.fromJson(const <String, dynamic>{'id': 'a', 'kind': 'pour', 'targetWeightGrams': 0}),
        throwsFormatException,
      );
      expect(
        () => BrewPhase.fromJson(const <String, dynamic>{'id': 'a', 'kind': 'bloom', 'durationSeconds': -5}),
        throwsFormatException,
      );
    });

    /// A target of the wrong type is a data error and must not be guessed at.
    test('throws a FormatException for a non-numeric target', () {
      expect(
        () => BrewPhase.fromJson(const <String, dynamic>{'id': 'a', 'kind': 'pour', 'targetWeightGrams': '160'}),
        throwsFormatException,
      );
    });

    /// Two phases that differ only in a target are different phases.
    test('compares targets in equality', () {
      const BrewPhase a = BrewPhase(id: 'p', kind: BrewPhaseKind.pour, targetWeightGrams: 160);
      const BrewPhase b = BrewPhase(id: 'p', kind: BrewPhaseKind.pour, targetWeightGrams: 240);

      expect(a == b, isFalse);
    });
  });
}
