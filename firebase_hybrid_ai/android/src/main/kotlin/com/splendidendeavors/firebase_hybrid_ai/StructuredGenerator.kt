package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.PublicPreviewAPI
import kotlinx.coroutines.CancellationException

/**
 * Generates a response that should match the JSON schema in [schemaJson], and returns its raw text.
 *
 * The SDK can only constrain the model to a schema that is built at run time when the request is cloud-only. For
 * on-device and hybrid inference it requires schemas generated from annotated Kotlin classes when the app is compiled,
 * which a plugin cannot provide for schemas that come from Dart. So:
 *
 * - With [InferenceMode.ONLY_IN_CLOUD], the schema is converted with [jsonSchemaFromJson] and passed to
 *   `generateObject`, and the response is reported as enforced.
 * - With any other mode, [instructedPrompt], which describes the schema in words, is sent with `generateContent`, and
 *   the response is reported as not enforced. The Dart side validates the text either way.
 *
 * @throws FlutterError with [ERROR_INVALID_SCHEMA] for a schema that cannot be converted, with [ERROR_EMPTY_RESPONSE]
 * if the response has no text, and with the codes of [toGenerationError] for SDK failures.
 */
@OptIn(PublicPreviewAPI::class)
internal suspend fun generateStructuredWithFirebaseAi(
    prompt: String,
    instructedPrompt: String,
    schemaJson: String,
    mode: InferenceMode,
    category: OnDeviceModelCategory,
    cloudModelName: String,
): StructuredTextResponse {
    val isEnforced = mode == InferenceMode.ONLY_IN_CLOUD

    // The schema is converted before the request so that an invalid schema is reported as such, and not as a
    // generation failure.
    val schema = if (isEnforced) jsonSchemaFromJson(schemaJson) else null
    val model = createGenerativeModel(cloudModelName, mode.toSdkMode(), category)

    val response = try {
        if (schema != null) model.generateObject(schema, prompt).response else model.generateContent(instructedPrompt)
    } catch (exception: CancellationException) {
        throw exception
    } catch (exception: Exception) {
        throw exception.toGenerationError()
    }

    val text = response.text
        ?: throw FlutterError(ERROR_EMPTY_RESPONSE, "The model returned a response that holds no text.", null)

    return StructuredTextResponse(
        text = text,
        source = response.inferenceSource.toSource(),
        isSchemaEnforced = isEnforced,
    )
}
