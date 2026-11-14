package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.type.PublicPreviewAPI
import kotlin.test.Test
import kotlin.test.assertEquals
import com.google.firebase.ai.InferenceMode as SdkInferenceMode
import com.google.firebase.ai.InferenceSource as SdkInferenceSource

/** Verifies that modes sent from Dart select the same SDK mode, and that SDK sources convert back to Dart's. */
@OptIn(PublicPreviewAPI::class)
internal class InferenceMappingTest {
    @Test
    fun everyMode_mapsToTheSdkModeOfTheSameName() {
        assertEquals(SdkInferenceMode.PREFER_ON_DEVICE, InferenceMode.PREFER_ON_DEVICE.toSdkMode())
        assertEquals(SdkInferenceMode.ONLY_ON_DEVICE, InferenceMode.ONLY_ON_DEVICE.toSdkMode())
        assertEquals(SdkInferenceMode.PREFER_IN_CLOUD, InferenceMode.PREFER_IN_CLOUD.toSdkMode())
        assertEquals(SdkInferenceMode.ONLY_IN_CLOUD, InferenceMode.ONLY_IN_CLOUD.toSdkMode())
    }

    @Test
    fun onDeviceSource_mapsToOnDevice() {
        assertEquals(InferenceSource.ON_DEVICE, SdkInferenceSource.ON_DEVICE.toSource())
    }

    @Test
    fun inCloudSource_mapsToInCloud() {
        assertEquals(InferenceSource.IN_CLOUD, SdkInferenceSource.IN_CLOUD.toSource())
    }
}
