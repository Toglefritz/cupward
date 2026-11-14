package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.Firebase
import com.google.firebase.ai.GenerativeModel
import com.google.firebase.ai.OnDeviceConfig
import com.google.firebase.ai.OnDeviceExtension
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.ai.type.PublicPreviewAPI
import com.google.firebase.ai.InferenceMode as SdkInferenceMode

/** Error code returned to Dart when no default `FirebaseApp` exists. */
internal const val ERROR_FIREBASE_NOT_INITIALIZED = "firebase-not-initialized"

/** Error code returned to Dart when the SDK does not expose an on-device extension. */
internal const val ERROR_ON_DEVICE_UNSUPPORTED = "on-device-unsupported"

/**
 * Cloud model name used when building a model only to reach its on-device extension. The name is required by the
 * SDK but is never sent anywhere, because status checks and downloads make no inference request.
 */
private const val PLACEHOLDER_CLOUD_MODEL_NAME = "gemini-3.5-flash-lite"

/**
 * Builds a Firebase AI Logic model that can use the on-device model of the given [category], the cloud model named
 * [cloudModelName], or both, as chosen by [mode].
 *
 * Creating the model sends no request. This requires a default `FirebaseApp`.
 *
 * @throws FlutterError with [ERROR_FIREBASE_NOT_INITIALIZED] if Firebase is not initialized.
 */
@OptIn(PublicPreviewAPI::class)
internal fun createGenerativeModel(
    cloudModelName: String,
    mode: SdkInferenceMode,
    category: OnDeviceModelCategory,
): GenerativeModel {
    return try {
        Firebase.ai(backend = GenerativeBackend.googleAI()).generativeModel(
            modelName = cloudModelName,
            onDeviceConfig = OnDeviceConfig(
                mode = mode,
                modelOption = category.toModelOption(),
            ),
        )
    } catch (exception: IllegalStateException) {
        throw FlutterError(
            ERROR_FIREBASE_NOT_INITIALIZED,
            "Firebase must be initialized before the on-device model can be used.",
            exception.message,
        )
    }
}

/**
 * Returns the Firebase AI Logic extension that checks and downloads the on-device model of the given [category].
 *
 * The SDK exposes these operations only through a `GenerativeModel`, so this builds one in `PREFER_ON_DEVICE` mode
 * with a placeholder cloud model name. The [category] decides the release stage and size of the model that AICore
 * checks and downloads.
 *
 * @throws FlutterError with [ERROR_FIREBASE_NOT_INITIALIZED] if Firebase is not initialized, or with
 * [ERROR_ON_DEVICE_UNSUPPORTED] if the SDK provides no extension.
 */
@OptIn(PublicPreviewAPI::class)
internal fun createOnDeviceExtension(category: OnDeviceModelCategory): OnDeviceExtension {
    val model = createGenerativeModel(PLACEHOLDER_CLOUD_MODEL_NAME, SdkInferenceMode.PREFER_ON_DEVICE, category)

    return model.onDeviceExtension
        ?: throw FlutterError(
            ERROR_ON_DEVICE_UNSUPPORTED,
            "The Firebase AI Logic SDK did not provide an on-device extension.",
            null,
        )
}
