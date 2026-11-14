package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.DownloadStatus
import com.google.firebase.ai.type.PublicPreviewAPI
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Streams the progress of an on-device model download to Dart.
 *
 * Each Dart listener starts one download through the Firebase AI Logic SDK and receives its progress as fractions.
 * The stream ends when the SDK reports completion and reports an error if the SDK reports failure. Cancelling the
 * Dart subscription stops this handler from listening, but the SDK may finish the download in the background.
 * The sink is used on the main thread, which is where the coroutine runs.
 */
@OptIn(PublicPreviewAPI::class)
internal class OnDeviceModelDownloadHandler : DownloadOnDeviceModelStreamHandler() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** The collection of the active download, or null when no listener is attached. */
    private var job: Job? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<OnDeviceModelDownloadProgress>) {
        job?.cancel()

        job = scope.launch {
            try {
                var bytesToDownload = 0L

                createOnDeviceExtension().download().collect { status ->
                    when (status) {
                        is DownloadStatus.DownloadStarted -> {
                            bytesToDownload = status.bytesToDownload
                            sink.success(OnDeviceModelDownloadProgress(fraction = 0.0))
                        }

                        is DownloadStatus.DownloadInProgress -> {
                            val fraction = downloadFraction(status.totalBytesDownloaded, bytesToDownload)
                            sink.success(OnDeviceModelDownloadProgress(fraction = fraction))
                        }

                        is DownloadStatus.DownloadCompleted -> {
                            sink.success(OnDeviceModelDownloadProgress(fraction = 1.0))
                            sink.endOfStream()
                        }

                        is DownloadStatus.DownloadFailed ->
                            sink.error(ERROR_DOWNLOAD_FAILED, status.exception.message, status.exception.toString())

                        else -> Unit
                    }
                }
            } catch (exception: CancellationException) {
                throw exception
            } catch (exception: FlutterError) {
                sink.error(exception.code, exception.message, exception.details)
            } catch (exception: Exception) {
                sink.error(ERROR_DOWNLOAD_FAILED, exception.message, exception.toString())
            }
        }
    }

    override fun onCancel(p0: Any?) {
        job?.cancel()
        job = null
    }

    /** Stops any active download collection and releases the coroutine scope. Called when the plugin detaches. */
    fun dispose() {
        scope.cancel()
    }

    private companion object {
        /** Error code returned to Dart when the SDK reports that the download failed. */
        const val ERROR_DOWNLOAD_FAILED = "download-failed"
    }
}
