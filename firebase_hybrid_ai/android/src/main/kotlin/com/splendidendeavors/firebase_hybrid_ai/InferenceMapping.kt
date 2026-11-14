package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.PublicPreviewAPI
import com.google.firebase.ai.InferenceMode as SdkInferenceMode
import com.google.firebase.ai.InferenceSource as SdkInferenceSource

/** Converts the mode chosen in Dart into the mode the Firebase AI Logic SDK uses to route a request. */
@OptIn(PublicPreviewAPI::class)
internal fun InferenceMode.toSdkMode(): SdkInferenceMode =
    when (this) {
        InferenceMode.PREFER_ON_DEVICE -> SdkInferenceMode.PREFER_ON_DEVICE
        InferenceMode.ONLY_ON_DEVICE -> SdkInferenceMode.ONLY_ON_DEVICE
        InferenceMode.PREFER_IN_CLOUD -> SdkInferenceMode.PREFER_IN_CLOUD
        InferenceMode.ONLY_IN_CLOUD -> SdkInferenceMode.ONLY_IN_CLOUD
    }

/**
 * Converts the source the SDK reports for a response into the value sent to Dart.
 *
 * A source that the SDK adds in the future maps to [InferenceSource.IN_CLOUD], because every request that is not
 * known to have run on the device was handled by a remote service.
 */
@OptIn(PublicPreviewAPI::class)
internal fun SdkInferenceSource.toSource(): InferenceSource =
    when (this) {
        SdkInferenceSource.ON_DEVICE -> InferenceSource.ON_DEVICE
        else -> InferenceSource.IN_CLOUD
    }
