package com.example.firebase_hybrid_ai

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FirebaseHybridAiPlugin */
class FirebaseHybridAiPlugin :
    FlutterPlugin,
    FirebaseHybridAiPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FirebaseHybridAiPluginApi.setUp(binding.binaryMessenger, null)
    }
}
