package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.FirebaseAIException
import com.google.firebase.ai.type.FirebaseAIOnDeviceNotAvailableException
import com.google.firebase.ai.type.PublicPreviewAPI
import kotlinx.coroutines.CancellationException

/** Error code returned to Dart when `ONLY_ON_DEVICE` was requested and the on-device model cannot serve it. */
internal const val ERROR_ON_DEVICE_UNAVAILABLE = "on-device-unavailable"

/** Error code returned to Dart when the SDK fails to generate a response. */
internal const val ERROR_GENERATION_FAILED = "generation-failed"

/** Error code returned to Dart when the SDK returns a response that holds no text. */
internal const val ERROR_EMPTY_RESPONSE = "empty-response"

/**
 * Converts a failure from the Firebase AI Logic SDK into the error that Dart receives.
 *
 * A [FlutterError] is returned unchanged, because it already carries the code that Dart expects. An on-device model
 * that cannot serve the request becomes [ERROR_ON_DEVICE_UNAVAILABLE], so Dart can tell that case apart from other
 * failures. Everything else becomes [ERROR_GENERATION_FAILED], with the original exception text in the details.
 */
@OptIn(PublicPreviewAPI::class)
internal fun Throwable.toGenerationError(): FlutterError =
    when (this) {
        is FlutterError -> this
        is FirebaseAIOnDeviceNotAvailableException -> FlutterError(ERROR_ON_DEVICE_UNAVAILABLE, message, toString())
        is FirebaseAIException -> FlutterError(ERROR_GENERATION_FAILED, message, toString())
        else -> FlutterError(ERROR_GENERATION_FAILED, message, toString())
    }

/**
 * Sends [prompt] through the Firebase AI Logic SDK and returns the text with the source that produced it.
 *
 * The [mode] decides whether the on-device model of the given [category], the cloud model named [cloudModelName], or
 * both are used. The SDK reports which one answered, and that value is returned unchanged.
 *
 * @throws FlutterError with [ERROR_ON_DEVICE_UNAVAILABLE] if on-device inference was required and not possible,
 * with [ERROR_EMPTY_RESPONSE] if the response has no text, and with [ERROR_GENERATION_FAILED] for any other SDK
 * failure. A missing Firebase app is reported as [ERROR_FIREBASE_NOT_INITIALIZED].
 */
@OptIn(PublicPreviewAPI::class)
internal suspend fun generateTextWithFirebaseAi(
    prompt: String,
    mode: InferenceMode,
    category: OnDeviceModelCategory,
    cloudModelName: String,
): TextGenerationResult {
    val model = createGenerativeModel(cloudModelName, mode.toSdkMode(), category)

    val response = try {
        model.generateContent(prompt)
    } catch (exception: CancellationException) {
        throw exception
    } catch (exception: Exception) {
        throw exception.toGenerationError()
    }

    val text = response.text
        ?: throw FlutterError(ERROR_EMPTY_RESPONSE, "The model returned a response that holds no text.", null)

    return TextGenerationResult(text = text, source = response.inferenceSource.toSource())
}
