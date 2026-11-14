import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:firebase_hybrid_ai/src/schema/structured_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies how the text of a structured response is decoded and checked, including the extra text that a model which
/// was only instructed to answer in JSON tends to add.
void main() {
  /// The schema used by these tests.
  const ResponseSchema schema = ResponseSchema.object(
    properties: <String, ResponseSchema>{'fact': ResponseSchema.string()},
  );

  /// Parses [text] with the test schema.
  StructuredGenerationResult parse(String text) {
    return StructuredResponseParser.parse(
      text: text,
      schema: schema,
      source: InferenceSource.onDevice,
      isSchemaEnforced: false,
    );
  }

  group('parse', () {
    /// Plain JSON is the expected case and must decode as is.
    test('decodes plain JSON', () {
      final StructuredGenerationResult result = parse('{"fact": "Otters hold hands."}');

      expect(result.data, <String, Object?>{'fact': 'Otters hold hands.'});
      expect(result.conformsToSchema, isTrue);
      expect(result.text, '{"fact": "Otters hold hands."}');
    });

    /// Models often wrap JSON in a Markdown code fence even when told not to.
    test('decodes JSON inside a Markdown code fence', () {
      final StructuredGenerationResult result = parse('```json\n{"fact": "Otters hold hands."}\n```');

      expect(result.data, <String, Object?>{'fact': 'Otters hold hands.'});
      expect(result.conformsToSchema, isTrue);
    });

    /// A sentence before or after the value must not stop the value from being read.
    test('decodes JSON surrounded by prose', () {
      final StructuredGenerationResult result = parse('Here you go: {"fact": "Otters hold hands."} Enjoy!');

      expect(result.data, <String, Object?>{'fact': 'Otters hold hands.'});
    });

    /// Text that holds no JSON is not a failure of the request, so it is reported as a violation with no data.
    test('reports text that is not JSON as a violation', () {
      final StructuredGenerationResult result = parse('Otters hold hands while they sleep.');

      expect(result.data, isNull);
      expect(result.conformsToSchema, isFalse);
      expect(result.violations, <String>[StructuredResponseParser.notJsonViolation]);
    });

    /// JSON that decodes but does not match the schema keeps its data, so callers can still inspect it.
    test('keeps the data of JSON that does not match the schema', () {
      final StructuredGenerationResult result = parse('{"fact": 3}');

      expect(result.data, <String, Object?>{'fact': 3});
      expect(result.conformsToSchema, isFalse);
    });

    /// The source and the enforcement flag come from the platform and must not be changed.
    test('reports the source and enforcement flag unchanged', () {
      final StructuredGenerationResult result = StructuredResponseParser.parse(
        text: '{"fact": "x"}',
        schema: schema,
        source: InferenceSource.inCloud,
        isSchemaEnforced: true,
      );

      expect(result.source, InferenceSource.inCloud);
      expect(result.isSchemaEnforced, isTrue);
    });
  });

  group('instructionsFor', () {
    /// The instructions are all an unconstrained model knows about the schema, so the schema must be in them.
    test('includes the schema as JSON', () {
      final String instructions = StructuredResponseParser.instructionsFor(schema);

      expect(instructions, contains('JSON Schema'));
      expect(instructions, contains('"fact"'));
      expect(instructions, contains('"type": "object"'));
    });
  });
}
