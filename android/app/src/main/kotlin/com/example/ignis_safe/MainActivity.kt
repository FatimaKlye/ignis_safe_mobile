package com.example.ignis_safe

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ignis_safe/unity"
    private val UNITY_REQUEST_CODE = 1001
    private val TAG = "MainActivity"

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSceneName: String? = null
    private var waitingForUnityReturn = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUnityScene" -> {
                        try {
                            val sceneName = call.argument<String>("sceneName")
                            Log.d(TAG, "[Flutter->Unity] Flutter requested scene: $sceneName")

                            val unityActivityClass = Class.forName("com.unity3d.player.UnityFlutterHostActivity")
                            val intent = Intent(this, unityActivityClass)
                            intent.putExtra("sceneName", sceneName)
                            // [FIX] FLAG_ACTIVITY_SINGLE_TOP mirrors the manifest launchMode="singleTop".
                            // If UnityFlutterHostActivity is already at the top of the stack (e.g.,
                            // process survived from a previous session), this triggers onNewIntent()
                            // instead of creating a new conflicting instance in the same :unity process.
                            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)

                            pendingResult = result
                            pendingSceneName = sceneName
                            waitingForUnityReturn = true

                            Log.d(TAG, "[Flutter->Unity] Starting UnityFlutterHostActivity for scene: $sceneName")
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, UNITY_REQUEST_CODE)
                        } catch (e: Exception) {
                            Log.e(TAG, "[Flutter->Unity] Failed to open Unity: ${e.message}", e)
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
        Log.d(TAG, "[Unity->Flutter] onActivityResult requestCode=$requestCode resultCode=$resultCode scene=$pendingSceneName waitingForUnity=$waitingForUnityReturn")

        if (requestCode == UNITY_REQUEST_CODE) {
            Log.d(TAG, "[Unity->Flutter] Unity Activity returned — completing pending result")
            completePendingUnityResult()
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "[Flutter] onResume waitingForUnityReturn=$waitingForUnityReturn pendingResult=${pendingResult != null}")
        if (waitingForUnityReturn && pendingResult != null) {
            // Fallback: onActivityResult may be skipped if the Unity process was killed.
            // onResume always fires when Flutter comes back to foreground, so this catches it.
            Log.d(TAG, "[Flutter] Completing Unity result via onResume fallback for scene: $pendingSceneName")
            Handler(Looper.getMainLooper()).post { completePendingUnityResult() }
        }
    }

    private fun completePendingUnityResult() {
        val pr = pendingResult ?: return
        val sceneName = pendingSceneName
        pendingResult = null
        pendingSceneName = null
        waitingForUnityReturn = false

        Log.d(TAG, "[Flutter] Sending completed=true back to Flutter for scene: $sceneName")
        pr.success(
            mapOf(
                "completed" to true,
                "sceneName" to sceneName
            )
        )
    }
}


