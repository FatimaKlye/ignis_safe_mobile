// ============================================================
//  ReturnToFlutter.cs  –  COPY THIS FILE INTO YOUR UNITY PROJECT
//  Suggested path: Assets/Scripts/ReturnToFlutter.cs
// ============================================================
//
//  USAGE:
//  Call  ReturnToFlutter.Return();  from any C# script when the
//  player completes a scene (e.g., from MissionCompleteAutoReturn.cs).
//
//  This calls finish() on the Android Activity so the :unity process
//  is properly destroyed and Flutter receives the onActivityResult()
//  callback in MainActivity.kt.
//
//  DO NOT use Application.Quit() — it works on some devices but on
//  others it leaves the :unity process alive, which causes the
//  black screen on the next scene launch.
//
//  DO NOT use UnityPlayer.MoveTaskToBack(true) — same problem; the
//  activity stays alive and Unity retains state from the old scene.
// ============================================================

using UnityEngine;

public static class ReturnToFlutter
{
    private const string TAG = "[ReturnToFlutter]";
    
    // FIX: Add static flag to prevent multiple return calls
    // WHY: Multiple scripts (countdown, trigger, mission complete) could call Return() simultaneously,
    //      causing multiple finish() calls and ANR/freeze
    private static bool _isReturning = false;

    /// <summary>
    /// Call this when the scene is complete and the user should return to Flutter.
    /// On Android this calls Activity.finish() which triggers the :unity process
    /// to be killed (see UnityFlutterHostActivity.onDestroy).
    /// In the Unity Editor it just logs so you can test without an Android device.
    /// </summary>
    public static void Return()
    {
        // FIX: Check if we're already returning to prevent multiple calls
        // WHY: Prevents race condition where multiple scene completion triggers call finish() simultaneously
        if (_isReturning)
        {
            Debug.LogWarning(TAG + " Return() already called. Ignoring duplicate call.");
            return;
        }
        
        // FIX: Set flag immediately to prevent concurrent calls
        // WHY: Even if the Activity.finish() below is delayed, the flag prevents another Return() call
        _isReturning = true;
        
        Debug.Log(TAG + " Unity returning to Flutter — calling Activity.finish().");

#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            // FIX: Do NOT wrap 'activity' in a nested 'using' block
            // WHY: The nested 'using' calls activity.Dispose() when the block exits, BEFORE the
            //      runOnUiThread lambda runs on the Android UI thread. A disposed AndroidJavaObject
            //      has an invalid JNI handle — activity.Call("finish") becomes a silent no-op,
            //      the Unity activity never closes, onActivityResult is never fired, and Flutter's
            //      await UnityLauncher.openScene() hangs forever → freeze / ANR.
            // using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            // using (var activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
            // {
            //     activity.Call("runOnUiThread", new AndroidJavaRunnable(() =>
            //     {
            //         Debug.Log(TAG + " Calling Activity.finish() from UI thread.");
            //         activity.Call("finish");  // BUG: activity already disposed here
            //     }));
            // }

            // FIX: Only put unityPlayer in 'using'; keep activity alive until after finish() runs
            // WHY: unityPlayer is only needed to read currentActivity and can be disposed immediately.
            //      activity must remain valid until the runOnUiThread lambda completes on the UI thread.
            AndroidJavaObject activity;
            using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
            }

            // FIX: Run finish() on the Android UI thread to prevent ANR
            // WHY: Activity methods must be called from the UI thread; calling from a Unity thread
            //      causes an Android "Only the original thread that created a view hierarchy can touch its views" crash
            activity.Call("runOnUiThread", new AndroidJavaRunnable(() =>
            {
                Debug.Log(TAG + " Calling Activity.finish() from UI thread.");
                activity.Call("finish");
                // FIX: Dispose activity inside the lambda, after finish() completes
                // WHY: JNI reference must remain valid until finish() returns; disposing here
                //      prevents a JNI handle leak while still allowing finish() to execute cleanly
                activity.Dispose();
            }));
        }
        catch (System.Exception e)
        {
            Debug.LogError(TAG + " Failed to call Activity.finish(): " + e.Message);
            // FIX: Reset flag if finish() failed so retry is possible
            // WHY: If finish() throws, allow another attempt
            _isReturning = false;
        }
#else
        Debug.Log(TAG + " [Editor] Return() called — would call Activity.finish() on device.");
#endif
    }
    
    // FIX: Reset _isReturning so a fresh Unity session can always call Return().
    // WHY: Called by SceneLoader.Start() as a safety net. Primary fix is MainActivity
    //      killing the :unity process (new process resets all statics automatically).
    //      This handles the edge case where the process kill is delayed or fails:
    //      _isReturning=true from a previous scene would silently block Return() on the
    //      new scene → finish() never called → onActivityResult never fires → Flutter hangs.
    public static void ResetReturningState()
    {
        _isReturning = false;
        Debug.Log(TAG + " ResetReturningState() called — _isReturning cleared.");
    }
}
