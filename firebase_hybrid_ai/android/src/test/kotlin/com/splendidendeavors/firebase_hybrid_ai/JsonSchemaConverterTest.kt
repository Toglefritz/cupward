package com.splendidendeavors.firebase_hybrid_ai

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** Verifies that schemas sent from Dart become SDK schemas with the same types, descriptions, and required fields. */
internal class JsonSchemaConverterTest {
    @Test
    fun objectSchema_keepsPropertiesAndMarksUnrequiredOnesOptional() {
        val schema = jsonSchemaFromJson(
            """
            {
              "type": "object",
              "description": "An animal fact",
              "properties": {
                "animal": { "type": "string" },
                "category": { "type": "string", "enum": ["diet", "habitat"] },
                "legs": { "type": "integer" }
              },
              "required": ["animal", "category"]
            }
            """,
        )

        assertEquals("OBJECT", schema.type.uppercase())
        assertEquals("An animal fact", schema.description)
        assertEquals(listOf("animal", "category", "legs"), schema.properties?.keys?.toList())
        assertEquals(listOf("animal", "category"), schema.required)
        assertEquals(listOf("diet", "habitat"), schema.properties?.get("category")?.enum)
        assertEquals("INTEGER", schema.properties?.get("legs")?.type?.uppercase())
    }

    @Test
    fun arraySchema_convertsItsItems() {
        val schema = jsonSchemaFromJson("""{ "type": "array", "items": { "type": "number" } }""")

        assertEquals("ARRAY", schema.type.uppercase())
        assertEquals("NUMBER", schema.items?.type?.uppercase())
    }

    @Test
    fun unsupportedType_isRejectedWithInvalidSchema() {
        val error = assertFailsWith<FlutterError> { jsonSchemaFromJson("""{ "type": "date" }""") }

        assertEquals(ERROR_INVALID_SCHEMA, error.code)
    }

    @Test
    fun malformedJson_isRejectedWithInvalidSchema() {
        val error = assertFailsWith<FlutterError> { jsonSchemaFromJson("{ not json") }

        assertEquals(ERROR_INVALID_SCHEMA, error.code)
    }
}
