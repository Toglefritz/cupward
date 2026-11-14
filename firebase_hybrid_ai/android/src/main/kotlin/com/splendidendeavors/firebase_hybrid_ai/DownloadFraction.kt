package com.splendidendeavors.firebase_hybrid_ai

/**
 * Converts byte counts from a download into the fraction sent to Dart.
 *
 * The result is clamped to the range 0.0 to 1.0, because the SDK reports a running total that can briefly exceed
 * the announced size. When [bytesToDownload] is zero or negative the total is unknown, and the result is 0.0
 * instead of a division by zero.
 */
internal fun downloadFraction(bytesDownloaded: Long, bytesToDownload: Long): Double {
    if (bytesToDownload <= 0L) {
        return 0.0
    }

    return (bytesDownloaded.toDouble() / bytesToDownload.toDouble()).coerceIn(0.0, 1.0)
}
