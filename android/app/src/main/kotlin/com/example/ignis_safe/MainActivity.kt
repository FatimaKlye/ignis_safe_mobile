package com.example.ignis_safe

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "ignis_safe/unity"
    private val unityRequestCode = 1001
    private val tag = "MainActivity"

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSceneName: String? = null
    private var waitingForUnityReturn = false
    private var unityChannelReplyDelivered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUnityScene" -> {
                        try {
                            val sceneName = call.argument<String>("sceneName")
                            Log.d(tag, "Opening Unity scene: $sceneName")

                            val intent = Intent().apply {
                                setClassName(
                                    this@MainActivity,
                                    "com.unity3d.player.UnityPlayerGameActivity"
                                )
                                putExtra("sceneName", sceneName)
                                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            }

                            pendingResult = result
                            pendingSceneName = sceneName
                            waitingForUnityReturn = true
                            unityChannelReplyDelivered = false

                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, unityRequestCode)
                        } catch (e: Exception) {
                            clearUnityPendingState()
                            Log.e(tag, "Failed to open Unity", e)
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
        if (requestCode == unityRequestCode) {
            completePendingResult()
        }
    }

    override fun onResume() {
        super.onResume()
        if (waitingForUnityReturn && pendingResult != null) {
            Handler(Looper.getMainLooper()).post {
                completePendingResult()
            }
        }
    }

    private fun clearUnityPendingState() {
        pendingResult = null
        pendingSceneName = null
        waitingForUnityReturn = false
        unityChannelReplyDelivered = false
    }

    private fun completePendingResult() {
        synchronized(this) {
            if (unityChannelReplyDelivered) return
            val result = pendingResult ?: return

            unityChannelReplyDelivered = true
            pendingResult = null
            val scene = pendingSceneName
            pendingSceneName = null
            waitingForUnityReturn = false

            try {
                result.success(
                    mapOf(
                        "completed" to true,
                        "sceneName" to scene
                    )
                )
            } catch (e: IllegalStateException) {
                Log.w(tag, "Unity channel reply already completed", e)
            }
        }
    }
}