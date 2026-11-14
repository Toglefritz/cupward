import 'response_schema.dart';

/// A JSON string.
class StringSchema extends ResponseSchema {
  /// Creates a string schema.
  const new({super.description});

  @override
  String get type => 'string';

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! String) {
      violations.add('$path must be a string, but is ${ResponseSchema.describeType(value)}.');
    }
  }
}
