import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  /// Builds the Foundation Models schema that matches a JSON Schema object sent from Dart.
  ///
  /// Dart sends the subset of JSON Schema that its `ResponseSchema` type produces: the types `object`, `array`, `string`
  /// (optionally with `enum`), `integer`, `number`, and `boolean`, with `description`, `properties`, `required`, and
  /// `items`. An object property that is not listed in `required` becomes an optional property.
  ///
  /// The same schema constrains both the on-device model and the cloud Gemini model, because both are used through
  /// `LanguageModelSession`.
  @available(iOS 26.0, *)
  enum JsonSchemaConverter {
    /// Returns the schema for [schemaJson].
    ///
    /// Throws a `HybridAiFailure` with the `invalid-schema` code if the text is not a JSON Schema object of the form
    /// above. Throws the framework's own error if the framework rejects an otherwise valid schema, for example one
    /// whose root is not an object. The caller then asks for the JSON in the prompt instead.
    static func generationSchema(from schemaJson: String) throws -> GenerationSchema {
      let root = try parse(schemaJson)
      let dynamic = try dynamicSchema(from: root, name: "Response", path: "$")
      return try GenerationSchema(root: dynamic, dependencies: [])
    }

    /// Decodes [schemaJson] into a dictionary, or throws the `invalid-schema` failure.
    static func parse(_ schemaJson: String) throws -> [String: Any] {
      let object: Any
      do {
        object = try JSONSerialization.jsonObject(with: Data(schemaJson.utf8))
      } catch {
        throw HybridAiFailure(
          HybridAiFailure.invalidSchema,
          "The schema is not valid JSON.",
          details: error.localizedDescription
        )
      }
      guard let dictionary = object as? [String: Any] else {
        throw HybridAiFailure(HybridAiFailure.invalidSchema, "The schema must be a JSON object.")
      }
      return dictionary
    }

    /// Converts the schema [json], found at [path], and its children.
    ///
    /// Each object and enum needs a name that is unique in the schema, so [name] is built from the property names that
    /// lead to it.
    private static func dynamicSchema(
      from json: [String: Any],
      name: String,
      path: String
    ) throws -> DynamicGenerationSchema {
      let description = json["description"] as? String

      switch json["type"] as? String {
      case "object":
        let properties = json["properties"] as? [String: Any] ?? [:]
        let required = Set((json["required"] as? [Any])?.compactMap { $0 as? String } ?? [])
        // JSON objects have no order once decoded, so the properties are sorted to make the schema the same every time.
        let converted: [DynamicGenerationSchema.Property] = try properties.keys.sorted().map { key in
          guard let child = properties[key] as? [String: Any] else {
            throw HybridAiFailure(
              HybridAiFailure.invalidSchema,
              "\(path).\(key) must be a schema object."
            )
          }
          return DynamicGenerationSchema.Property(
            name: key,
            description: child["description"] as? String,
            schema: try dynamicSchema(from: child, name: "\(name)_\(key)", path: "\(path).\(key)"),
            isOptional: !required.contains(key)
          )
        }
        return DynamicGenerationSchema(name: name, description: description, properties: converted)

      case "array":
        guard let items = json["items"] as? [String: Any] else {
          throw HybridAiFailure(HybridAiFailure.invalidSchema, "\(path) must define items.")
        }
        return DynamicGenerationSchema(
          arrayOf: try dynamicSchema(from: items, name: "\(name)_item", path: "\(path)[]")
        )

      case "string":
        if let values = json["enum"] as? [Any] {
          return DynamicGenerationSchema(
            name: name,
            description: description,
            anyOf: values.compactMap { $0 as? String }
          )
        }
        return DynamicGenerationSchema(type: String.self)

      case "integer":
        return DynamicGenerationSchema(type: Int.self)

      case "number":
        return DynamicGenerationSchema(type: Double.self)

      case "boolean":
        return DynamicGenerationSchema(type: Bool.self)

      case let type:
        throw HybridAiFailure(
          HybridAiFailure.invalidSchema,
          "\(path) has an unsupported type: \(type ?? "none")."
        )
      }
    }
  }
#endif
