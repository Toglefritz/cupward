import 'response_schema.dart';

/// A JSON boolean.
class BooleanSchema extends ResponseSchema {
  /// Creates a boolean schema.
  const new({super.description});

  @override
  String get type => 'boolean';

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! bool) {
      violations.add('$path must be a boolean, but is ${ResponseSchema.describeType(value)}.');
    }
  }
}
