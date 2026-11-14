package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.PublicPreviewAPI
import com.google.firebase.ai.OnDeviceModelStatus as FirebaseOnDeviceModelStatus

/**
 * Converts the status reported by the Firebase AI Logic SDK into the availability value sent to Dart.
 *
 * Any status the SDK adds in the future that is not listed here maps to [OnDeviceModelAvailability.UNAVAILABLE],
 * because the plugin cannot assume that such a model is usable.
 */
@OptIn(PublicPreviewAPI::class)
internal fun FirebaseOnDeviceModelStatus.toAvailability(): OnDeviceModelAvailability =
    when (this) {
        FirebaseOnDeviceModelStatus.AVAILABLE -> OnDeviceModelAvailability.AVAILABLE
        FirebaseOnDeviceModelStatus.DOWNLOADABLE -> OnDeviceModelAvailability.DOWNLOADABLE
        FirebaseOnDeviceModelStatus.DOWNLOADING -> OnDeviceModelAvailability.DOWNLOADING
        else -> OnDeviceModelAvailability.UNAVAILABLE
    }
