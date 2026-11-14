package com.splendidendeavors.firebase_hybrid_ai

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
    /**
     * Streams download progress to Dart, one handler for each model category. They are created when the plugin
     * attaches and disposed when it detaches.
     */
    private var downloadHandlers: List<OnDeviceModelDownloadHandler> = emptyList()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)

        // Event channels cannot take parameters, so each category gets its own channel, named after the category.
        downloadHandlers = OnDeviceModelCategory.values().map { category ->
            OnDeviceModelDownloadHandler(category).also { handler ->
                DownloadOnDeviceModelStreamHandler.register(
                    flutterPluginBinding.binaryMessenger,
                    handler,
                    category.channelInstanceName,
                )
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(binding.binaryMessenger, null)

        // Passing null removes the handler registration for a channel.
        OnDeviceModelCategory.values().forEach { category ->
            DownloadOnDeviceModelEventChannel(binding.binaryMessenger, category.channelInstanceName)
                .setStreamHandler(null)
        }
        downloadHandlers.forEach { it.dispose() }
        downloadHandlers = emptyList()
    }

    /**
     * Reports whether the on-device model can be used, using the Firebase AI Logic SDK.
     *
     * The SDK exposes the on-device status through a `GenerativeModel`, so this builds one in
     * `PREFER_ON_DEVICE` mode with the given [category] of model. Creating the model sends no request, which means
     * the cloud model name is never contacted. This requires a default `FirebaseApp`, so a missing one is reported as
     * [ERROR_FIREBASE_NOT_INITIALIZED].
     *
     * @throws FlutterError if Firebase is not initialized or the SDK reports a failure.
     */
    override suspend fun checkOnDeviceStatus(category: OnDeviceModelCategory): OnDeviceModelStatus {
        val extension = createOnDeviceExtension(category)

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
        /** Error code returned to Dart when the SDK throws while checking the model status. */
        const val ERROR_STATUS_CHECK_FAILED = "status-check-failed"
    }
}
