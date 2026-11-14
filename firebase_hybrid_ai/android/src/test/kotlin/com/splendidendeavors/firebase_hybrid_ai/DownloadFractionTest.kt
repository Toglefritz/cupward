package com.splendidendeavors.firebase_hybrid_ai

import kotlin.test.Test
import kotlin.test.assertEquals

/** Verifies the conversion of byte counts into the 0.0 to 1.0 fraction sent to Dart. */
internal class DownloadFractionTest {
    @Test
    fun halfDownloaded_returnsHalf() {
        assertEquals(0.5, downloadFraction(bytesDownloaded = 50L, bytesToDownload = 100L))
    }

    @Test
    fun nothingDownloaded_returnsZero() {
        assertEquals(0.0, downloadFraction(bytesDownloaded = 0L, bytesToDownload = 100L))
    }

    @Test
    fun overshoot_isClampedToOne() {
        assertEquals(1.0, downloadFraction(bytesDownloaded = 120L, bytesToDownload = 100L))
    }

    @Test
    fun unknownTotal_returnsZeroInsteadOfDividingByZero() {
        assertEquals(0.0, downloadFraction(bytesDownloaded = 10L, bytesToDownload = 0L))
    }
}
