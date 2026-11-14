import 'response_schema.dart';

/// A number, which can have a fractional part.
class NumberSchema extends ResponseSchema {
  /// Creates a number schema.
  const new({super.description});

  @override
  String get type => 'number';

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! num) {
      violations.add('$path must be a number, but is ${ResponseSchema.describeType(value)}.');
    }
  }
}
