package com.unity3d.player;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.core.view.ViewCompat;

import com.google.androidgamesdk.GameActivity;

import java.io.InputStream;

public class UnityPlayerGameActivity extends GameActivity implements IUnityPlayerLifecycleEvents, IUnityPermissionRequestSupport, IUnityPlayerSupport
{
    class GameActivitySurfaceView extends InputEnabledSurfaceView
    {
        GameActivity mGameActivity;
        public GameActivitySurfaceView(GameActivity activity) {
            super(activity);
            mGameActivity = activity;
        }

        // Reroute motion events from captured pointer to normal events
        // Otherwise when doing Cursor.lockState = CursorLockMode.Locked from C# the touch and mouse events will stop working
        @Override public boolean onCapturedPointerEvent(MotionEvent event) {
            return mGameActivity.onTouchEvent(event);
        }
    }

    protected UnityPlayerForGameActivity mUnityPlayer;
    private final Handler ignisUiHandler = new Handler(Looper.getMainLooper());
    private FrameLayout ignisLoadingOverlay;
    private final Runnable ignisLoadingTimeout = this::hideIgnisLoadingOverlay;
    protected String updateUnityCommandLineArguments(String cmdLine)
    {
        return cmdLine;
    }

    static
    {
        System.loadLibrary("game");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        Intent result = new Intent();
        result.putExtra("completed", false);
        setResult(Activity.RESULT_CANCELED, result);
    }

    @Override
    public UnityPlayerForGameActivity getUnityPlayerConnection() {
        return mUnityPlayer;
    }

    // Soft keyboard relies on inset listener for listening to various events - keyboard opened/closed/text entered.
    private void applyInsetListener(SurfaceView surfaceView)
    {
        surfaceView.getViewTreeObserver().addOnGlobalLayoutListener(
                () -> onApplyWindowInsets(surfaceView, ViewCompat.getRootWindowInsets(getWindow().getDecorView())));
    }

    @Override protected InputEnabledSurfaceView createSurfaceView() {
        return new GameActivitySurfaceView(this);
    }

    @Override protected void onCreateSurfaceView() {
        super.onCreateSurfaceView();
        FrameLayout frameLayout = findViewById(contentViewId);

        applyInsetListener(mSurfaceView);

        mSurfaceView.setId(UnityPlayerForGameActivity.getUnityViewIdentifier(this));

        String cmdLine = updateUnityCommandLineArguments(getIntent().getStringExtra("unity"));
        getIntent().putExtra("unity", cmdLine);
        // Unity requires access to frame layout for setting the static splash screen.
        // Note: we cannot initialize in onCreate (after super.onCreate), because game activity native thread would be already started and unity runtime initialized
        //       we also cannot initialize before super.onCreate since frameLayout is not yet available.
        mUnityPlayer = new UnityPlayerForGameActivity(this, frameLayout, mSurfaceView, this);
        showIgnisLoadingOverlay(frameLayout);
    }

    private void showIgnisLoadingOverlay(FrameLayout root) {
        if (ignisLoadingOverlay != null) return;

        FrameLayout overlay = new FrameLayout(this);
        overlay.setClickable(true);
        overlay.setBackground(
            new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                new int[] {
                    Color.rgb(20, 17, 18),
                    Color.rgb(52, 27, 29),
                    Color.rgb(25, 20, 21)
                }
            )
        );

        addIgnisBackgroundAccent(
            overlay,
            dp(330),
            Gravity.TOP | Gravity.END,
            dp(-85),
            dp(-115),
            Color.argb(38, 191, 34, 39)
        );
        addIgnisBackgroundAccent(
            overlay,
            dp(220),
            Gravity.BOTTOM | Gravity.START,
            dp(-65),
            dp(-90),
            Color.argb(24, 218, 167, 75)
        );

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER_HORIZONTAL);
        card.setPadding(dp(42), dp(28), dp(42), dp(28));
        GradientDrawable cardBackground = new GradientDrawable();
        cardBackground.setColor(Color.argb(238, 31, 27, 28));
        cardBackground.setCornerRadius(dp(28));
        cardBackground.setStroke(dp(1), Color.argb(42, 255, 255, 255));
        card.setBackground(cardBackground);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            card.setElevation(dp(18));
        }

        FrameLayout logoCard = new FrameLayout(this);
        GradientDrawable logoBackground = new GradientDrawable();
        logoBackground.setColor(Color.rgb(250, 248, 244));
        logoBackground.setCornerRadius(dp(24));
        logoCard.setBackground(logoBackground);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            logoCard.setElevation(dp(8));
        }

        ImageView logo = new ImageView(this);
        logo.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        logo.setPadding(dp(8), dp(8), dp(8), dp(8));
        logo.setContentDescription("IGNIS SAFE logo");
        Drawable logoDrawable = loadIgnisLogo();
        if (logoDrawable != null) {
            logo.setImageDrawable(logoDrawable);
        }
        logoCard.addView(
            logo,
            new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        );
        card.addView(
            logoCard,
            new LinearLayout.LayoutParams(dp(104), dp(104))
        );

        TextView brand = new TextView(this);
        brand.setText("IGNIS SAFE");
        brand.setTextColor(Color.rgb(248, 244, 239));
        brand.setTextSize(25f);
        brand.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        brand.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams brandParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        brandParams.topMargin = dp(18);
        card.addView(brand, brandParams);

        View brandLine = new View(this);
        GradientDrawable brandLineBackground = new GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            new int[] {
                Color.rgb(150, 25, 31),
                Color.rgb(216, 59, 61),
                Color.rgb(218, 167, 75)
            }
        );
        brandLineBackground.setCornerRadius(dp(3));
        brandLine.setBackground(brandLineBackground);
        LinearLayout.LayoutParams brandLineParams = new LinearLayout.LayoutParams(
            dp(92),
            dp(3)
        );
        brandLineParams.topMargin = dp(9);
        card.addView(brandLine, brandLineParams);

        TextView title = new TextView(this);
        title.setText("Preparing your simulation");
        title.setTextColor(Color.WHITE);
        title.setTextSize(18f);
        title.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        titleParams.topMargin = dp(20);
        card.addView(title, titleParams);

        TextView subtitle = new TextView(this);
        subtitle.setText("Setting up the scene and safety controls.");
        subtitle.setTextColor(Color.rgb(196, 187, 187));
        subtitle.setTextSize(14f);
        subtitle.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subtitleParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        subtitleParams.topMargin = dp(6);
        card.addView(subtitle, subtitleParams);

        ProgressBar progress = new ProgressBar(
            this,
            null,
            android.R.attr.progressBarStyleHorizontal
        );
        progress.setIndeterminate(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            progress.setIndeterminateTintList(
                ColorStateList.valueOf(Color.rgb(214, 55, 60))
            );
            progress.setProgressBackgroundTintList(
                ColorStateList.valueOf(Color.rgb(78, 64, 65))
            );
        }
        LinearLayout.LayoutParams progressParams = new LinearLayout.LayoutParams(
            dp(292),
            dp(5)
        );
        progressParams.topMargin = dp(22);
        card.addView(progress, progressParams);

        TextView message = new TextView(this);
        message.setText("Loading simulation...");
        message.setTextColor(Color.rgb(226, 217, 216));
        message.setTextSize(13f);
        message.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams messageParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        messageParams.topMargin = dp(10);
        card.addView(message, messageParams);

        TextView note = new TextView(this);
        note.setText("This may take a moment on the first launch.");
        note.setTextColor(Color.rgb(174, 159, 158));
        note.setTextSize(11f);
        note.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams noteParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        noteParams.topMargin = dp(4);
        card.addView(note, noteParams);

        FrameLayout.LayoutParams cardParams = new FrameLayout.LayoutParams(
            dp(520),
            FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        );
        overlay.addView(card, cardParams);
        root.addView(
            overlay,
            new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        );

        ignisLoadingOverlay = overlay;
        ignisUiHandler.postDelayed(ignisLoadingTimeout, 90000L);
    }

    private Drawable loadIgnisLogo() {
        try (InputStream stream = getAssets().open("flutter_assets/assets/logo.png")) {
            Bitmap source = BitmapFactory.decodeStream(stream);
            if (source == null) return null;
            return new BitmapDrawable(
                getResources(),
                cropTransparentPadding(source)
            );
        } catch (Exception ignored) {
            try {
                return getPackageManager().getApplicationIcon(getApplicationInfo());
            } catch (Exception fallbackError) {
                return null;
            }
        }
    }

    private Bitmap cropTransparentPadding(Bitmap source) {
        int width = source.getWidth();
        int height = source.getHeight();
        int left = width;
        int top = height;
        int right = -1;
        int bottom = -1;
        int[] pixels = new int[width * height];
        source.getPixels(pixels, 0, width, 0, 0, width, height);

        for (int y = 0; y < height; y++) {
            int row = y * width;
            for (int x = 0; x < width; x++) {
                if (Color.alpha(pixels[row + x]) <= 12) continue;
                if (x < left) left = x;
                if (x > right) right = x;
                if (y < top) top = y;
                if (y > bottom) bottom = y;
            }
        }

        if (right < left || bottom < top) return source;

        int padding = Math.max(2, Math.round(Math.max(width, height) * 0.025f));
        left = Math.max(0, left - padding);
        top = Math.max(0, top - padding);
        right = Math.min(width - 1, right + padding);
        bottom = Math.min(height - 1, bottom + padding);

        return Bitmap.createBitmap(
            source,
            left,
            top,
            right - left + 1,
            bottom - top + 1
        );
    }

    private void addIgnisBackgroundAccent(
        FrameLayout overlay,
        int size,
        int gravity,
        int horizontalMargin,
        int verticalMargin,
        int color
    ) {
        View accent = new View(this);
        GradientDrawable accentBackground = new GradientDrawable();
        accentBackground.setShape(GradientDrawable.OVAL);
        accentBackground.setColor(color);
        accent.setBackground(accentBackground);

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
            size,
            size,
            gravity
        );
        if ((gravity & Gravity.END) == Gravity.END) {
            params.rightMargin = horizontalMargin;
        } else {
            params.leftMargin = horizontalMargin;
        }
        if ((gravity & Gravity.BOTTOM) == Gravity.BOTTOM) {
            params.bottomMargin = verticalMargin;
        } else {
            params.topMargin = verticalMargin;
        }
        overlay.addView(accent, params);
    }

    private int dp(int value) {
        return Math.round(
            value * getResources().getDisplayMetrics().density
        );
    }

    private void hideIgnisLoadingOverlay() {
        ignisUiHandler.removeCallbacks(ignisLoadingTimeout);
        FrameLayout overlay = ignisLoadingOverlay;
        if (overlay == null) return;
        ignisLoadingOverlay = null;
        if (overlay.getParent() instanceof FrameLayout) {
            ((FrameLayout) overlay.getParent()).removeView(overlay);
        }
    }

    public void notifyIgnisSceneReady() {
        runOnUiThread(this::hideIgnisLoadingOverlay);
    }

    public void markIgnisSimulationCompleted() {
        Intent result = new Intent();
        result.putExtra("completed", true);
        result.putExtra("sceneName", getIntent().getStringExtra("sceneName"));
        setResult(Activity.RESULT_OK, result);
    }

    @Override
    public void onUnityPlayerUnloaded() {
        moveTaskToBack(true);
    }

    @Override
    public void onUnityPlayerQuitted() {
    }

    // Quit Unity
    @Override protected void onDestroy ()
    {
        ignisUiHandler.removeCallbacksAndMessages(null);
        hideIgnisLoadingOverlay();
        mUnityPlayer.destroy();
        super.onDestroy();
    }

    @Override protected void onStop()
    {
        // Note: we want Java onStop callbacks to be processed before the native part processes the onStop callback
        mUnityPlayer.onStop();
        super.onStop();
    }

    @Override protected void onStart()
    {
        // Note: we want Java onStart callbacks to be processed before the native part processes the onStart callback
        mUnityPlayer.onStart();
        super.onStart();
    }

    // Pause Unity
    @Override protected void onPause()
    {
        // Note: we want Java onPause callbacks to be processed before the native part processes the onPause callback
        mUnityPlayer.onPause();
        super.onPause();
    }

    // Resume Unity
    @Override protected void onResume()
    {
        // Note: we want Java onResume callbacks to be processed before the native part processes the onResume callback
        mUnityPlayer.onResume();
        super.onResume();
    }

    // Configuration changes are used by Video playback logic in Unity
    @Override public void onConfigurationChanged(Configuration newConfig)
    {
        mUnityPlayer.configurationChanged(newConfig);
        super.onConfigurationChanged(newConfig);
    }

    // Notify Unity of the focus change.
    @Override public void onWindowFocusChanged(boolean hasFocus)
    {
        mUnityPlayer.windowFocusChanged(hasFocus);
        super.onWindowFocusChanged(hasFocus);
    }

    @Override protected void onNewIntent(Intent intent)
    {
        super.onNewIntent(intent);
        // To support deep linking, we need to make sure that the client can get access to
        // the last sent intent. The clients access this through a JNI api that allows them
        // to get the intent set on launch. To update that after launch we have to manually
        // replace the intent with the one caught here.
        setIntent(intent);
        mUnityPlayer.newIntent(intent);
    }

    @Override
    public void requestPermissions(PermissionRequest request)
    {
        mUnityPlayer.addPermissionRequest(request);
    }

    @Override public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults)
    {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        mUnityPlayer.permissionResponse(this, requestCode, permissions, grantResults);
    }
}
