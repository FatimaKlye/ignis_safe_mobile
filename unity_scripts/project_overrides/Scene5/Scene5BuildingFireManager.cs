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

    private void Start()
    {
        CacheFallbackSpawn();

        HidePanelsAtStart();

        if (objectivePanel != null)
            objectivePanel.SetActive(true);

        SetMobileControlsVisible(true);
        StartEmergencyImmediately();

        if (showOpeningBrief)
            StartCoroutine(ShowOpeningBriefRoutine());
    }

    private void Update()
    {
        HandleSmokeLogic();
        HandleAlarmLights();

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

        SetObjective("Fire alarm is on. Use the stairs. Do not use the elevator.");
    }

    private IEnumerator ShowOpeningBriefRoutine()
    {
        yield return new WaitForSeconds(openingBriefDelay);

        ShowWarning(
            "Fire Emergency",
            "Evacuate now. Avoid elevators. Use the stairs.",
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
                "Elevator Unsafe",
                "Do not use it. Find the stairs.",
                warningPanelDuration
            );

            return;
        }

        elevatorWarningShown = true;

        SetObjective("Do not use the elevator. Find the stairs.");

        ShowWarning(
            "Do Not Use Elevator",
            "Elevators are unsafe during fire. Use the stairs.",
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

        SetObjective("Smoke ahead. Stay crouched.");

        ShowInfo(
            "Smoke Area",
            "Crouch and stay low.",
            infoPanelDuration
        );
    }

    public void ExitSmokeZone()
    {
        smokeZoneActive = false;
        smokeDangerTimer = 0f;

        if (!smokePassed && !isRespawning)
            SetObjective("Follow the route. Stay low near smoke.");
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

        SetObjective("Smoke passed. Go to the stairs.");

        ShowInfo(
            "Smoke Passed",
            "Good. You stayed low.",
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
            SetObjective("Stay crouched until you leave the smoke.");
            return;
        }

        smokeDangerTimer += Time.deltaTime;

        float remaining = Mathf.Max(0f, smokeSuffocationSeconds - smokeDangerTimer);
        SetObjective("Crouch now. Smoke danger: " + remaining.ToString("0.0") + "s");

        if (Time.time >= nextSmokeWarningTime)
        {
            nextSmokeWarningTime = Time.time + 1.2f;

            ShowWarning(
                "Crouch",
                "You are breathing smoke.",
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

        FreezePlayer(true);
        SetMobileControlsVisible(false);

        ShowWarning(
            "Smoke Inhaled",
            "You stood in smoke. Try again and crouch.",
            2f
        );

        yield return new WaitForSeconds(0.5f);

        RespawnPlayer();

        yield return new WaitForSeconds(respawnFreezeSeconds);

        FreezePlayer(false);
        SetMobileControlsVisible(true);

        SetObjective("Try again. Crouch through the smoke.");

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

        SetObjective("Use the stairs. Go to the exit.");

        ShowInfo(
            "Stairs",
            "Correct. Keep going down.",
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

        SetObjective("Go to the safe assembly area.");

        ShowInfo(
            "Final Checkpoint",
            "Good. Go to the assembly area.",
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

        if (completionStarted)
            return;

        completionStarted = true;
        StartCoroutine(CompleteRoutine());
    }

    private IEnumerator CompleteRoutine()
    {
        FreezePlayer(true);

        if (objectivePanel != null)
            objectivePanel.SetActive(false);

        if (warningPanel != null)
            warningPanel.SetActive(false);

        SetMobileControlsVisible(false);

        if (alarmAudioSource != null && alarmAudioSource.isPlaying)
            alarmAudioSource.Stop();

        if (completePanel != null)
            completePanel.SetActive(true);

        if (completeTitleText != null)
            completeTitleText.text = "Evacuation Complete";

        if (completeBodyText != null)
            completeBodyText.text = "You avoided the elevator, stayed low, used the stairs, and reached safety.";

        float timer = returnCountdownSeconds;

        while (timer > 0)
        {
            if (completeCountdownText != null)
                completeCountdownText.text = "Returning in " + Mathf.CeilToInt(timer) + "...";

            timer -= Time.deltaTime;
            yield return null;
        }

        ReturnToFlutter();
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
