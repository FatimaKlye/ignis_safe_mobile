import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../module_progress_db.dart';
import '../profile_progress_sync.dart';
import '../simulation_history_service.dart';
import '../unity_launcher.dart';
import '../widgets/app_notification.dart';

const Color kBrandBlue = Color(0xFF2563EB);
const Color kBrandBlueDark = Color(0xFF1D4ED8);
const Color kBrandBlueDeep = Color(0xFF1E3A8A);
const Color kBrandBlueSoft = Color(0xFFEFF6FF);

class SimulationScene3 extends StatefulWidget {
  const SimulationScene3({super.key});

  @override
  State<SimulationScene3> createState() => _SimulationScene3State();
}

class _SimulationScene3State extends State<SimulationScene3> {
  static const int _moduleNo = 3;
  static const String _unitySceneName = 'Electrical Fire Safety';
  static const String _sceneLabel = 'Module 3 - Scene 3';

  final SimulationHistoryService _simulationHistoryService =
      SimulationHistoryService();

  String? _moduleId;
  String? _simulationAttemptId;
  bool _simulationMarkedComplete = false;
  bool _isUnityLaunching = false;
  String? _launchError;

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openSceneFlow();
      }
    });
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
    if (_isUnityLaunching) return;

    var unityReturned = false;

    try {
      setState(() {
        _isUnityLaunching = true;
        _launchError = null;
      });

      if (_moduleId == null || _simulationAttemptId == null) {
        await _startSimulationTracking();
      }

      final unityResult = await UnityLauncher.openScene(_unitySceneName);
      unityReturned = true;

      if (!mounted) return;

      await ProfileProgressSync.updateLastSimulation(_sceneLabel);

      if (unityResult.completed == true) {
        await _completeSimulationTracking();
        await ProfileProgressSync.syncCompletedSimulations();

        if (!mounted) return;
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      final message = _isTl
          ? 'Hindi mabuksan ang Unity: ${e.message ?? e.code}'
          : 'Failed to open Unity: ${e.message ?? e.code}';

      setState(() => _launchError = message);

      showAppNotification(
        context,
        message: message,
        type: AppNotificationType.error,
        accentColor: kBrandBlue,
      );
    } catch (e) {
      if (!mounted) return;

      final message = _isTl
          ? 'Hindi ma-save ang progreso ng simulasyon: $e'
          : 'Failed to save simulation progress: $e';

      setState(() => _launchError = message);

      showAppNotification(
        context,
        message: message,
        type: AppNotificationType.error,
        accentColor: kBrandBlue,
      );
    } finally {
      if (mounted) {
        setState(() => _isUnityLaunching = false);
      } else {
        _isUnityLaunching = false;
      }

      if (unityReturned && mounted) {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop(true);
        }
      }
    }
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isTl
        ? 'Binubuksan ang Eksena 3'
        : 'Opening Scene 3';
    final subtitle = _isTl
        ? 'Tutorial sa Kaligtasan sa Sunog sa Kuryente'
        : 'Electrical Fire Safety Tutorial';
    final message = _isTl
        ? 'Ididirekta ka sa Unity simulation. Mangyaring maghintay.'
        : 'Redirecting you to the Unity simulation. Please wait.';
    final retryText = _isTl ? 'SUBUKAN MULI' : 'RETRY';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kBrandBlueDeep.withOpacity(0.20),
                    Colors.black.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 15, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _close,
                      ),
                      Expanded(
                        child: Text(
                          _isTl ? 'Simulasyon' : 'Simulation',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 360;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 18 : 24,
                            vertical: 18,
                          ),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 430),
                            padding: EdgeInsets.all(compact ? 18 : 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: compact ? 64 : 72,
                                  height: compact ? 64 : 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [kBrandBlue, kBrandBlueDark],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kBrandBlue.withOpacity(0.25),
                                        blurRadius: 18,
                                        offset: const Offset(0, 9),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.electrical_services_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kBrandBlueSoft,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: kBrandBlue.withOpacity(0.16),
                                    ),
                                  ),
                                  child: Text(
                                    _isTl ? 'MODYUL 3' : 'MODULE 3',
                                    style: const TextStyle(
                                      color: kBrandBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF111827),
                                    fontSize: compact ? 21 : 24,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    height: 1.18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kBrandBlueDeep,
                                    fontSize: compact ? 13 : 14,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Poppins',
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: kBrandBlueSoft,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: kBrandBlue.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Text(
                                    _launchError ?? message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _launchError == null
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFD32F2F),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                if (_isUnityLaunching)
                                  const SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: kBrandBlue,
                                    ),
                                  )
                                else if (_launchError != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [kBrandBlue, kBrandBlueDark],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: _openSceneFlow,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: Text(
                                          retryText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
