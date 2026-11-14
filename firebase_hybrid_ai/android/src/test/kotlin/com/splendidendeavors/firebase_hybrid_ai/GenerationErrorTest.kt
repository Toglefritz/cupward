package com.splendidendeavors.firebase_hybrid_ai

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

/** Verifies how failures from text generation become the errors that Dart receives. */
internal class GenerationErrorTest {
    @Test
    fun flutterError_isReturnedUnchanged() {
        val original = FlutterError(ERROR_FIREBASE_NOT_INITIALIZED, "No Firebase app", null)

        assertSame(original, original.toGenerationError())
    }

    @Test
    fun otherException_becomesGenerationFailedWithItsMessage() {
        val error = IllegalStateException("Quota exceeded").toGenerationError()

        assertEquals(ERROR_GENERATION_FAILED, error.code)
        assertEquals("Quota exceeded", error.message)
    }
}
