import 'array_schema.dart';
import 'boolean_schema.dart';
import 'enum_schema.dart';
import 'integer_schema.dart';
import 'number_schema.dart';
import 'object_schema.dart';
import 'string_schema.dart';

/// Describes the JSON value that a structured response must contain.
///
/// A schema is built from the factory constructors, such as [ResponseSchema.object] and [ResponseSchema.string], and
/// passed to `FirebaseHybridAi.generateStructured`. The plugin uses it in two ways: it gives it to the platform, which
/// constrains the model's output where the platform supports that, and it validates the model's output against it on
/// every platform, so every response reports whether it conforms.
///
/// The types cover the subset of JSON Schema that the Firebase AI Logic SDKs accept for both on-device and cloud
/// models: objects, arrays, strings, integers, numbers, booleans, and string enumerations.
abstract class ResponseSchema {
  /// Creates a schema with an optional [description].
  const new({this.description});

  /// An object with the given [properties]. Every property is required unless it is listed in [optionalProperties].
  const factory object({
    required Map<String, ResponseSchema> properties,
    List<String> optionalProperties,
    String? description,
  }) = ObjectSchema;

  /// An array whose elements all match [items].
  const factory array({required ResponseSchema items, String? description}) = ArraySchema;

  /// A string.
  const factory string({String? description}) = StringSchema;

  /// A whole number.
  const factory integer({String? description}) = IntegerSchema;

  /// A number, which can have a fractional part.
  const factory number({String? description}) = NumberSchema;

  /// A boolean.
  const factory boolean({String? description}) = BooleanSchema;

  /// A string that must be one of [values].
  const factory enumeration(List<String> values, {String? description}) = EnumSchema;

  /// Explains the value to the model. Descriptions are sent with the schema and improve the model's output.
  final String? description;

  /// The JSON Schema name of the type, such as `object` or `string`.
  String get type;

  /// Converts the schema into a JSON Schema object that the SDKs accept.
  ///
  /// The map can be passed to `jsonEncode`. Subclasses add their own keywords to the ones produced here.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      if (description != null) 'description': description,
    };
  }

  /// Checks [value], a decoded JSON value, against the schema and returns a description of each problem.
  ///
  /// An empty list means that the value conforms. Each description names the location of the problem as a path from
  /// the root, such as `$.ingredients[2]`.
  List<String> validate(Object? value) {
    final List<String> violations = <String>[];
    collectViolations(value, r'$', violations);

    return violations;
  }

  /// Adds a description of each way that [value], found at [path], does not match the schema to [violations].
  ///
  /// This is the step that each type implements. [validate] calls it on the root value.
  void collectViolations(Object? value, String path, List<String> violations);

  /// The JSON type name of [value], used in violation messages.
  static String describeType(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return 'a string';
    }

    if (value is bool) {
      return 'a boolean';
    }

    if (value is num) {
      return 'a number';
    }

    if (value is List<Object?>) {
      return 'an array';
    }

    if (value is Map<String, Object?>) {
      return 'an object';
    }

    return 'an unknown value';
  }
}
