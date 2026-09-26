using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class Scene5BuildingFireManager : MonoBehaviour
{
    [Header("Player")]
    public GameObject playerRoot;
    public Rigidbody playerRigidbody;
    public CharacterController playerCharacterController;
    public MonoBehaviour[] movementScriptsToDisable;

    [Header("Respawn Settings")]
    public Transform playerSpawnPoint;
    public float smokeSuffocationSeconds = 2.5f;
    public float respawnFreezeSeconds = 1f;

    [Header("UI Roots")]
    public GameObject objectivePanel;
    public GameObject warningPanel;
    public GameObject completePanel;

    [Header("Mobile Controls")]
    public GameObject mobileControlsRoot;
    public GameObject[] mobileControlObjectsToHide;

    [Header("Mobile Crouch Mode")]
    public bool mobileCrouchIsToggle = true;

    [Header("Objective UI")]
    public TextMeshProUGUI objectiveText;

    [Header("Warning / Feedback UI")]
    public Image warningPanelBackground;
    public TextMeshProUGUI warningTitleText;
    public TextMeshProUGUI warningBodyText;

    [Header("Complete UI")]
    public TextMeshProUGUI completeTitleText;
    public TextMeshProUGUI completeBodyText;
    public TextMeshProUGUI completeCountdownText;

    [Header("Emergency Scene Objects")]
    public GameObject fireRoot;
    public GameObject smokeRoot;
    public GameObject alarmLightRoot;
    public AudioSource alarmAudioSource;

    [Header("Alarm Light Settings")]
    public Light[] alarmLights;
    public float alarmBlinkSpeed = 5f;
    public float alarmMinIntensity = 0.2f;
    public float alarmMaxIntensity = 3f;

    [Header("Panel Colors")]
    public Color infoColor = new Color(0.10f, 0.32f, 0.75f, 1f);
    public Color warningColor = new Color(0.80f, 0.12f, 0.12f, 1f);

    [Header("Panel Timing")]
    public float openingBriefDuration = 4f;
    public float infoPanelDuration = 3f;
    public float warningPanelDuration = 3f;

    [Header("Smoke Settings")]
    public KeyCode crouchKey = KeyCode.C;

    [Header("Completion Settings")]
    public float returnCountdownSeconds = 5f;

    [Header("Opening Brief")]
    public bool showOpeningBrief = true;
    public float openingBriefDelay = 0.5f;

    private bool emergencyStarted;
    private bool elevatorWarningShown;
    private bool smokeZoneActive;
    private bool smokePassed;
    private bool usedStairs;
    private bool finalCheckpointReached;
    private bool completionStarted;
    private bool isPlayerFrozen;
    private bool mobileCrouchActive;
    private bool isRespawning;

    private float smokeDangerTimer;
    private float nextSmokeWarningTime;

    private Vector3 fallbackSpawnPosition;
    private Quaternion fallbackSpawnRotation;

    private Coroutine warningHideRoutine;
    private GameObject progressPanel;
    private TextMeshProUGUI progressText;
    private Scene5FinalQuestionPanel finalQuestionPanel;
    private bool finalQuestionOpen;
    private bool finalQuestionAnswered;

    private void Start()
    {
        infoColor = IgnisUiTheme.InfoPanelColor;
        warningColor = IgnisUiTheme.WarningPanelColor;
        IgnisUiTheme.ApplyToScene(gameObject.scene);
        showOpeningBrief = false;

        CacheFallbackSpawn();

        HidePanelsAtStart();

        if (objectivePanel != null)
            objectivePanel.SetActive(true);

        BuildProgressHud();
        UpdateProgressHud();

        SetMobileControlsVisible(true);
        StartEmergencyImmediately();

        if (showOpeningBrief)
            StartCoroutine(ShowOpeningBriefRoutine());
    }

    private void Update()
    {
        HandleSmokeLogic();
        HandleAlarmLights();
        LayoutProgressHud();

        if (isPlayerFrozen)
            StopPlayerMovementNow();
    }

    private void CacheFallbackSpawn()
    {
        if (playerRoot != null)
        {
            fallbackSpawnPosition = playerRoot.transform.position;
            fallbackSpawnRotation = playerRoot.transform.rotation;
        }
        else
        {
            fallbackSpawnPosition = transform.position;
            fallbackSpawnRotation = transform.rotation;
        }
    }

    private void HidePanelsAtStart()
    {
        if (warningPanel != null)
            warningPanel.SetActive(false);

        if (completePanel != null)
            completePanel.SetActive(false);
    }

    private void StartEmergencyImmediately()
    {
        emergencyStarted = true;

        if (fireRoot != null)
            fireRoot.SetActive(true);

        if (smokeRoot != null)
            smokeRoot.SetActive(true);

        if (alarmLightRoot != null)
            alarmLightRoot.SetActive(true);

        if (alarmAudioSource != null)
        {
            alarmAudioSource.loop = true;

            if (!alarmAudioSource.isPlaying)
                alarmAudioSource.Play();
        }

        SetObjective("OBJECTIVE: Evacuate using the stairs. Do not use the elevator.");
    }

    private IEnumerator ShowOpeningBriefRoutine()
    {
        yield return new WaitForSeconds(openingBriefDelay);

        ShowWarning(
            "FIRE EMERGENCY",
            "Evacuate now. Use the stairs and do not use the elevator.",
            openingBriefDuration
        );
    }

    private void HandleAlarmLights()
    {
        if (!emergencyStarted || alarmLights == null || alarmLights.Length == 0)
            return;

        float pulse = Mathf.Abs(Mathf.Sin(Time.time * alarmBlinkSpeed));
        float intensity = Mathf.Lerp(alarmMinIntensity, alarmMaxIntensity, pulse);

        foreach (Light alarmLight in alarmLights)
        {
            if (alarmLight != null)
                alarmLight.intensity = intensity;
        }
    }

    private void SetMobileControlsVisible(bool visible)
    {
        if (mobileControlsRoot != null)
            mobileControlsRoot.SetActive(visible);

        if (mobileControlObjectsToHide == null)
            return;

        foreach (GameObject control in mobileControlObjectsToHide)
        {
            if (control != null)
                control.SetActive(visible);
        }
    }

    private void SetObjective(string message)
    {
        if (objectiveText != null)
            objectiveText.text = message;
    }

    public void ElevatorWarning()
    {
        if (!emergencyStarted)
            return;

        if (elevatorWarningShown)
        {
            ShowWarning(
                "ELEVATOR UNSAFE",
                "Do not use the elevator during a fire. Find the stairs.",
                warningPanelDuration
            );

            return;
        }

        elevatorWarningShown = true;

        SetObjective("OBJECTIVE: Find the stairs. Do not use the elevator.");

        ShowWarning(
            "ELEVATOR UNSAFE",
            "Elevators may stop or open onto a fire. Use the stairs.",
            warningPanelDuration
        );
    }

    public void EnterSmokeZone()
    {
        if (!emergencyStarted || isRespawning)
            return;

        if (smokePassed)
            return;

        smokeZoneActive = true;
        smokeDangerTimer = 0f;

        SetObjective("OBJECTIVE: Crouch and stay low beneath the smoke.");

        ShowInfo(
            "SMOKE AREA",
            "Crouch and stay low beneath the smoke.",
            infoPanelDuration
        );
    }

    public void ExitSmokeZone()
    {
        smokeZoneActive = false;
        smokeDangerTimer = 0f;

        if (!smokePassed && !isRespawning)
            SetObjective("OBJECTIVE: Continue along the evacuation route.");
    }

    public void ReachSmokeExit()
    {
        if (!emergencyStarted || isRespawning)
            return;

        if (smokePassed)
            return;

        smokePassed = true;
        smokeZoneActive = false;
        smokeDangerTimer = 0f;
        UpdateProgressHud();

        SetObjective("OBJECTIVE: Proceed to the stairwell.");

        ShowInfo(
            "SMOKE CLEARED",
            "Good. You stayed low beneath the smoke.",
            infoPanelDuration
        );
    }

    private void HandleSmokeLogic()
    {
        if (!smokeZoneActive || smokePassed || isRespawning)
            return;

        bool isCrouching = IsCrouching();

        if (isCrouching)
        {
            smokeDangerTimer = 0f;
            SetObjective("OBJECTIVE: Stay crouched until you leave the smoke area.");
            return;
        }

        smokeDangerTimer += Time.deltaTime;

        float remaining = Mathf.Max(0f, smokeSuffocationSeconds - smokeDangerTimer);
        SetObjective("OBJECTIVE: Crouch now — smoke exposure in " + remaining.ToString("0.0") + " s.");

        if (Time.time >= nextSmokeWarningTime)
        {
            nextSmokeWarningTime = Time.time + 1.2f;

            ShowWarning(
                "CROUCH NOW",
                "You are breathing smoke. Stay low.",
                1.2f
            );
        }

        if (smokeDangerTimer >= smokeSuffocationSeconds)
            StartCoroutine(RespawnFromSmoke());
    }

    private IEnumerator RespawnFromSmoke()
    {
        if (isRespawning)
            yield break;

        isRespawning = true;
        smokeZoneActive = false;
        smokeDangerTimer = 0f;
        smokePassed = false;
        UpdateProgressHud();

        FreezePlayer(true);
        SetMobileControlsVisible(false);

        ShowWarning(
            "SMOKE EXPOSURE",
            "You inhaled too much smoke. Crouch and try again.",
            2f
        );

        yield return new WaitForSeconds(0.5f);

        RespawnPlayer();

        yield return new WaitForSeconds(respawnFreezeSeconds);

        FreezePlayer(false);
        SetMobileControlsVisible(true);

        SetObjective("OBJECTIVE: Try again. Crouch and move beneath the smoke.");

        isRespawning = false;
    }

    private void RespawnPlayer()
    {
        if (playerRoot == null)
            return;

        Vector3 targetPosition = playerSpawnPoint != null ? playerSpawnPoint.position : fallbackSpawnPosition;
        Quaternion targetRotation = playerSpawnPoint != null ? playerSpawnPoint.rotation : fallbackSpawnRotation;

        bool hadCharacterController = playerCharacterController != null;
        bool characterControllerWasEnabled = false;

        if (hadCharacterController)
        {
            characterControllerWasEnabled = playerCharacterController.enabled;
            playerCharacterController.enabled = false;
        }

        if (playerRigidbody != null)
        {
#if UNITY_6000_0_OR_NEWER
            playerRigidbody.linearVelocity = Vector3.zero;
#else
            playerRigidbody.velocity = Vector3.zero;
#endif
            playerRigidbody.angularVelocity = Vector3.zero;
        }

        playerRoot.transform.SetPositionAndRotation(targetPosition, targetRotation);

        if (hadCharacterController)
            playerCharacterController.enabled = characterControllerWasEnabled;
    }

    private bool IsCrouching()
    {
        if (mobileCrouchActive)
            return true;

        if (Input.GetKey(crouchKey) || Input.GetKey(KeyCode.LeftControl))
            return true;

        return false;
    }

    public void SetMobileCrouchDown()
    {
        if (mobileCrouchIsToggle)
            return;

        mobileCrouchActive = true;
    }

    public void SetMobileCrouchUp()
    {
        if (mobileCrouchIsToggle)
            return;

        mobileCrouchActive = false;
    }

    public void ToggleMobileCrouch()
    {
        mobileCrouchActive = !mobileCrouchActive;
    }

    public void SetMobileCrouchActive(bool active)
    {
        mobileCrouchActive = active;
    }

    public void ReachStairwell()
    {
        if (!emergencyStarted)
            return;

        if (usedStairs)
            return;

        usedStairs = true;
        UpdateProgressHud();

        SetObjective("OBJECTIVE: Use the stairs and continue to the exit.");

        ShowInfo(
            "STAIRS",
            "Correct. Continue down the stairs to the exit.",
            infoPanelDuration
        );
    }

    public void ReachFinalCheckpoint()
    {
        if (!emergencyStarted)
            return;

        if (!smokePassed)
        {
            ShowWarning(
                "Smoke Route Required",
                "Pass the smoke area first.",
                warningPanelDuration
            );

            return;
        }

        if (!usedStairs)
        {
            ShowWarning(
                "Use Stairs First",
                "Use the stairs before exiting.",
                warningPanelDuration
            );

            return;
        }

        if (finalCheckpointReached)
            return;

        finalCheckpointReached = true;
        UpdateProgressHud();

        SetObjective("OBJECTIVE: Proceed to the designated assembly area.");

        ShowInfo(
            "FINAL CHECKPOINT",
            "Good. Proceed to the designated assembly area.",
            infoPanelDuration
        );
    }

    public void CompleteScene()
    {
        if (!emergencyStarted)
            return;

        if (!smokePassed)
        {
            ShowWarning(
                "Smoke Route Required",
                "Pass the smoke area first.",
                warningPanelDuration
            );

            return;
        }

        if (!usedStairs)
        {
            ShowWarning(
                "Use Stairs First",
                "Use the stairs before finishing.",
                warningPanelDuration
            );

            return;
        }

        if (!finalCheckpointReached)
        {
            ShowWarning(
                "ASSEMBLY AREA REQUIRED",
                "Follow the exit route and report to the designated assembly area.",
                warningPanelDuration
            );

            SetObjective("OBJECTIVE: Proceed to the designated assembly area.");
            return;
        }

        if (completionStarted || finalQuestionOpen)
            return;

        ShowFinalSafetyQuestion();
    }

    private void ShowFinalSafetyQuestion()
    {
        Canvas canvas = objectivePanel != null ? objectivePanel.GetComponentInParent<Canvas>(true) : null;
        if (canvas == null)
        {
            Debug.LogError("Scene 5 final question could not find the gameplay Canvas.");
            return;
        }

        finalQuestionOpen = true;
        FreezePlayer(true);
        SetMobileControlsVisible(false);

        if (objectivePanel != null)
            objectivePanel.SetActive(false);
        if (progressPanel != null)
            progressPanel.SetActive(false);
        if (warningPanel != null)
            warningPanel.SetActive(false);

        if (finalQuestionPanel == null)
            finalQuestionPanel = gameObject.AddComponent<Scene5FinalQuestionPanel>();

        finalQuestionPanel.Initialize(this, canvas, objectiveText);
        finalQuestionPanel.Show();
    }

    public void FinalSafetyQuestionPassed()
    {
        if (!finalQuestionOpen || finalQuestionAnswered || completionStarted)
            return;

        finalQuestionOpen = false;
        finalQuestionAnswered = true;
        completionStarted = true;
        StartCoroutine(CompleteRoutine());
    }

    private IEnumerator CompleteRoutine()
    {
        FreezePlayer(true);

        if (objectivePanel != null)
            objectivePanel.SetActive(false);
        if (progressPanel != null)
            progressPanel.SetActive(false);

        if (warningPanel != null)
            warningPanel.SetActive(false);

        SetMobileControlsVisible(false);
        HideExitButton();

        if (alarmAudioSource != null && alarmAudioSource.isPlaying)
            alarmAudioSource.Stop();

        if (completePanel != null)
        {
            completePanel.SetActive(true);
            completePanel.transform.SetAsLastSibling();
            IgnisUiTheme.ApplyToRoot(completePanel);
        }

        if (completeTitleText != null)
            completeTitleText.text = "Simulation Complete";

        // The original Scene 5 body label is the reliably rendered second line
        // in this panel, so use it for the same return countdown shown elsewhere.
        TextMeshProUGUI countdownDisplay = completeBodyText != null
            ? completeBodyText
            : completeCountdownText;

        if (countdownDisplay != null)
            countdownDisplay.gameObject.SetActive(true);
        if (completeCountdownText != null && completeCountdownText != countdownDisplay)
            completeCountdownText.gameObject.SetActive(false);

        float timer = returnCountdownSeconds;

        while (timer > 0)
        {
            if (countdownDisplay != null)
            {
                countdownDisplay.gameObject.SetActive(true);
                countdownDisplay.text = "Returning to the app in " + Mathf.CeilToInt(timer) + "...";
            }

            timer -= Time.unscaledDeltaTime;
            yield return null;
        }

        if (countdownDisplay != null)
            countdownDisplay.text = "Returning to the app...";

        ReturnToFlutter();
    }

    private void BuildProgressHud()
    {
        if (objectivePanel == null || progressPanel != null)
            return;

        RectTransform objectiveRect = objectivePanel.GetComponent<RectTransform>();
        if (objectiveRect == null || objectiveRect.parent == null)
            return;

        progressPanel = new GameObject("EvacuationProgressPanel", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        progressPanel.transform.SetParent(objectiveRect.parent, false);
        Image background = progressPanel.GetComponent<Image>();
        background.color = new Color32(12, 74, 92, 225);
        background.raycastTarget = false;

        GameObject textObject = new GameObject("EvacuationProgressText", typeof(RectTransform), typeof(CanvasRenderer), typeof(TextMeshProUGUI));
        textObject.transform.SetParent(progressPanel.transform, false);
        progressText = textObject.GetComponent<TextMeshProUGUI>();
        if (objectiveText != null && objectiveText.font != null)
            progressText.font = objectiveText.font;
        progressText.fontSize = 13f;
        progressText.enableAutoSizing = true;
        progressText.fontSizeMin = 9f;
        progressText.fontSizeMax = 13f;
        progressText.fontStyle = FontStyles.Bold;
        progressText.alignment = TextAlignmentOptions.Center;
        progressText.color = IgnisUiTheme.SecondaryTextColor;
        progressText.textWrappingMode = TextWrappingModes.NoWrap;
        progressText.overflowMode = TextOverflowModes.Truncate;
        progressText.raycastTarget = false;

        RectTransform textRect = progressText.rectTransform;
        textRect.anchorMin = Vector2.zero;
        textRect.anchorMax = Vector2.one;
        textRect.offsetMin = new Vector2(8f, 4f);
        textRect.offsetMax = new Vector2(-8f, -4f);
        textRect.localScale = Vector3.one;

        LayoutProgressHud();
    }

    private void LayoutProgressHud()
    {
        if (progressPanel == null || objectivePanel == null || !progressPanel.activeSelf)
            return;

        RectTransform objectiveRect = objectivePanel.GetComponent<RectTransform>();
        RectTransform progressRect = progressPanel.GetComponent<RectTransform>();
        if (objectiveRect == null || progressRect == null)
            return;

        progressRect.anchorMin = objectiveRect.anchorMin;
        progressRect.anchorMax = objectiveRect.anchorMax;
        progressRect.pivot = objectiveRect.pivot;
        progressRect.anchoredPosition = objectiveRect.anchoredPosition + new Vector2(0f, -86f);
        progressRect.sizeDelta = new Vector2(objectiveRect.sizeDelta.x, 34f);
        progressRect.localScale = Vector3.one;
        progressRect.localRotation = Quaternion.identity;
    }

    private void UpdateProgressHud()
    {
        if (progressText == null)
            return;

        progressText.text = "ROUTE  SMOKE [" + (smokePassed ? "OK" : " ") + "]   STAIRS [" +
            (usedStairs ? "OK" : " ") + "]   ASSEMBLY [" + (finalCheckpointReached ? "OK" : " ") + "]";
    }

    private void HideExitButton()
    {
        Canvas canvas = objectivePanel != null ? objectivePanel.GetComponentInParent<Canvas>(true) : null;
        if (canvas == null && completePanel != null)
            canvas = completePanel.GetComponentInParent<Canvas>(true);
        if (canvas == null)
            return;

        foreach (Button button in canvas.GetComponentsInChildren<Button>(true))
        {
            if (!string.Equals(button.gameObject.name, "LeaveButton", System.StringComparison.OrdinalIgnoreCase))
                continue;

            button.interactable = false;
            button.gameObject.SetActive(false);
        }
    }

    private void ShowInfo(string title, string message, float duration)
    {
        ShowPanel(title, message, infoColor, duration);
    }

    private void ShowWarning(string title, string message, float duration)
    {
        ShowPanel(title, message, warningColor, duration);
    }

    private void ShowPanel(string title, string message, Color panelColor, float duration)
    {
        if (warningPanel != null)
            warningPanel.SetActive(true);

        if (warningPanelBackground != null)
            warningPanelBackground.color = panelColor;

        if (warningTitleText != null)
            warningTitleText.text = title;

        if (warningBodyText != null)
            warningBodyText.text = message;

        if (warningHideRoutine != null)
            StopCoroutine(warningHideRoutine);

        if (duration > 0f)
            warningHideRoutine = StartCoroutine(HideWarningAfterDelay(duration));
    }

    private IEnumerator HideWarningAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);

        if (warningPanel != null)
            warningPanel.SetActive(false);

        warningHideRoutine = null;
    }

    public void CloseWarningPanel()
    {
        if (warningHideRoutine != null)
        {
            StopCoroutine(warningHideRoutine);
            warningHideRoutine = null;
        }

        if (warningPanel != null)
            warningPanel.SetActive(false);
    }

    private void FreezePlayer(bool freeze)
    {
        isPlayerFrozen = freeze;

        if (movementScriptsToDisable != null)
        {
            foreach (MonoBehaviour script in movementScriptsToDisable)
            {
                if (script != null)
                    script.enabled = !freeze;
            }
        }

        StopPlayerMovementNow();
    }

    private void StopPlayerMovementNow()
    {
        if (playerRigidbody != null)
        {
#if UNITY_6000_0_OR_NEWER
            playerRigidbody.linearVelocity = Vector3.zero;
#else
            playerRigidbody.velocity = Vector3.zero;
#endif
            playerRigidbody.angularVelocity = Vector3.zero;
        }
    }

    private void ReturnToFlutter()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            IgnisFlutterActivityBridge.MarkSimulationCompleted();
            using (AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                AndroidJavaObject activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
                activity.Call("finish");
            }
        }
        catch
        {
            Application.Quit();
        }
#else
        Debug.Log("Scene 5 complete. Android build will return to Flutter.");
#endif
    }
}

/// <summary>
/// Final knowledge check shown at the assembly area. The learner must confirm
/// the safe post-evacuation action before the simulation can complete.
/// </summary>
internal sealed class Scene5FinalQuestionPanel : MonoBehaviour
{
    private Scene5BuildingFireManager manager;
    private Canvas canvas;
    private TMP_Text fontSource;
    private GameObject overlay;
    private TMP_Text feedbackText;
    private readonly System.Collections.Generic.List<Button> answerButtons =
        new System.Collections.Generic.List<Button>();
    private bool answerLocked;
    private CursorLockMode previousCursorLock;
    private bool previousCursorVisible;

    public void Initialize(Scene5BuildingFireManager owner, Canvas targetCanvas, TMP_Text template)
    {
        manager = owner;
        canvas = targetCanvas;
        fontSource = template;

        if (overlay == null)
            BuildUi();
    }

    public void Show()
    {
        if (overlay == null)
            BuildUi();
        if (overlay == null)
            return;

        answerLocked = false;
        feedbackText.text = string.Empty;
        ResetButtons();
        previousCursorLock = Cursor.lockState;
        previousCursorVisible = Cursor.visible;
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
        overlay.SetActive(true);
        overlay.transform.SetAsLastSibling();
    }

    private void BuildUi()
    {
        if (canvas == null)
            return;

        overlay = new GameObject("BuildingFireFinalQuestion", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        overlay.transform.SetParent(canvas.transform, false);
        Image background = overlay.GetComponent<Image>();
        background.color = new Color32(15, 23, 42, 247);
        background.raycastTarget = true;
        Stretch(overlay.GetComponent<RectTransform>());

        TMP_Text title = CreateText("QuestionTitle", overlay.transform, "SAFETY CHECK", 36f, FontStyles.Bold);
        SetRect(title.rectTransform, new Vector2(0f, 174f), new Vector2(780f, 58f));
        title.color = IgnisUiTheme.AccentColor;

        TMP_Text progress = CreateText(
            "RouteSummary",
            overlay.transform,
            "EVACUATION ROUTE COMPLETE",
            15f,
            FontStyles.Bold
        );
        SetRect(progress.rectTransform, new Vector2(0f, 137f), new Vector2(600f, 28f));
        progress.color = IgnisUiTheme.SecondaryTextColor;

        TMP_Text question = CreateText(
            "QuestionBody",
            overlay.transform,
            "After reaching the assembly area, what should you do?",
            27f,
            FontStyles.Normal
        );
        SetRect(question.rectTransform, new Vector2(0f, 88f), new Vector2(820f, 70f));
        question.enableAutoSizing = true;
        question.fontSizeMin = 21f;
        question.fontSizeMax = 27f;
        question.textWrappingMode = TextWrappingModes.Normal;

        answerButtons.Add(CreateAnswerButton(
            "AnswerA",
            "Return inside to collect your belongings.",
            new Vector2(-270f, -55f),
            0
        ));
        answerButtons.Add(CreateAnswerButton(
            "AnswerB",
            "Stay at the assembly area and report to the fire marshal.",
            new Vector2(0f, -55f),
            1
        ));
        answerButtons.Add(CreateAnswerButton(
            "AnswerC",
            "Leave immediately without telling anyone.",
            new Vector2(270f, -55f),
            2
        ));

        feedbackText = CreateText("AnswerFeedback", overlay.transform, string.Empty, 18f, FontStyles.Bold);
        SetRect(feedbackText.rectTransform, new Vector2(0f, -174f), new Vector2(820f, 48f));
        feedbackText.enableAutoSizing = true;
        feedbackText.fontSizeMin = 15f;
        feedbackText.fontSizeMax = 18f;

        overlay.SetActive(false);
    }

    private Button CreateAnswerButton(string objectName, string label, Vector2 position, int answerIndex)
    {
        GameObject buttonObject = new GameObject(objectName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
        buttonObject.transform.SetParent(overlay.transform, false);
        RectTransform rect = buttonObject.GetComponent<RectTransform>();
        SetRect(rect, position, new Vector2(242f, 154f));

        Image image = buttonObject.GetComponent<Image>();
        image.color = IgnisUiTheme.AnswerButtonColor;

        Button button = buttonObject.GetComponent<Button>();
        button.targetGraphic = image;
        ColorBlock colors = button.colors;
        colors.normalColor = IgnisUiTheme.AnswerButtonColor;
        colors.highlightedColor = IgnisUiTheme.AnswerButtonHighlightColor;
        colors.pressedColor = IgnisUiTheme.AnswerButtonPressedColor;
        button.colors = colors;
        button.onClick.AddListener(() => SelectAnswer(button, answerIndex));

        TMP_Text text = CreateText("Label", buttonObject.transform, label, 21f, FontStyles.Bold);
        StretchWithPadding(text.rectTransform, 16f, 14f);
        text.color = IgnisUiTheme.DarkTextColor;
        text.enableAutoSizing = true;
        text.fontSizeMin = 15f;
        text.fontSizeMax = 21f;
        text.textWrappingMode = TextWrappingModes.Normal;
        text.overflowMode = TextOverflowModes.Truncate;
        text.raycastTarget = false;
        return button;
    }

    private void SelectAnswer(Button selectedButton, int answerIndex)
    {
        if (answerLocked)
            return;

        if (answerIndex == 1)
        {
            answerLocked = true;
            SetButtonState(selectedButton, IgnisUiTheme.CorrectColor, Color.white);
            feedbackText.color = new Color32(134, 239, 172, 255);
            feedbackText.text = "Correct. Stay at the assembly area and report that you are safe.";
            foreach (Button button in answerButtons)
            {
                if (button != null)
                    button.interactable = false;
            }
            StartCoroutine(CompleteAfterFeedback());
            return;
        }

        answerLocked = true;
        SetButtonState(selectedButton, IgnisUiTheme.IncorrectColor, Color.white);
        feedbackText.color = new Color32(254, 202, 202, 255);
        feedbackText.text = answerIndex == 0
            ? "Do not re-enter a burning building. Wait for emergency personnel."
            : "Remain at the assembly area so responders can account for everyone.";
        StartCoroutine(ResetWrongAnswer(selectedButton));
    }

    private IEnumerator ResetWrongAnswer(Button selectedButton)
    {
        yield return new WaitForSecondsRealtime(1.35f);
        SetButtonState(selectedButton, IgnisUiTheme.AnswerButtonColor, IgnisUiTheme.DarkTextColor);
        feedbackText.text = string.Empty;
        answerLocked = false;
    }

    private IEnumerator CompleteAfterFeedback()
    {
        yield return new WaitForSecondsRealtime(1f);
        overlay.SetActive(false);
        Cursor.lockState = previousCursorLock;
        Cursor.visible = previousCursorVisible;
        manager.FinalSafetyQuestionPassed();
    }

    private void ResetButtons()
    {
        foreach (Button button in answerButtons)
        {
            if (button == null)
                continue;
            button.interactable = true;
            SetButtonState(button, IgnisUiTheme.AnswerButtonColor, IgnisUiTheme.DarkTextColor);
        }
    }

    private static void SetButtonState(Button button, Color background, Color foreground)
    {
        if (button == null)
            return;

        Image image = button.GetComponent<Image>();
        if (image != null)
            image.color = background;
        TMP_Text label = button.GetComponentInChildren<TMP_Text>(true);
        if (label != null)
            label.color = foreground;
    }

    private TMP_Text CreateText(string objectName, Transform parent, string value, float size, FontStyles style)
    {
        GameObject textObject = new GameObject(objectName, typeof(RectTransform), typeof(CanvasRenderer), typeof(TextMeshProUGUI));
        textObject.transform.SetParent(parent, false);
        TextMeshProUGUI text = textObject.GetComponent<TextMeshProUGUI>();
        if (fontSource != null && fontSource.font != null)
            text.font = fontSource.font;
        text.text = value;
        text.fontSize = size;
        text.fontStyle = style;
        text.alignment = TextAlignmentOptions.Center;
        text.color = IgnisUiTheme.PrimaryTextColor;
        text.margin = Vector4.zero;
        text.raycastTarget = false;
        text.overflowMode = TextOverflowModes.Truncate;
        return text;
    }

    private static void SetRect(RectTransform rect, Vector2 position, Vector2 size)
    {
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.anchoredPosition = position;
        rect.sizeDelta = size;
        rect.localScale = Vector3.one;
        rect.localRotation = Quaternion.identity;
    }

    private static void StretchWithPadding(RectTransform rect, float horizontal, float vertical)
    {
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.one;
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.anchoredPosition = Vector2.zero;
        rect.offsetMin = new Vector2(horizontal, vertical);
        rect.offsetMax = new Vector2(-horizontal, -vertical);
        rect.localScale = Vector3.one;
        rect.localRotation = Quaternion.identity;
    }

    private static void Stretch(RectTransform rect)
    {
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.one;
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.anchoredPosition = Vector2.zero;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;
        rect.localScale = Vector3.one;
        rect.localRotation = Quaternion.identity;
    }
}
