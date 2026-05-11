package com.unity3d.player;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/**
 * Unity's exported `UnityPlayerGameActivity` defaults to `moveTaskToBack(true)` on unload,
 * which can leave the Flutter task in an unresponsive state on some devices.
 *
 * This host Activity overrides unload/quit to finish() and return to Flutter cleanly.
 *
 * It also kills the Unity process in onDestroy() so that the next simulation always
 * starts with a clean Unity engine. Without this, Unity's native engine retains state
 * from the previous scene and shows a black screen when a different scene is launched.
 *
 * FIX (black screen / scene-switching bug):
 *   - The scene name is now forwarded to Unity via UnitySendMessage() every time,
 *     not just logged. Unity's SceneLoader C# script must receive this and call
 *     SceneManager.LoadScene(sceneName, LoadSceneMode.Single).
 *   - onNewIntent() is added so that if the activity is reused (singleTop launchMode),
 *     the new scene name is captured and forwarded immediately.
 *   - setIntent() is called in onNewIntent() so getIntent() always returns the
 *     current (latest) intent — Unity C# code that reads getIntent() directly will
 *     also get the correct scene name.
 *   - onWindowFocusChanged() is used to send the scene name to Unity at the earliest
 *     moment when Unity's C# runtime is ready to receive messages (first launch path).
 */
public class UnityFlutterHostActivity extends UnityPlayerGameActivity {

    private static final String TAG = "UnityFlutterHost";

    // [FIX] Store the scene name so it can be forwarded to Unity at the right moment.
    private String _requestedSceneName = null;
    // [FIX] Track whether UnitySendMessage has already been sent for this launch,
    //       so we don't double-send if both onWindowFocusChanged and onNewIntent fire.
    private boolean _sceneNameSentToUnity = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // OLD: only logged the scene name, never forwarded it to Unity.
        // String sceneName = getIntent().getStringExtra("sceneName");
        // Log.d(TAG, "[Unity] Activity started. Requested scene: " + sceneName);

        // [FIX] Read, log, and store the scene name for forwarding to Unity.
        String sceneName = getIntent().getStringExtra("sceneName");
        Log.d(TAG, "[Unity] Activity started (onCreate). Android received scene: " + sceneName);
        _requestedSceneName = sceneName;
        _sceneNameSentToUnity = false;
        Log.d(TAG, "[Unity] Scene stored. Will forward to Unity via UnitySendMessage on window focus.");
    }

    /**
     * [FIX] Handle re-delivery of a new scene intent when the activity is reused
     * (android:launchMode="singleTop" in AndroidManifest.xml).
     *
     * IMPORTANT: setIntent(intent) must be called here so that getIntent() on this
     * Activity — and inside Unity's C# code — returns the NEW intent, not the old one.
     * Without setIntent(), getIntent() keeps returning the original (wrong) scene name.
     */
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);

        // Update getIntent() to reflect the new intent — critical for Unity C# code
        // that reads UnityPlayer.currentActivity.getIntent() directly.
        setIntent(intent);

        String sceneName = intent.getStringExtra("sceneName");
        Log.d(TAG, "[Unity] onNewIntent — Android received new scene: " + sceneName);

        _requestedSceneName = sceneName;
        _sceneNameSentToUnity = false;

        // Unity is already running when onNewIntent() fires (activity was reused),
        // so UnitySendMessage can be called immediately.
        Log.d(TAG, "[Unity] Forwarding new scene to Unity immediately (onNewIntent path).");
        _sendSceneNameToUnity();
    }

    /**
     * [FIX] Forward the scene name to Unity via UnitySendMessage when the window
     * receives focus. This is the earliest reliable moment that Unity's C# runtime
     * (including Start() methods) is ready to receive messages on a fresh launch.
     */
    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            Log.d(TAG, "[Unity] onWindowFocusChanged(true) — Unity window focused.");
            if (!_sceneNameSentToUnity && _requestedSceneName != null) {
                Log.d(TAG, "[Unity] Sending scene to Unity via UnitySendMessage: " + _requestedSceneName);
                _sendSceneNameToUnity();
            } else if (_sceneNameSentToUnity) {
                Log.d(TAG, "[Unity] Scene already sent to Unity. Skipping duplicate send.");
            }
        }
    }

    /**
     * [FIX] Send the requested scene name to Unity's SceneLoader C# script.
     *
     * Target: GameObject named "SceneLoader" in the Unity scene, with a public
     * method  void LoadScene(string sceneName)  that calls:
     *   SceneManager.LoadScene(sceneName, LoadSceneMode.Single);
     *
     * The SceneLoader GameObject must use DontDestroyOnLoad so it persists
     * across scene transitions and is always available to receive this message.
     *
     * UnitySendMessage() is thread-safe and queues messages if Unity's C# runtime
     * is not yet ready, so it is safe to call from any lifecycle method.
     */
    private void _sendSceneNameToUnity() {
        if (_requestedSceneName == null || _requestedSceneName.isEmpty()) {
            Log.w(TAG, "[Unity] _sendSceneNameToUnity — scene name is null/empty, skipping.");
            return;
        }
        try {
            Log.d(TAG, "[Unity] Unity received scene (UnitySendMessage): " + _requestedSceneName);
            UnityPlayer.UnitySendMessage("SceneLoader", "LoadScene", _requestedSceneName);
            _sceneNameSentToUnity = true;
            Log.d(TAG, "[Unity] UnitySendMessage dispatched successfully for scene: " + _requestedSceneName);
        } catch (Exception e) {
            Log.e(TAG, "[Unity] UnitySendMessage failed: " + e.getMessage(), e);
        }
    }

    @Override
    public void onUnityPlayerUnloaded() {
        Log.d(TAG, "[Unity] onUnityPlayerUnloaded — Unity returned to Flutter. Calling finish().");
        // OLD: moveTaskToBack(true) — left Unity running in background, causing black
        //      screen on relaunch because Unity's native state was not cleaned up.
        // moveTaskToBack(true);
        finish();
    }

    @Override
    public void onUnityPlayerQuitted() {
        Log.d(TAG, "[Unity] onUnityPlayerQuitted — Unity returned to Flutter. Calling finish().");
        finish();
    }

    @Override
    protected void onDestroy() {
        Log.d(TAG, "[Unity] onDestroy — cleaning up Unity player, then killing Unity process.");
        try {
            // Let the base class run its cleanup (calls mUnityPlayer.destroy())
            super.onDestroy();
        } finally {
            // Kill the Unity process so it always reinitializes cleanly on the next launch.
            // Root cause of the black-screen bug: when this process stays alive, the native
            // Unity engine (libgame.so) retains state from the previous scene. A fresh process
            // guarantees Unity reads the correct Intent scene name and renders normally.
            Log.d(TAG, "[Unity] Killing Unity process (pid=" + android.os.Process.myPid() + ") for clean reinit.");
            android.os.Process.killProcess(android.os.Process.myPid());
        }
    }
}
