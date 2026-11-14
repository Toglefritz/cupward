import 'response_schema.dart';

/// A string that must be one of a fixed set of [values].
///
/// Use it for classification, where the model must choose a label instead of writing its own.
class EnumSchema extends ResponseSchema {
  /// Creates an enumeration of [values].
  const new(this.values, {super.description});

  /// The strings that the value can be.
  final List<String> values;

  @override
  String get type => 'string';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{...super.toJson(), 'enum': values};
  }

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! String) {
      violations.add('$path must be one of ${values.join(', ')}, but is ${ResponseSchema.describeType(value)}.');

      return;
    }

    if (!values.contains(value)) {
      violations.add('$path must be one of ${values.join(', ')}, but is "$value".');
    }
  }
}
