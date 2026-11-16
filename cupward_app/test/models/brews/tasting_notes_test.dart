import 'package:cupward/models/brews/taste_attribute.dart';
import 'package:cupward/models/brews/tasting_notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the tasting notes' JSON form and how ratings are added and removed.
void main() {
  group('TastingNotes', () {
    /// Brew feedback reads the notes as JSON, so they must survive conversion and back unchanged.
    test('converts to JSON and back', () {
      // Arrange
      final TastingNotes notes = TastingNotes(
        ratings: const <TasteAttribute, int>{TasteAttribute.bitterness: 4, TasteAttribute.intensity: 2},
        goal: 'Less bitter.',
      );

      // Act
      final TastingNotes copy = TastingNotes.fromJson(notes.toJson());

      // Assert
      expect(copy, notes);
    });

    /// Unrated attributes must be absent, so a missing answer is never read as a middle rating.
    test('leaves unrated attributes out of the JSON, and states the scale', () {
      // Arrange
      final TastingNotes notes = TastingNotes(
        ratings: const <TasteAttribute, int>{TasteAttribute.overall: 5, TasteAttribute.acidity: 3},
        goal: '  Brighter.  ',
      );

      // Act
      final Map<String, dynamic> json = notes.toJson();

      // Assert
      expect(json['ratingScale'], <String, int>{'min': 1, 'max': 5});
      expect((json['ratings'] as Map<String, int>).keys, <String>['acidity', 'overall']);
      expect(json['goal'], 'Brighter.');
    });

    /// Stored or received data with a rating out of range must fail clearly.
    test('rejects a rating out of range', () {
      expect(
        () => TastingNotes.fromJson(const <String, dynamic>{
          'ratings': <String, dynamic>{'body': 9},
        }),
        throwsFormatException,
      );
      expect(
        () => TastingNotes.fromJson(const <String, dynamic>{
          'ratings': <String, dynamic>{'flavor': 3},
        }),
        throwsFormatException,
      );
    });

    /// The form sets and clears ratings one at a time.
    test('adds and removes a rating', () {
      // Act
      final TastingNotes rated = TastingNotes().withRating(TasteAttribute.body, 2);
      final TastingNotes cleared = rated.withRating(TasteAttribute.body, null);

      // Assert
      expect(rated.ratings, <TasteAttribute, int>{TasteAttribute.body: 2});
      expect(cleared.ratings, isEmpty);
    });

    /// An untouched form must be recognizable, so the app can tell the user there is nothing to send.
    test('reports when nothing has been filled in', () {
      expect(TastingNotes().isEmpty, isTrue);
      expect(TastingNotes(goal: '   ').isEmpty, isTrue);
      expect(TastingNotes(goal: 'Sweeter').isEmpty, isFalse);
      expect(TastingNotes().withRating(TasteAttribute.overall, 3).isEmpty, isFalse);
    });
  });
}
