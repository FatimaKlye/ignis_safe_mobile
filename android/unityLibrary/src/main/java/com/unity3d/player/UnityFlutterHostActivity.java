package com.unity3d.player;

/**
 * Unity's exported `UnityPlayerGameActivity` defaults to `moveTaskToBack(true)` on unload,
 * which can leave the Flutter task in an unresponsive state on some devices.
 *
 * This host Activity overrides unload/quit to finish() and return to Flutter cleanly.
 */
public class UnityFlutterHostActivity extends UnityPlayerGameActivity {
    @Override
    public void onUnityPlayerUnloaded() {
        finish();
    }

    @Override
    public void onUnityPlayerQuitted() {
        finish();
    }
}

