/// The kind of response that the example asks the model for.
enum ResponseFormat {
  /// Free text, generated with `generateText` or `generateTextStream`.
  text,

  /// JSON that matches a schema, generated with `generateStructured`.
  structured,
}
