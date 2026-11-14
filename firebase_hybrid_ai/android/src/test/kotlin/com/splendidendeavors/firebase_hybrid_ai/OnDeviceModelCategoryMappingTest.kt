package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.OnDeviceModelOption
import com.google.firebase.ai.type.PublicPreviewAPI
import kotlin.test.Test
import kotlin.test.assertEquals

/** Verifies that each category maps to the model option of the same release stage and the channel Dart opens. */
@OptIn(PublicPreviewAPI::class)
internal class OnDeviceModelCategoryMappingTest {
    @Test
    fun stable_mapsToStableOption() {
        assertEquals(OnDeviceModelOption.STABLE, OnDeviceModelCategory.STABLE.toModelOption())
    }

    @Test
    fun preview_mapsToPreviewOption() {
        assertEquals(OnDeviceModelOption.PREVIEW, OnDeviceModelCategory.PREVIEW.toModelOption())
    }

    @Test
    fun previewFast_mapsToPreviewFastOption() {
        assertEquals(OnDeviceModelOption.PREVIEW_FAST, OnDeviceModelCategory.PREVIEW_FAST.toModelOption())
    }

    /** Dart builds the channel name from the enum constant's name, so these strings are part of the contract. */
    @Test
    fun channelInstanceNames_matchTheDartEnumNames() {
        assertEquals(
            listOf("stable", "preview", "previewFast"),
            OnDeviceModelCategory.values().map { it.channelInstanceName },
        )
    }
}
