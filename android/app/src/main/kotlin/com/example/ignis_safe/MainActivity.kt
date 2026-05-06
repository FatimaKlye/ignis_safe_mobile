package com.example.ignis_safe

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ignis_safe/unity"
    private val UNITY_REQUEST_CODE = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSceneName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUnityScene" -> {
                        try {
                            val sceneName = call.argument<String>("sceneName")

                            val unityActivityClass =
                                Class.forName("com.unity3d.player.UnityPlayerActivity")

                            val intent = Intent(this, unityActivityClass)
                            intent.putExtra("sceneName", sceneName)

                            pendingResult = result
                            pendingSceneName = sceneName

                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, UNITY_REQUEST_CODE)
                        } catch (e: Exception) {
                            result.error(
                                "UNITY_OPEN_FAILED",
                                "Cannot open Unity: ${e.message}",
                                null
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == UNITY_REQUEST_CODE) {
            val pr = pendingResult ?: return
            val sceneName = pendingSceneName
            pendingResult = null
            pendingSceneName = null

            pr.success(
                mapOf(
                    "completed" to true,
                    "sceneName" to sceneName
                )
            )
        }
    }
}
