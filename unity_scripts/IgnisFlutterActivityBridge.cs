using UnityEngine;

public static class IgnisFlutterActivityBridge
{
    public static void MarkSimulationCompleted()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        CallActivity("markIgnisSimulationCompleted");
#endif
    }

    public static void NotifySceneReady()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        CallActivity("notifyIgnisSceneReady");
#endif
    }

    private static void CallActivity(string methodName)
    {
        try
        {
            using (var unityPlayer =
                   new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            using (var activity =
                   unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
            {
                activity.Call(methodName);
            }
        }
        catch (System.Exception error)
        {
            Debug.LogError(
                "[IgnisFlutterActivityBridge] " + methodName +
                " failed: " + error.Message
            );
        }
    }
}
