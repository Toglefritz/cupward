package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.PublicPreviewAPI
import kotlin.test.Test
import kotlin.test.assertEquals
import com.google.firebase.ai.OnDeviceModelStatus as FirebaseOnDeviceModelStatus

/**
 * Verifies the conversion from Firebase AI Logic on-device statuses to the values sent to Dart. Calls into the
 * Firebase SDK itself are covered by running the example app on a device.
 */
@OptIn(PublicPreviewAPI::class)
internal class FirebaseHybridAiPluginTest {
    @Test
    fun available_mapsToAvailable() {
        assertEquals(OnDeviceModelAvailability.AVAILABLE, FirebaseOnDeviceModelStatus.AVAILABLE.toAvailability())
    }

    @Test
    fun downloadable_mapsToDownloadable() {
        assertEquals(
            OnDeviceModelAvailability.DOWNLOADABLE,
            FirebaseOnDeviceModelStatus.DOWNLOADABLE.toAvailability(),
        )
    }

    @Test
    fun downloading_mapsToDownloading() {
        assertEquals(
            OnDeviceModelAvailability.DOWNLOADING,
            FirebaseOnDeviceModelStatus.DOWNLOADING.toAvailability(),
        )
    }

    @Test
    fun unavailable_mapsToUnavailable() {
        assertEquals(
            OnDeviceModelAvailability.UNAVAILABLE,
            FirebaseOnDeviceModelStatus.UNAVAILABLE.toAvailability(),
        )
    }
}
