package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.Firebase
import com.google.firebase.ai.InferenceMode
import com.google.firebase.ai.OnDeviceConfig
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.ai.type.PublicPreviewAPI
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Android host implementation of the plugin.
 *
 * Registers the Pigeon host API and forwards each call to the Firebase AI Logic hybrid SDK. Pigeon invokes the
 * `suspend` functions on the main thread, and an exception thrown from one is returned to Dart as a
 * `PlatformException`.
 */
@OptIn(PublicPreviewAPI::class)
class FirebaseHybridAiPlugin :
    FlutterPlugin,
    FirebaseHybridAiHostApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(binding.binaryMessenger, null)
    }

    /**
     * Reports whether the on-device model can be used, using the Firebase AI Logic SDK.
     *
     * The SDK exposes the on-device status through a `GenerativeModel`, so this builds one in
     * `PREFER_ON_DEVICE` mode. Creating the model sends no request, which means the cloud model name is never
     * contacted. This requires a default `FirebaseApp`, so a missing one is reported as
     * [ERROR_FIREBASE_NOT_INITIALIZED].
     *
     * @throws FlutterError if Firebase is not initialized or the SDK reports a failure.
     */
    override suspend fun checkOnDeviceStatus(): OnDeviceModelStatus {
        val model = try {
            Firebase.ai(backend = GenerativeBackend.googleAI()).generativeModel(
                modelName = PLACEHOLDER_CLOUD_MODEL_NAME,
                onDeviceConfig = OnDeviceConfig(mode = InferenceMode.PREFER_ON_DEVICE),
            )
        } catch (exception: IllegalStateException) {
            throw FlutterError(
                ERROR_FIREBASE_NOT_INITIALIZED,
                "Firebase must be initialized before the on-device model status can be checked.",
                exception.message,
            )
        }

        val extension = model.onDeviceExtension
            ?: throw FlutterError(
                ERROR_ON_DEVICE_UNSUPPORTED,
                "The Firebase AI Logic SDK did not provide an on-device extension.",
                null,
            )

        return try {
            val availability = extension.checkStatus().toAvailability()

            // The model name is only meaningful once a model exists on the device, and a failure to read it must
            // not hide the availability result.
            val modelName = if (availability == OnDeviceModelAvailability.AVAILABLE) {
                runCatching { extension.getModelName() }.getOrNull()
            } else {
                null
            }

            OnDeviceModelStatus(availability = availability, modelName = modelName)
        } catch (exception: Exception) {
            throw FlutterError(ERROR_STATUS_CHECK_FAILED, exception.message, exception.toString())
        }
    }

    private companion object {
        /**
         * Cloud model name used when building the model for a status check. The name is required by the SDK but is
         * never sent anywhere, because a status check makes no inference request.
         */
        const val PLACEHOLDER_CLOUD_MODEL_NAME = "gemini-3.8-flash"

        /** Error code returned to Dart when no default `FirebaseApp` exists. */
        const val ERROR_FIREBASE_NOT_INITIALIZED = "firebase-not-initialized"

        /** Error code returned to Dart when the SDK does not expose an on-device extension. */
        const val ERROR_ON_DEVICE_UNSUPPORTED = "on-device-unsupported"

        /** Error code returned to Dart when the SDK throws while checking the model status. */
        const val ERROR_STATUS_CHECK_FAILED = "status-check-failed"
    }
}
