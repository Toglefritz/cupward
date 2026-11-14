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
    /** Streams download progress to Dart. Created when the plugin attaches and disposed when it detaches. */
    private var downloadHandler: OnDeviceModelDownloadHandler? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)

        val handler = OnDeviceModelDownloadHandler()
        downloadHandler = handler
        DownloadOnDeviceModelStreamHandler.register(flutterPluginBinding.binaryMessenger, handler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(binding.binaryMessenger, null)

        // Passing null removes the handler registration for this channel.
        DownloadOnDeviceModelEventChannel(binding.binaryMessenger).setStreamHandler(null)
        downloadHandler?.dispose()
        downloadHandler = null
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
        val extension = createOnDeviceExtension()

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
