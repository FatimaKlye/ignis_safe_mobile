using UnityEngine;

public class ReturnToFlutter1 : MonoBehaviour
{
    // FIX: Make isReturning a public static property so other scripts (e.g. MovementController)
    //      can check it and stop work while the activity is being finished
    // WHY: Private instance field was inaccessible cross-script; static allows any MonoBehaviour
    //      to read it without a direct reference, stopping unnecessary per-frame work during shutdown
    public static bool IsReturning { get; private set; } = false;

    // FIX: Keep the instance field for backward-compatible internal checks
    // WHY: Some paths (catch blocks) still set this; route them through the static property
    private bool _isReturning
    {
        get => IsReturning;
        set => IsReturning = value;
    }

    private void Awake()
    {
        // FIX: Reset static IsReturning flag at the start of every new Unity session
        // WHY: IsReturning is a static property — it persists for the lifetime of the
        //      :unity process. If System.exit(0) is not called immediately after finish(),
        //      the process survives and IsReturning remains true from the previous run.
        //      The next simulation launch creates a new activity (onCreate) but reuses the
        //      same process. Any call to BackToFlutterApp() hits "if (_isReturning) return"
        //      and never calls finish() → onActivityResult never fires → Flutter hangs.
        //      Resetting in Awake() guarantees a clean state for every new scene load,
        //      without risk of interfering with an in-progress finish() call (Awake fires
        //      at scene start, long before any completion trigger can run).
        IsReturning = false;
    }

    public void BackToFlutterApp()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        // FIX: Guard with the static flag to prevent multiple concurrent calls
        // WHY: Multiple scripts (countdown, trigger) may call BackToFlutterApp() simultaneously
        if (_isReturning) return;
        _isReturning = true;
        IgnisFlutterActivityBridge.MarkSimulationCompleted();

        try
        {
            // FIX: Scope unityPlayer in a 'using' block; declare activity outside so it stays alive
            //      for the runOnUiThread lambda
            // WHY: unityPlayer is only needed to read currentActivity — safe to dispose immediately.
            //      activity must NOT be inside a 'using' block: the using disposes it at block exit,
            //      BEFORE the runOnUiThread lambda executes on the Android UI thread. A disposed
            //      AndroidJavaObject has an invalid JNI handle; activity.Call("finish") would silently
            //      fail, the Unity activity would never close, onActivityResult would never fire,
            //      and Flutter's await UnityLauncher.openScene() would hang forever → freeze / ANR.
            AndroidJavaObject activity;
            using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
            }
            // unityPlayer disposed here; activity JNI reference is still valid

            if (activity == null)
            {
                Debug.LogError("ReturnToFlutter1: currentActivity is null.");
                _isReturning = false;
                return;
            }

            Debug.Log("ReturnToFlutter1: calling finish() on Unity activity.");

            activity.Call("runOnUiThread", new AndroidJavaRunnable(() =>
            {
                try
                {
                    activity.Call("finish");
                }
                catch (System.Exception e)
                {
                    Debug.LogError("ReturnToFlutter1 finish() failed: " + e.Message);
                    _isReturning = false;
                }
                finally
                {
                    // FIX: Dispose activity JNI reference before killing the process
                    // WHY: Releases the JNI global reference cleanly before System.exit(0)
                    //      terminates the process. The OS would clean it up anyway on exit,
                    //      but explicit disposal is correct practice.
                    activity.Dispose();

                    // FIX: Explicitly call System.exit(0) to kill the :unity process
                    // WHY: Unity's UnityPlayerGameActivity.onDestroy() is supposed to call
                    //      System.exit(0) internally, but it does not do so reliably on all
                    //      devices and Unity versions. If the :unity process survives after
                    //      finish(), the next startActivityForResult() creates a NEW
                    //      UnityPlayerGameActivity inside the SAME living process. Unity's
                    //      native renderer (libunity.so) cannot reinitialize or rebind to the
                    //      new activity's SurfaceView — it renders to the old, destroyed surface.
                    //      Result: permanent black screen on every simulation after the first one.
                    //      Calling System.exit(0) here guarantees the :unity process is killed
                    //      immediately after finish() completes. Because android:process=":unity"
                    //      isolates Unity in its own OS process, this call ONLY kills :unity —
                    //      the Flutter process (com.example.ignis_safe, PID 19260) is completely
                    //      unaffected. onActivityResult still fires in MainActivity via Binder IPC
                    //      because the Android system server handles result delivery independently
                    //      of the dying :unity process.
                    //      This is NOT Application.Quit() — Application.Quit() routes through
                    //      Unity's managed layer and may be suppressed. This calls the Java
                    //      System.exit() directly, which the OS always honors.
                    try
                    {
                        using (var system = new AndroidJavaClass("java.lang.System"))
                            system.CallStatic("exit", 0);
                    }
                    catch (System.Exception ex)
                    {
                        Debug.LogError("ReturnToFlutter1: System.exit(0) failed: " + ex.Message);
                    }
                }
            }));
        }
        catch (System.Exception e)
        {
            Debug.LogError("ReturnToFlutter1 failed: " + e.Message);
            _isReturning = false;
        }
#else
        Debug.Log("ReturnToFlutter1: BackToFlutterApp called. This only returns to Flutter on Android build.");
#endif
    }

    // FIX: Add reset method for editor/multi-scene testing
    // WHY: The static flag persists across scenes in the editor; reset it to allow re-testing
    public static void ResetReturningState()
    {
        IsReturning = false;
        Debug.Log("[ReturnToFlutter1] IsReturning reset (editor/testing only).");
    }
}
