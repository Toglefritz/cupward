import 'response_schema.dart';

/// A JSON object with named properties.
///
/// Every property is required unless it is listed in [optionalProperties]. An optional property can be absent or
/// `null`. Properties that the schema does not mention are allowed, as they are in JSON Schema.
class ObjectSchema extends ResponseSchema {
  /// Creates an object schema with the given [properties].
  const new({
    required this.properties,
    this.optionalProperties = const <String>[],
    super.description,
  });

  /// The schema of each property, by name. The order is kept when the schema is sent to the model.
  final Map<String, ResponseSchema> properties;

  /// The names of the properties that may be left out.
  final List<String> optionalProperties;

  @override
  String get type => 'object';

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...super.toJson(),
      'properties': <String, Object?>{
        for (final MapEntry<String, ResponseSchema> property in properties.entries)
          property.key: property.value.toJson(),
      },
      'required': <String>[
        for (final String name in properties.keys)
          if (!optionalProperties.contains(name)) name,
      ],
    };
  }

  @override
  void collectViolations(Object? value, String path, List<String> violations) {
    if (value is! Map<String, Object?>) {
      violations.add('$path must be an object, but is ${ResponseSchema.describeType(value)}.');

      return;
    }

    for (final MapEntry<String, ResponseSchema> property in properties.entries) {
      final String propertyPath = '$path.${property.key}';
      final bool isOptional = optionalProperties.contains(property.key);
      final Object? propertyValue = value[property.key];

      if (!value.containsKey(property.key) || propertyValue == null) {
        if (!isOptional) {
          violations.add('$propertyPath is required, but is missing.');
        }

        continue;
      }

      property.value.collectViolations(propertyValue, propertyPath, violations);
    }
  }
}
