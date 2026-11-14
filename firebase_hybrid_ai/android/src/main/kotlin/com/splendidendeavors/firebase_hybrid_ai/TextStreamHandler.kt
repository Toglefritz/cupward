package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.GenerativeModel
import com.google.firebase.ai.type.PublicPreviewAPI
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Streams the response to one prompt to Dart, one chunk at a time.
 *
 * The handler belongs to a single request. It is registered on an event channel named by the request's token, and it
 * starts generating when Dart listens to that channel. Each chunk of text the SDK produces is sent with the source
 * that produced it. The stream ends when the SDK finishes, and it reports an error if the SDK fails. Cancelling the
 * Dart subscription cancels the collection of the SDK's flow, which stops the generation.
 *
 * [onFinished] is called once the request is over for any reason, so the plugin can unregister the channel. The sink is
 * used on the main thread, which is where the coroutine runs.
 */
@OptIn(PublicPreviewAPI::class)
internal class TextStreamHandler(
    private val model: GenerativeModel,
    private val prompt: String,
    private val onFinished: () -> Unit,
) : StreamTextGenerationStreamHandler() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** The collection of the SDK's flow, or null before Dart listens and after the request finishes. */
    private var job: Job? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<TextGenerationChunk>) {
        job = scope.launch {
            try {
                model.generateContentStream(prompt).collect { response ->
                    // Some chunks carry no text, such as the last one, which only holds usage details.
                    val text = response.text

                    if (!text.isNullOrEmpty()) {
                        sink.success(TextGenerationChunk(text = text, source = response.inferenceSource.toSource()))
                    }
                }

                sink.endOfStream()
            } catch (exception: CancellationException) {
                throw exception
            } catch (exception: Exception) {
                val error = exception.toGenerationError()
                sink.error(error.code, error.message, error.details)
            } finally {
                onFinished()
            }
        }
    }

    override fun onCancel(p0: Any?) {
        job?.cancel()
        job = null
        onFinished()
    }

    /** Stops any running generation and releases the coroutine scope. Called when the plugin detaches. */
    fun dispose() {
        scope.cancel()
    }
}
