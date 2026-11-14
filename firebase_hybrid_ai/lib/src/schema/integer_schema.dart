import 'response_schema.dart';

/// A whole number.
///
/// A number with no fractional part, such as `3.0`, also conforms, because JSON does not distinguish it from `3`.
class IntegerSchema extends ResponseSchema {
  /// Creates an integer schema.
  const new({super.description});

  @override
  String get type => 'integer';

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! num || value != value.roundToDouble()) {
      violations.add('$path must be a whole number, but is ${ResponseSchema.describeType(value)}.');
    }
  }
}
