package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.JsonSchema
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive

/** Error code returned to Dart when a schema sent from Dart uses something that the SDK's schema type cannot express. */
internal const val ERROR_INVALID_SCHEMA = "invalid-schema"

/**
 * Builds the Firebase AI Logic `JsonSchema` that matches a JSON Schema object sent from Dart.
 *
 * Dart sends the subset of JSON Schema that its `ResponseSchema` type produces: the types `object`, `array`, `string`
 * (optionally with `enum`), `integer`, `number`, and `boolean`, with `description`, `properties`, `required`, and
 * `items`. An object property that is not listed in `required` becomes an optional property.
 *
 * @throws FlutterError with [ERROR_INVALID_SCHEMA] if the JSON is not a schema of that form.
 */
internal fun jsonSchemaFromJson(schemaJson: String): JsonSchema<*> {
    val element = try {
        Json.parseToJsonElement(schemaJson)
    } catch (exception: Exception) {
        throw FlutterError(ERROR_INVALID_SCHEMA, "The schema is not valid JSON.", exception.message)
    }

    if (element !is JsonObject) {
        throw FlutterError(ERROR_INVALID_SCHEMA, "The schema must be a JSON object.", null)
    }

    return convert(element, path = "$")
}

/** Converts one schema object, found at [path], and its children. */
private fun convert(schema: JsonObject, path: String): JsonSchema<*> {
    val description = schema.stringOrNull("description")

    return when (val type = schema.stringOrNull("type")) {
        "object" -> {
            val properties = schema["properties"] as? JsonObject ?: JsonObject(emptyMap())
            val required = (schema["required"] as? JsonArray)?.mapNotNull { it.jsonPrimitive.contentOrNull }.orEmpty()

            JsonSchema.obj(
                properties = properties.mapValues { (name, value) ->
                    val child = value as? JsonObject
                        ?: throw FlutterError(ERROR_INVALID_SCHEMA, "$path.$name must be a schema object.", null)

                    convert(child, "$path.$name")
                },
                optionalProperties = properties.keys.filterNot { it in required },
                description = description,
            )
        }

        "array" -> {
            val items = schema["items"] as? JsonObject
                ?: throw FlutterError(ERROR_INVALID_SCHEMA, "$path must define items.", null)

            JsonSchema.array(items = convert(items, "$path[]"), description = description)
        }

        "string" -> {
            val values = (schema["enum"] as? JsonArray)?.mapNotNull { it.jsonPrimitive.contentOrNull }

            if (values == null) {
                JsonSchema.string(description = description)
            } else {
                JsonSchema.enumeration(values = values, description = description)
            }
        }

        "integer" -> JsonSchema.integer(description = description)
        "number" -> JsonSchema.double(description = description)
        "boolean" -> JsonSchema.boolean(description = description)

        else -> throw FlutterError(ERROR_INVALID_SCHEMA, "$path has an unsupported type: $type.", null)
    }
}

/** The string value of the property [name], or null if it is missing or not a string. */
private fun JsonObject.stringOrNull(name: String): String? = (this[name] as? JsonPrimitive)?.contentOrNull
