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

    /// <summary>
    /// Call this when the scene is complete and the user should return to Flutter.
    /// On Android this calls Activity.finish() which triggers the :unity process
    /// to be killed (see UnityFlutterHostActivity.onDestroy).
    /// In the Unity Editor it just logs so you can test without an Android device.
    /// </summary>
    public static void Return()
    {
        Debug.Log(TAG + " Unity returned to Flutter — calling Activity.finish().");

#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            using (var activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
            {
                // finish() triggers onUnityPlayerUnloaded / onUnityPlayerQuitted in
                // UnityFlutterHostActivity, which calls finish() → onDestroy() → killProcess().
                activity.Call("finish");
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError(TAG + " Failed to call Activity.finish(): " + e.Message);
        }
#else
        Debug.Log(TAG + " [Editor] Return() called — would call Activity.finish() on device.");
#endif
    }
}
