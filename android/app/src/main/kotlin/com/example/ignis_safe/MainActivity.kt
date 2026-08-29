package com.example.ignis_safe

import android.app.ActivityManager
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
    // FIX: Track if we are still waiting for Unity to return
    // WHY: Prevent multiple onActivityResult or onResume from triggering duplicate result callbacks
    private var waitingForUnityReturn = false
    // FIX: Add flag to track if the result has been delivered to avoid double-delivery
    // WHY: onActivityResult and onResume can race; this ensures only one delivery
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
                            // FIX: Log the current process PID so logcat can confirm this call
                            //      runs in the main process (com.example.ignis_safe), not :unity.
                            // WHY: Diagnosing whether process isolation is actually in effect.
                            Log.d(tag, "Launching Unity: scene=$sceneName pid=${android.os.Process.myPid()}")

                            val intent = Intent().apply {
                                setClassName(
                                    this@MainActivity,
                                    "com.example.ignis_safe.IgnisUnityPlayerActivity"
                                )
                                putExtra("sceneName", sceneName)
                                // FIX: Add a unique launchToken on every startActivityForResult call
                                // WHY: FlutterBridge.cs uses this token to detect a new launch even
                                //      when the :unity process stays alive between simulations.
                                //      Without a token, if the process survives, FlutterBridge cannot
                                //      distinguish "OnApplicationFocus fired during the same session"
                                //      from "OnApplicationFocus fired because a new scene was requested."
                                //      The token is a timestamp string — unique per tap, zero overhead.
                                putExtra("launchToken", System.currentTimeMillis().toString())
                                // FIX: Removed FLAG_ACTIVITY_SINGLE_TOP from the intent
                                // WHY: FLAG_ACTIVITY_SINGLE_TOP (combined with android:launchMode="singleTop"
                                //      that was previously set) caused Android to call onNewIntent() instead
                                //      of onCreate() when the Unity activity was still alive in the back stack
                                //      (e.g., :unity process survived because System.exit(0) was delayed).
                                //      With onNewIntent(), FlutterBridge.Start() is never re-executed,
                                //      the scene never loads, no completion script ever calls finish(),
                                //      onActivityResult never fires, and Flutter's invokeMethod awaits
                                //      forever → _isUnityLaunching stays true → all simulations blocked.
                                //      Manifest is now android:launchMode="standard" which always creates
                                //      a fresh activity. The FLAG is no longer needed and is removed.
                                //
                                // OLD CODE (removed):
                                // addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
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
        // FIX: Only process if this is our Unity request
        // WHY: Avoid processing unrelated activity results
        if (requestCode == unityRequestCode) {
            val completed =
                resultCode == RESULT_OK &&
                    data?.getBooleanExtra("completed", false) == true
            Log.d(
                tag,
                "onActivityResult called for Unity scene: completed=$completed"
            )
            completePendingResult(completed)
            // FIX: Kill the :unity process immediately after the result is delivered.
            // WHY: Activity.finish() closes UnityPlayerGameActivity but leaves the :unity
            //      process alive. Android keeps empty processes for performance (process reuse).
            //      On the next startActivityForResult call, Android finds the :unity process
            //      still alive and creates the new UnityPlayerGameActivity instance in that
            //      SAME process. However, Unity's native library (libunity.so) was already
            //      loaded and torn down by the first session's onDestroy(). The Unity native
            //      player cannot be re-initialized in the same process → black screen,
            //      no scene loads, no ReturnToFlutter fires, session is stuck.
            //      Killing the process HERE (AFTER completePendingResult has already delivered
            //      the result to Flutter) ensures the next startActivityForResult always gets
            //      a fresh :unity process with a clean native Unity state.
            killUnityProcess()
        }
    }

    override fun onResume() {
        super.onResume()
        // FIX: Check if we're waiting for Unity and if pendingResult hasn't been delivered yet
        // WHY: onResume can be called multiple times; only trigger once when returning from Unity
        if (waitingForUnityReturn && pendingResult != null && !unityChannelReplyDelivered) {
            Log.d(tag, "onResume detected return from Unity")
            Handler(Looper.getMainLooper()).postDelayed({
                if (!waitingForUnityReturn || unityChannelReplyDelivered) {
                    return@postDelayed
                }

                Log.w(
                    tag,
                    "Unity returned without an activity result; treating it as cancelled"
                )
                completePendingResult(completed = false)
                // FIX: Also kill :unity process in the onResume fallback path.
                // WHY: onActivityResult may not fire if the :unity process was killed externally
                //      (e.g., OOM killer) before Android could send the result. In that case
                //      onResume is the delivery path. We still need to ensure the :unity process
                //      is dead for the next launch. killUnityProcess() is idempotent — if the
                //      process is already dead it logs a message and returns harmlessly.
                killUnityProcess()
            }, 500L)
        }
    }

    private fun clearUnityPendingState() {
        pendingResult = null
        pendingSceneName = null
        waitingForUnityReturn = false
        unityChannelReplyDelivered = false
    }

    // FIX: Kill the :unity process after each simulation to ensure a fresh process for next launch.
    // WHY: Root cause of the black screen on 2nd+ launch: Unity's native library (libunity.so)
    //      cannot be re-initialized in a process that already loaded and tore it down.
    //      finish() alone does not kill the process — Android keeps it alive for performance.
    //      This method is called AFTER completePendingResult() so the Flutter result is always
    //      delivered before the process dies. It is idempotent: if the process is already dead
    //      (OOM killer, previous call) it logs a message and returns without error.
    //      ActivityManager.getRunningAppProcesses() on Android 11+ returns only the calling
    //      app's own processes, so the :unity process (com.example.ignis_safe:unity) is visible.
    private fun killUnityProcess() {
        try {
            val unityProcessName = "${packageName}:unity"
            val am = getSystemService(ActivityManager::class.java)
            val processes = am?.runningAppProcesses
            if (processes == null) {
                Log.d(tag, "killUnityProcess: getRunningAppProcesses returned null")
                return
            }
            for (info in processes) {
                if (info.processName == unityProcessName) {
                    Log.d(tag, "killUnityProcess: killing pid=${info.pid} name=${info.processName}")
                    android.os.Process.killProcess(info.pid)
                    return
                }
            }
            Log.d(tag, "killUnityProcess: :unity process not found (already dead)")
        } catch (e: Exception) {
            Log.w(tag, "killUnityProcess: failed — ${e.message}")
        }
    }

    // FIX: Add synchronized block to prevent race conditions between onActivityResult and onResume
    // WHY: Multiple threads/lifecycle callbacks could call this simultaneously, causing ANR
    private fun completePendingResult(completed: Boolean) {
        synchronized(this) {
            // FIX: Early exit if result already delivered to prevent double-delivery
            // WHY: onActivityResult and onResume can race; prevent sending result twice
            if (unityChannelReplyDelivered) {
                Log.d(tag, "Result already delivered, skipping duplicate completion")
                return
            }
            
            val result = pendingResult ?: return

            unityChannelReplyDelivered = true
            pendingResult = null
            val scene = pendingSceneName
            pendingSceneName = null
            waitingForUnityReturn = false

            try {
                Log.d(
                    tag,
                    "Delivering Unity result for scene: $scene completed=$completed"
                )
                result.success(
                    mapOf(
                        "completed" to completed,
                        "sceneName" to scene
                    )
                )
            } catch (e: IllegalStateException) {
                Log.w(tag, "Unity channel reply already completed", e)
            }
        }
    }
}
