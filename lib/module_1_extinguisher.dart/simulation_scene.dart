// simulation_scene.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../module_progress_db.dart';
import '../profile_progress_sync.dart';
import '../simulation_history_service.dart';
import '../unity_launcher.dart';

class SimulationScene extends StatefulWidget {
  const SimulationScene({super.key});

  @override
  State<SimulationScene> createState() => _SimulationSceneState();
}

class _SimulationSceneState extends State<SimulationScene> {
  static const Color accent = Color(0xFFB11217);
  static const Color accent2 = Color(0xFF7A1014);
  static const int _moduleNo = 1;
  static const String _unitySceneName = 'FireExtinguisher_PASS';
  static const String _sceneLabel = 'Module 1 - Scene 1';

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      final message = _isTl
          ? 'Hindi ma-save ang progreso ng simulasyon: $e'
          : 'Failed to save simulation progress: $e';

      setState(() => _launchError = message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
        ? 'Binubuksan ang Eksena 1'
        : 'Opening Scene 1';
    final subtitle = _isTl
        ? 'PASS Method Tutorial'
        : 'PASS Method Tutorial';
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

                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(
                            horizontal: compact ? 18 : 24,
                          ),
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
                                width: compact ? 60 : 68,
                                height: compact ? 60 : 68,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [accent, accent2],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.sports_esports_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _isTl ? 'MODYUL 1' : 'MODULE 1',
                                  style: const TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF111827),
                                  fontSize: compact ? 19 : 21,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _launchError ?? message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _launchError == null
                                      ? const Color(0xFF4B5563)
                                      : accent,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_isUnityLaunching) ...[
                                const CircularProgressIndicator(
                                  color: accent,
                                ),
                              ] else if (_launchError != null) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [accent, accent2],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: _openSceneFlow,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 22,
                                      ),
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
                            ],
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
