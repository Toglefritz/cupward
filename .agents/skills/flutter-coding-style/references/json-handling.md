# JSON Handling

- Do not use code generation such as `json_serializable`. Keep parsing explicit and readable.
- Every model has a `fromJson` factory and a `toJson` method.
- Use explicit `as` casts, `(x as num).toDouble()` for doubles, and handle nullable fields deliberately.
- Validate required fields and throw meaningful errors. Document the expected JSON shape in the class Dartdoc.

```dart
class ScaleReading {
  const ScaleReading({required this.id, required this.grams});

  final String id;
  final double grams;

  factory ScaleReading.fromJson(Map<String, dynamic> json) {
    try {
      return ScaleReading(
        id: json['id'] as String? ??
            (throw ArgumentError('Missing required field: id')),
        grams: (json['grams'] as num).toDouble(),
      );
    } catch (e) {
      throw FormatException('Failed to parse ScaleReading from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'grams': grams,
      };
}
```
