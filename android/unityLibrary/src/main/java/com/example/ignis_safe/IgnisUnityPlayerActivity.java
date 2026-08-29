package com.example.ignis_safe;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.unity3d.player.UnityPlayerGameActivity;

/**
 * Receives the completion callbacks sent by the Unity scenes and returns a
 * trustworthy result to Flutter. Exiting Unity by Back or without reaching a
 * scene's completion action remains a cancelled/incomplete result.
 */
public class IgnisUnityPlayerActivity extends UnityPlayerGameActivity {
    private static final String TAG = "IgnisUnityActivity";
    private boolean simulationCompleted = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setResult(RESULT_CANCELED, new Intent().putExtra("completed", false));
    }

    public void markIgnisSimulationCompleted() {
        simulationCompleted = true;
        setResult(RESULT_OK, new Intent().putExtra("completed", true));
        Log.d(TAG, "Unity reported that the simulation scene was completed");
    }

    public void notifyIgnisSceneReady() {
        Log.d(TAG, "Unity scene is ready");
    }

    @Override
    public void finish() {
        if (!simulationCompleted) {
            setResult(RESULT_CANCELED, new Intent().putExtra("completed", false));
        }
        super.finish();
    }
}
