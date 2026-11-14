import 'dart:convert';

import '../messages.g.dart';
import 'response_schema.dart';
import 'structured_generation_result.dart';

/// Turns the text of a structured response into a [StructuredGenerationResult] by decoding and validating it.
///
/// Every platform hands its raw text here, so the result is built and checked the same way everywhere.
abstract final class StructuredResponseParser {
  /// The message used when no JSON value can be read from the text.
  static const String notJsonViolation = r'$ must be JSON, but the response could not be decoded.';

  /// Decodes [text], validates it against [schema], and returns the result.
  ///
  /// The text is decoded as is first. If that fails, which happens when a model that was only instructed to answer
  /// in JSON wraps the value in a Markdown code fence or adds a sentence, the outermost object or array in the text
  /// is decoded instead. [source] and [isSchemaEnforced] are reported unchanged.
  static StructuredGenerationResult parse({
    required String text,
    required ResponseSchema schema,
    required InferenceSource source,
    required bool isSchemaEnforced,
  }) {
    final (bool isDecoded, Object? data) = decode(text);

    return StructuredGenerationResult(
      text: text,
      data: isDecoded ? data : null,
      source: source,
      isSchemaEnforced: isSchemaEnforced,
      violations: isDecoded ? schema.validate(data) : const <String>[notJsonViolation],
    );
  }

  /// Reads a JSON value from [text], and returns whether that worked together with the value.
  ///
  /// A separate flag is needed because `null` is a valid JSON value.
  static (bool, Object?) decode(String text) {
    final String trimmed = text.trim();

    try {
      return (true, jsonDecode(trimmed));
    } on FormatException {
      // Fall through to look for a JSON value inside the text.
    }

    final int start = _firstIndexOfAny(trimmed, const <String>['{', '[']);
    final int end = _lastIndexOfAny(trimmed, const <String>['}', ']']);

    if (start < 0 || end <= start) {
      return (false, null);
    }

    try {
      return (true, jsonDecode(trimmed.substring(start, end + 1)));
    } on FormatException {
      return (false, null);
    }
  }

  /// The instructions that ask a model which is not constrained to the schema to answer with matching JSON.
  ///
  /// They are added after the caller's prompt, so the request reads as the task followed by the output format.
  static String instructionsFor(ResponseSchema schema) {
    final String schemaJson = const JsonEncoder.withIndent('  ').convert(schema.toJson());

    return 'Respond with only a JSON value that conforms to the following JSON Schema. Do not include any explanation, '
        'and do not wrap the JSON in Markdown.\n\nJSON Schema:\n$schemaJson';
  }

  /// The position of the first of [characters] in [text], or -1 if none is present.
  static int _firstIndexOfAny(String text, List<String> characters) {
    int first = -1;

    for (final String character in characters) {
      final int index = text.indexOf(character);

      if (index >= 0 && (first < 0 || index < first)) {
        first = index;
      }
    }

    return first;
  }

  /// The position of the last of [characters] in [text], or -1 if none is present.
  static int _lastIndexOfAny(String text, List<String> characters) {
    int last = -1;

    for (final String character in characters) {
      last = text.lastIndexOf(character) > last ? text.lastIndexOf(character) : last;
    }

    return last;
  }
}
