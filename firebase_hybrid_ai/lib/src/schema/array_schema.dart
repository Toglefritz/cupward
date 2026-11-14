import 'response_schema.dart';

/// A JSON array whose elements all match [items].
class ArraySchema extends ResponseSchema {
  /// Creates an array schema whose elements match [items].
  const new({required this.items, super.description});

  /// The schema that every element must match.
  final ResponseSchema items;

  @override
  String get type => 'array';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{...super.toJson(), 'items': items.toJson()};
  }

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! List<Object?>) {
      violations.add('$path must be an array, but is ${ResponseSchema.describeType(value)}.');

      return;
    }

    for (int index = 0; index < value.length; index++) {
      items.collectViolations(value[index], '$path[$index]', violations);
    }
  }
}
