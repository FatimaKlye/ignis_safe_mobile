// simulation_scene.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../unity_launcher.dart';
import '../profile_progress_sync.dart';
import '../simulation_history_service.dart';
import '../module_progress_db.dart';

class SimulationScene5 extends StatefulWidget {
  const SimulationScene5({super.key});

  @override
  State<SimulationScene5> createState() => _SimulationScene5State();
}

class _SimulationScene5State extends State<SimulationScene5> {
  static const accent = Color(0xFF7C3AED);
  static const accent2 = Color(0xFF5B21B6);

  static const int _moduleNo = 5;
  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  final SimulationHistoryService _simulationHistoryService =
      SimulationHistoryService();

  String? _moduleId;
  String? _simulationAttemptId;
  bool _simulationMarkedComplete = false;

  @override
  void initState() {
    super.initState();
    _startSimulationTracking();
  }

  String _sceneLabelFor(int scene) {
    switch (scene) {
      case 5:
        return 'Module 5 - Scene 5';
      default:
        return 'Module 5 - Scene 5';
    }
  }

  String? _unitySceneNameFor(int scene) {
    switch (scene) {
      case 5:
        return 'Building_Fire';
      default:
        return null;
    }
  }

  Future<void> _startSimulationTracking() async {
    final session = await _simulationHistoryService.startAttempt(
      moduleNo: _moduleNo,
    );

    if (!mounted || session == null) return;

    _moduleId = session.moduleId;
    _simulationAttemptId = session.attemptId;
    _simulationMarkedComplete = false;
  }

  Future<void> _completeSimulationTracking() async {
    if (_simulationMarkedComplete) return;
    _simulationMarkedComplete = true;

    final moduleId = _moduleId;
    final attemptId = _simulationAttemptId;

    if (moduleId == null || attemptId == null) {
      await ModuleProgressDb.markSimulationCompleted(_moduleNo);
      return;
    }

    await _simulationHistoryService.completeAttempt(
      moduleId: moduleId,
      attemptId: attemptId,
      score: null,
    );
  }

  Future<void> _openSceneFlow() async {
    final picked = await _showScenePickerPopup();
    if (!mounted || picked == null) return;

    final confirmed = await _showSceneConfirmPopup(picked);
    if (!mounted || confirmed != true) return;

    final unitySceneName = _unitySceneNameFor(picked);

    if (unitySceneName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTl
                ? 'Ang Scene 5 ay hindi pa available sa Unity.'
                : 'Scene 5 is not yet available in Unity.',
          ),
        ),
      );
      return;
    }

    var unityReturned = false;
    try {
      if (_moduleId == null || _simulationAttemptId == null) {
        await _startSimulationTracking();
      }

      final unityResult = await UnityLauncher.openScene(unitySceneName);
      unityReturned = true;

      if (!mounted) return;

      await ProfileProgressSync.updateLastSimulation(_sceneLabelFor(picked));

      if (unityResult.completed == true) {
        await _completeSimulationTracking();
        await ProfileProgressSync.syncCompletedSimulations();

        if (!mounted) return;
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTl
                ? 'Hindi mabuksan ang Unity: ${e.message ?? e.code}'
                : 'Failed to open Unity: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTl
                ? 'Hindi ma-save ang progreso ng simulasyon: $e'
                : 'Failed to save simulation progress: $e',
          ),
        ),
      );
    } finally {
      if (unityReturned && mounted) {
        final nav = Navigator.of(context);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          nav.pop(true);
        });
      }
    }
  }

  Future<int?> _showScenePickerPopup() {
    return showGeneralDialog<int>(
      context: context,
      barrierLabel: "scene_picker",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: _ScenePickerPopup(
                  onClose: () => Navigator.pop(context),
                  onPickScene4: () => Navigator.pop(context, 4),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<bool?> _showSceneConfirmPopup(int scene) {
    return showGeneralDialog<bool>(
      context: context,
      barrierLabel: "scene_confirm",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: _SceneConfirmPopup(
                  scene: scene,
                  onClose: () => Navigator.pop(context, false),
                  onStart: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 900,
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(left: 9, right: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Text(
                          _isTl ? "Simulasyon" : "Simulation Scenes",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [accent, accent2],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isTl ? "MODYUL 5" : "MODULE 5",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _isTl
                                    ? "Sunog sa Tenement: Ano Ito, Karaniwang Sanhi, at Ano ang Dapat Gawin"
                                    : "Tenement Fire: What It Is, Common Causes, and What To Do",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    children: [
                      _ModuleCard(
                        moduleLabel: _isTl ? "MODYUL 5" : "MODULE 5",
                        title: _isTl ? "SUNOG SA TENEMENT" : "TENEMENT FIRE",
                        description: _isTl
                            ? "Alamin ang tamang paglikas kapag may sunog sa tenement, kabilang ang pagbababala sa ibang nakatira, pagyuko kapag may usok, pag-iwas sa elevator, paggamit ng ligtas na labasan, at pagpunta sa assembly area."
                            : "Learn the correct response during a tenement fire, including alerting occupants, staying low in smoke, avoiding elevators, using safe exits, and going to the assembly area.",
                        asset: "assets/condo.jpg",
                        buttonText: _isTl ? "Eksena" : "Scene",
                        onPressed: _openSceneFlow,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;
  final String buttonText;
  final VoidCallback onPressed;

  const _ModuleCard({
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
    required this.buttonText,
    required this.onPressed,
  });

  static const Color brandAmber = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: brandAmber,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF222222),
                        fontSize: 12.8,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandAmber,
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onPressed,
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: brandAmber,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              moduleLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScenePickerPopup extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onPickScene4;

  const _ScenePickerPopup({required this.onClose, required this.onPickScene4});

  static const Color brandAmber = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 345,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brandAmber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: brandAmber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isTl ? "Pumili ng Eksena" : "Choose a Scene",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.black54,
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isTl
                  ? "Ang Modyul 5 ay may isang available na eksena ng simulasyon."
                  : "Module 5 has one available simulation scene.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                height: 1.35,
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _ModernSceneTile(
              title: isTl ? "Eksena 5" : "Scene 5",
              subtitle: isTl
                  ? "Paglikas at pagtugon sa sunog sa tenement"
                  : "Tenement fire evacuation response",
              icon: Icons.local_fire_department_rounded,
              onTap: onPickScene4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSceneTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernSceneTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const Color brandAmber = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    brandAmber.withOpacity(0.92),
                    brandAmber.withOpacity(0.72),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: brandAmber.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: Colors.black.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneConfirmPopup extends StatelessWidget {
  final int scene;
  final VoidCallback onClose;
  final VoidCallback onStart;

  const _SceneConfirmPopup({
    required this.scene,
    required this.onClose,
    required this.onStart,
  });

  static const Color brandAmber = Color(0xFF7C3AED);

  String _body(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';

    switch (scene) {
      case 5:
        return isTl
            ? "Pinili mo ang Eksena 5: Sunog sa tenement.\n\n"
                "Sa eksenang ito, magsasanay ka ng ligtas na paglikas sa tenement:\n"
                "• Ipaalam agad sa ibang nakatira kung ligtas\n"
                "• Yumuko kapag may usok\n"
                "• HUWAG gumamit ng elevator\n"
                "• Gamitin ang pinakamalapit na ligtas na hagdan o labasan\n"
                "• Pumunta sa assembly area at hintayin ang responders"
            : "You chose Scene 5: Tenement fire.\n\n"
                "In this scene, you will practice safe evacuation during a tenement fire:\n"
                "• Alert other occupants immediately if safe\n"
                "• Stay low when there is smoke\n"
                "• Do NOT use elevators\n"
                "• Use the nearest safe stairway or exit\n"
                "• Go to the assembly area and wait for responders";
      default:
        return isTl
            ? "Pumili ka ng eksena. Pindutin ang Simulan para magpatuloy."
            : "You chose a scene. Press Start to continue.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 345,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brandAmber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: brandAmber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isTl ? "Napiling Eksena: Eksena $scene" : "Chosen Scene: Scene $scene",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.black54,
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Text(
                _body(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.black.withOpacity(0.70),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandAmber,
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isTl ? "SIMULAN ANG SIMULASYON" : "START SIMULATION",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isTl
                  ? "Dadalhin ka ng button na ito sa Unity simulation."
                  : "This button will redirect you to the Unity simulation.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
