package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.Firebase
import com.google.firebase.ai.InferenceMode
import com.google.firebase.ai.OnDeviceConfig
import com.google.firebase.ai.OnDeviceExtension
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.ai.type.PublicPreviewAPI

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
 * Returns the Firebase AI Logic extension that checks and downloads the on-device model.
 *
 * The SDK exposes these operations only through a `GenerativeModel`, so this builds one in `PREFER_ON_DEVICE` mode.
 * Creating the model sends no request. This requires a default `FirebaseApp`.
 *
 * @throws FlutterError with [ERROR_FIREBASE_NOT_INITIALIZED] if Firebase is not initialized, or with
 * [ERROR_ON_DEVICE_UNSUPPORTED] if the SDK provides no extension.
 */
@OptIn(PublicPreviewAPI::class)
internal fun createOnDeviceExtension(): OnDeviceExtension {
    val model = try {
        Firebase.ai(backend = GenerativeBackend.googleAI()).generativeModel(
            modelName = PLACEHOLDER_CLOUD_MODEL_NAME,
            onDeviceConfig = OnDeviceConfig(mode = InferenceMode.PREFER_ON_DEVICE),
        )
    } catch (exception: IllegalStateException) {
        throw FlutterError(
            ERROR_FIREBASE_NOT_INITIALIZED,
            "Firebase must be initialized before the on-device model can be used.",
            exception.message,
        )
    }

    return model.onDeviceExtension
        ?: throw FlutterError(
            ERROR_ON_DEVICE_UNSUPPORTED,
            "The Firebase AI Logic SDK did not provide an on-device extension.",
            null,
        )
}
