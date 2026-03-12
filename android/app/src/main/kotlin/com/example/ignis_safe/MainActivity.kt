package com.example.ignis_safe

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ignis_safe/unity"
    private val UNITY_REQUEST_CODE = 1001

    private var pendingUnityResult: MethodChannel.Result? = null
    private var pendingUnitySceneName: String? = null

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

                    if (pendingUnityResult != null) {
                        result.error("UNITY_BUSY", "A Unity scene is already running.", null)
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

                        pendingUnityResult = result
                        pendingUnitySceneName = sceneName

                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, UNITY_REQUEST_CODE)

                    } catch (e: Exception) {
                        pendingUnityResult = null
                        pendingUnitySceneName = null

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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == UNITY_REQUEST_CODE) {
            pendingUnityResult?.success(
                mapOf(
                    "completed" to true,
                    "sceneName" to pendingUnitySceneName
                )
            )

            pendingUnityResult = null
            pendingUnitySceneName = null
        }
    }
}