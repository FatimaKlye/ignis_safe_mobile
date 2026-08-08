// FlutterBridge.cs
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Android;
using System.Collections;

public class FlutterBridge : MonoBehaviour
{
    [SerializeField] private string fallbackScene = "FireExtinguisher_PASS";

    // FIX: Replace _sceneLoadTriggered bool with _lastLaunchToken string
    // WHY: _sceneLoadTriggered was a simple boolean set to true after the first scene load.
    //      When the :unity process survived between simulations (System.exit(0) delayed or
    //      not called), the DontDestroyOnLoad FlutterBridge from the previous run was still
    //      alive with _sceneLoadTriggered = true. Every subsequent OnApplicationFocus(true)
    //      saw the flag and returned early — the new scene was never loaded, no completion
    //      script ever called finish(), onActivityResult never fired, Flutter's invokeMethod
    //      awaited forever, and _isUnityLaunching stayed true permanently → ALL simulations
    //      blocked until the app was restarted.
    //      _lastLaunchToken stores the "launchToken" string that MainActivity.kt embeds in
    //      the intent for every startActivityForResult call (a unique timestamp per tap).
    //      TryLoadSceneFromIntent() compares the current intent's token to _lastLaunchToken:
    //        - Same token  → already handled this launch → skip (prevents double-load)
    //        - Different token → new launch → load the new scene immediately
    //      This works whether the process dies (new instance, _lastLaunchToken = null) or
    //      survives (same instance, token changes → loads again).
    private string _lastLaunchToken = null;

    private void Awake()
    {
        // FIX: Singleton guard — destroy stale DontDestroyOnLoad instances from previous launch
        // WHY: DontDestroyOnLoad keeps FlutterBridge alive across scene loads within the same
        //      Unity process. If :unity process survives between launches (System.exit(0) not
        //      called), a new FlutterBridge is created by the bootstrap scene on the next
        //      onCreate(). Without this guard, two FlutterBridge objects coexist: the old one
        //      (with stale _lastLaunchToken) and the new one. The old one's OnApplicationFocus
        //      could fire and try to load a stale scene. This guard destroys any pre-existing
        //      FlutterBridge before moving self to the DontDestroyOnLoad scene.
        FlutterBridge[] existing = FindObjectsOfType<FlutterBridge>();
        foreach (FlutterBridge fb in existing)
        {
            if (fb != this)
            {
                Debug.Log("[FlutterBridge] Destroying stale instance from previous Unity session.");
                Destroy(fb.gameObject);
            }
        }
        DontDestroyOnLoad(gameObject);
    }

    private void Start()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        TryLoadSceneFromIntent();
#else
        // FIX: In editor, skip intent reading and load fallback scene directly
        // WHY: AndroidApplication.currentActivity is not available in the editor;
        //      calling it would throw an exception. Fall back to the configured scene.
        OpenScene(fallbackScene);
#endif
    }

    // FIX: Add OnApplicationFocus as a fallback for the case where:
    //      (a) Start() runs before the Intent is fully committed on some Android versions, or
    //      (b) the :unity process survives and onNewIntent() is called (no new Start()),
    //          meaning the ONLY signal that a new scene was requested is OnApplicationFocus
    //          firing after the activity regains focus with the new intent.
    // WHY: OnApplicationFocus(true) fires every time the Unity app comes to the foreground.
    //      TryLoadSceneFromIntent() uses _lastLaunchToken to ensure it is a no-op when
    //      called for the same launch multiple times (e.g., Start() already handled it).
    private void OnApplicationFocus(bool hasFocus)
    {
        if (!hasFocus) return;
#if UNITY_ANDROID && !UNITY_EDITOR
        TryLoadSceneFromIntent();
#endif
    }

    private void TryLoadSceneFromIntent()
    {
        string sceneName;
        string launchToken;
        GetIntentData(out sceneName, out launchToken);

        // FIX: Only load the scene when the launchToken is new (different from last processed)
        // WHY: Both Start() and OnApplicationFocus(true) call this method. Without deduplication,
        //      the scene would be loaded twice: once from Start() and once from OnApplicationFocus.
        //      Using launchToken (a unique timestamp set by MainActivity per startActivityForResult
        //      call) lets us detect "already handled this launch" vs "new launch from Flutter."
        //      If launchToken is null (old Unity build without token support or editor), always load.
        if (launchToken != null && launchToken == _lastLaunchToken)
        {
            Debug.Log("[FlutterBridge] Same launchToken — scene already loaded for this launch.");
            return;
        }

        if (launchToken != null)
            _lastLaunchToken = launchToken;

        if (!string.IsNullOrWhiteSpace(sceneName))
        {
            Debug.Log("[FlutterBridge] Loading scene from intent: " + sceneName);
            OpenScene(sceneName);
        }
        else
        {
            Debug.Log("[FlutterBridge] No sceneName in intent — loading fallback: " + fallbackScene);
            OpenScene(fallbackScene);
        }
    }

    public void OpenScene(string sceneName)
    {
        if (string.IsNullOrWhiteSpace(sceneName))
            return;

        // FIX: Removed the early-return that skipped loading when activeScene.name == sceneName
        // WHY: This guard was introduced to prevent double-loading but it masked a deeper bug:
        //      with the old singleTask launchMode, getIntent() returned a stale intent after
        //      process death, and the stale scene name matched the active scene → scene never
        //      reloaded → black screen. The launchToken mechanism now handles deduplication
        //      correctly, so the same-name guard is no longer needed and is kept removed.
        //
        // OLD CODE (removed, kept here for reference):
        // if (SceneManager.GetActiveScene().name == sceneName)
        //     return;

        StartCoroutine(LoadSceneRoutine(sceneName));
    }

    private IEnumerator LoadSceneRoutine(string sceneName)
    {
        AsyncOperation op = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Single);
        while (!op.isDone)
        {
            yield return null;
        }

        // The bootstrap scene and the previously opened simulation can leave
        // textures, meshes, and other assets resident even after a Single-mode
        // scene load. Release anything the newly loaded scene no longer uses
        // before removing Flutter's loading screen.
        yield return null;
        AsyncOperation cleanup = Resources.UnloadUnusedAssets();
        while (!cleanup.isDone)
        {
            yield return null;
        }
        System.GC.Collect();

        Debug.Log("[FlutterBridge] Scene loaded: " + sceneName);
        IgnisFlutterActivityBridge.NotifySceneReady();
    }

    // FIX: Combined intent reader — reads both sceneName and launchToken in a single JNI call
    // WHY: The original GetSceneFromIntent() opened and disposed the intent object once.
    //      Reading two extras from the same intent requires the object to stay alive for both
    //      calls. This method reads both fields inside a single 'using' block, ensuring the
    //      JNI reference is disposed exactly once after both strings are retrieved.
    //      Using 'out' parameters avoids allocating a Tuple or ValueTuple (not available in
    //      all Unity C# runtimes) and keeps the code readable.
    private void GetIntentData(out string sceneName, out string launchToken)
    {
        sceneName = null;
        launchToken = null;
        try
        {
            using (AndroidJavaObject intent =
                AndroidApplication.currentActivity.Call<AndroidJavaObject>("getIntent"))
            {
                if (intent == null) return;
                sceneName   = intent.Call<string>("getStringExtra", "sceneName");
                launchToken = intent.Call<string>("getStringExtra", "launchToken");
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError("[FlutterBridge] Failed to read Intent data: " + e.Message);
        }
    }
}
