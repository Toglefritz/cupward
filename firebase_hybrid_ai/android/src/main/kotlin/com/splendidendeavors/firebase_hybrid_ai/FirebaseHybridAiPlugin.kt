package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.PublicPreviewAPI
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import java.util.UUID

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

    /** The messenger of the attached engine, which is needed to register event channels while the plugin runs. */
    private var messenger: BinaryMessenger? = null

    /**
     * The streamed generations that are prepared or running, by token. A request is added by [prepareTextStream]
     * and removed when its stream ends, fails, or is cancelled, or when the plugin detaches.
     */
    private val textStreams: MutableMap<String, TextStreamHandler> = mutableMapOf()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        messenger = flutterPluginBinding.binaryMessenger

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

        textStreams.keys.toList().forEach { token -> finishTextStream(token) }
        messenger = null
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

    /**
     * Generates text for [prompt] with the Firebase AI Logic hybrid SDK. See [generateTextWithFirebaseAi] for how the
     * arguments are used and which errors it returns.
     */
    override suspend fun generateText(
        prompt: String,
        mode: InferenceMode,
        category: OnDeviceModelCategory,
        cloudModelName: String,
    ): TextGenerationResult =
        generateTextWithFirebaseAi(prompt, mode, category, cloudModelName)

    /**
     * Prepares a streamed generation and returns the token that names its event channel.
     *
     * The model is created here so that a missing Firebase app is reported to the caller right away. The handler is
     * registered under a new token and starts generating only when Dart listens to the channel.
     */
    override suspend fun prepareTextStream(
        prompt: String,
        mode: InferenceMode,
        category: OnDeviceModelCategory,
        cloudModelName: String,
    ): String {
        val binaryMessenger = messenger
            ?: throw FlutterError(ERROR_GENERATION_FAILED, "The plugin is not attached to a Flutter engine.", null)

        val model = createGenerativeModel(cloudModelName, mode.toSdkMode(), category)
        val token = UUID.randomUUID().toString()

        val handler = TextStreamHandler(model, prompt) { finishTextStream(token) }
        textStreams[token] = handler
        StreamTextGenerationStreamHandler.register(binaryMessenger, handler, token)

        return token
    }

    /**
     * Ends the streamed generation with the given [token]: stops it, unregisters its channel, and forgets it.
     *
     * This is safe to call more than once for the same token, because the stream can finish and be cancelled at
     * nearly the same time.
     */
    private fun finishTextStream(token: String) {
        val handler = textStreams.remove(token) ?: return

        messenger?.let { StreamTextGenerationEventChannel(it, token).setStreamHandler(null) }
        handler.dispose()
    }

    private companion object {
        /** Error code returned to Dart when the SDK throws while checking the model status. */
        const val ERROR_STATUS_CHECK_FAILED = "status-check-failed"
    }
}
