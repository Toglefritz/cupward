import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that schemas convert to the JSON Schema form the SDKs accept, and that validation reports each problem
/// with its location. No platform code is involved.
void main() {
  /// An object schema that uses every type.
  const ResponseSchema recipe = ResponseSchema.object(
    description: 'A recipe idea',
    properties: <String, ResponseSchema>{
      'name': ResponseSchema.string(description: 'The dish'),
      'servings': ResponseSchema.integer(),
      'rating': ResponseSchema.number(),
      'vegetarian': ResponseSchema.boolean(),
      'course': ResponseSchema.enumeration(<String>['starter', 'main', 'dessert']),
      'ingredients': ResponseSchema.array(items: ResponseSchema.string()),
      'notes': ResponseSchema.string(),
    },
    optionalProperties: <String>['notes'],
  );

  group('toJson', () {
    /// The SDKs read these keywords, so their names and structure are part of the contract with them.
    test('produces a JSON Schema object with types, descriptions, and required properties', () {
      final Map<String, Object?> json = recipe.toJson();

      expect(json['type'], 'object');
      expect(json['description'], 'A recipe idea');
      expect(json['required'], <String>['name', 'servings', 'rating', 'vegetarian', 'course', 'ingredients']);

      final Map<String, Object?> properties = json['properties']! as Map<String, Object?>;
      expect(properties['name'], <String, Object?>{'type': 'string', 'description': 'The dish'});
      expect(properties['servings'], <String, Object?>{'type': 'integer'});
      expect(properties['rating'], <String, Object?>{'type': 'number'});
      expect(properties['vegetarian'], <String, Object?>{'type': 'boolean'});
      expect(properties['course'], <String, Object?>{
        'type': 'string',
        'enum': <String>['starter', 'main', 'dessert'],
      });
      expect(properties['ingredients'], <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      });
    });
  });

  group('validate', () {
    /// A value that matches every rule must produce no violations, including a whole number written as a decimal.
    test('accepts a conforming value', () {
      final List<String> violations = recipe.validate(<String, Object?>{
        'name': 'Soup',
        'servings': 4.0,
        'rating': 4.5,
        'vegetarian': true,
        'course': 'starter',
        'ingredients': <Object?>['leek', 'potato'],
      });

      expect(violations, isEmpty);
    });

    /// Each problem must be reported separately with its path, so a caller can see everything that is wrong at once.
    test('reports each problem with its path', () {
      final List<String> violations = recipe.validate(<String, Object?>{
        'name': 12,
        'servings': 2.5,
        'vegetarian': 'yes',
        'course': 'snack',
        'ingredients': <Object?>['leek', 3],
      });

      expect(violations, hasLength(6));
      expect(violations, contains(r'$.name must be a string, but is a number.'));
      expect(violations, contains(r'$.servings must be a whole number, but is a number.'));
      expect(violations, contains(r'$.rating is required, but is missing.'));
      expect(violations, contains(r'$.vegetarian must be a boolean, but is a string.'));
      expect(violations, contains(r'$.course must be one of starter, main, dessert, but is "snack".'));
      expect(violations, contains(r'$.ingredients[1] must be a string, but is a number.'));
    });

    /// An optional property can be left out or set to null, and a required one cannot be null.
    test('treats optional properties as absent or null, and required ones as present', () {
      const ResponseSchema schema = ResponseSchema.object(
        properties: <String, ResponseSchema>{'a': ResponseSchema.string(), 'b': ResponseSchema.string()},
        optionalProperties: <String>['b'],
      );

      expect(schema.validate(<String, Object?>{'a': 'x', 'b': null}), isEmpty);
      expect(schema.validate(<String, Object?>{'a': null}), <String>[r'$.a is required, but is missing.']);
    });

    /// A value of the wrong shape at the root must be reported without inspecting its properties.
    test('reports a root value of the wrong type', () {
      expect(recipe.validate(<Object?>[]), <String>[r'$ must be an object, but is an array.']);
    });
  });
}
