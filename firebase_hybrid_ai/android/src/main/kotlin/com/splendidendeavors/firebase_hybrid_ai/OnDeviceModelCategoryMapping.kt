package com.splendidendeavors.firebase_hybrid_ai

import com.google.firebase.ai.OnDeviceModelOption
import com.google.firebase.ai.type.PublicPreviewAPI

/**
 * Converts the category chosen in Dart into the model option the Firebase AI Logic SDK uses to ask AICore for a
 * model. AICore then picks the model that fits the category and the device. For example, [OnDeviceModelCategory.PREVIEW]
 * selects the latest preview model with full performance, such as Gemini Nano 4 Full.
 */
@OptIn(PublicPreviewAPI::class)
internal fun OnDeviceModelCategory.toModelOption(): OnDeviceModelOption =
    when (this) {
        OnDeviceModelCategory.STABLE -> OnDeviceModelOption.STABLE
        OnDeviceModelCategory.PREVIEW -> OnDeviceModelOption.PREVIEW
        OnDeviceModelCategory.PREVIEW_FAST -> OnDeviceModelOption.PREVIEW_FAST
    }

/**
 * The name of the event channel that streams download progress for this category.
 *
 * Pigeon event channels cannot take parameters, so the category is encoded in the channel's instance name. These
 * values must match the `name` of the Dart enum constants, because Dart builds the channel name from them.
 */
internal val OnDeviceModelCategory.channelInstanceName: String
    get() = when (this) {
        OnDeviceModelCategory.STABLE -> "stable"
        OnDeviceModelCategory.PREVIEW -> "preview"
        OnDeviceModelCategory.PREVIEW_FAST -> "previewFast"
    }
