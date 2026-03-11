package com.example.ignis_safe

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ignis_safe/unity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "openUnityScene" -> {
                    val sceneName = call.argument<String>("sceneName")

                    if (sceneName.isNullOrBlank()) {
                        result.error("NO_SCENE", "sceneName is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val intent = Intent().apply {
                            setClassName(
                                this@MainActivity,
                                "com.unity3d.player.UnityPlayerGameActivity"
                            )
                            putExtra("sceneName", sceneName)
                        }

                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "UNITY_LAUNCH_ERROR",
                            "Failed to launch Unity: ${e.message}",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}