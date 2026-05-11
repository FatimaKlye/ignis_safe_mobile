// ============================================================
//  SceneLoader.cs  –  COPY THIS FILE INTO YOUR UNITY PROJECT
//  Suggested path: Assets/Scripts/SceneLoader.cs
// ============================================================
//
//  HOW TO SET UP IN UNITY:
//  1. Create an EMPTY GameObject in your first/bootstrap Unity scene.
//  2. Name it EXACTLY "SceneLoader" (case-sensitive — must match the
//     first argument in UnityFlutterHostActivity._sendSceneNameToUnity()).
//  3. Attach this script to that GameObject.
//  4. The DontDestroyOnLoad call in Awake() keeps it alive across scene loads.
//  5. Build & export to Android as usual.
//
//  ANDROID SIDE:
//  UnityFlutterHostActivity calls:
//      UnityPlayer.UnitySendMessage("SceneLoader", "LoadScene", sceneName);
//  This routes to the LoadScene(string) method below.
// ============================================================

using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneLoader : MonoBehaviour
{
    private const string TAG = "[SceneLoader]";

    // Holds the scene name if it arrives before Awake/Start has run.
    private static string _pendingSceneName = null;
    // Prevents double-loading if both the Android message and the Start() fallback fire.
    private static bool _sceneLoadTriggered = false;

    private void Awake()
    {
        // Only one SceneLoader may exist across all scene loads.
        if (FindObjectsOfType<SceneLoader>().Length > 1)
        {
            Debug.Log(TAG + " Duplicate SceneLoader destroyed.");
            Destroy(gameObject);
            return;
        }
        DontDestroyOnLoad(gameObject);
        Debug.Log(TAG + " Awake — SceneLoader ready.");
    }

    private void Start()
    {
        // [FIX] Reset static state so each new Unity launch starts clean.
        _sceneLoadTriggered = false;

        // Fallback: if Android sent the scene name before C# was ready
        // (e.g., UnitySendMessage fired before the first frame), it was
        // stored in _pendingSceneName. Process it now.
        if (_pendingSceneName != null)
        {
            Debug.Log(TAG + " Start() — processing pending scene from static cache: " + _pendingSceneName);
            string s = _pendingSceneName;
            _pendingSceneName = null;
            LoadScene(s);
            return;
        }

        // Second fallback: read the scene name directly from the Android Intent.
        // This covers the case where the process was killed and restarted fresh,
        // so UnitySendMessage was never called (Unity just started from scratch).
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            using (var activity  = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
            using (var intent    = activity.Call<AndroidJavaObject>("getIntent"))
            {
                string sceneName = intent.Call<string>("getStringExtra", "sceneName");
                Debug.Log(TAG + " Start() — Android Intent scene name: " + sceneName);
                if (!string.IsNullOrEmpty(sceneName))
                {
                    LoadScene(sceneName);
                }
                else
                {
                    Debug.LogWarning(TAG + " Start() — Intent had no sceneName extra. Check MainActivity.kt.");
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError(TAG + " Start() — Failed to read Android Intent: " + e.Message);
        }
#endif
    }

    // -------------------------------------------------------
    //  Called by Android via:
    //    UnityPlayer.UnitySendMessage("SceneLoader", "LoadScene", sceneName);
    // -------------------------------------------------------
    public void LoadScene(string sceneName)
    {
        Debug.Log(TAG + " LoadScene called — Unity received scene: " + sceneName);

        if (string.IsNullOrEmpty(sceneName))
        {
            Debug.LogWarning(TAG + " LoadScene — sceneName is null or empty. Ignoring.");
            return;
        }

        if (_sceneLoadTriggered)
        {
            Debug.Log(TAG + " LoadScene — scene load already triggered for: " + sceneName + ". Ignoring duplicate.");
            return;
        }

        // [FIX] Reset any scene-specific static state here before loading.
        // Add calls to your scene-specific managers if they have static Reset() methods:
        // e.g.:  ExtinguisherGameManager.ResetState();
        //        HouseFireGameManager.ResetState();
        //        SceneSpecificStaticVar = defaultValue;

        _sceneLoadTriggered = true;
        Debug.Log(TAG + " Unity loaded scene: " + sceneName);
        SceneManager.LoadScene(sceneName, LoadSceneMode.Single);
    }

    // -------------------------------------------------------
    //  Called if the message arrives BEFORE the SceneLoader
    //  MonoBehaviour has run its Awake/Start (edge case).
    //  This is invoked statically so it does not require a
    //  live instance.
    // -------------------------------------------------------
    public static void SetPendingScene(string sceneName)
    {
        Debug.Log(TAG + " SetPendingScene (static) — caching scene for Start(): " + sceneName);
        _pendingSceneName = sceneName;
        _sceneLoadTriggered = false;
    }
}
