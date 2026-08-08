import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../unity_launcher.dart';
import '../profile_progress_sync.dart';
import '../simulation_history_service.dart';
import '../module_progress_db.dart';
import '../widgets/app_notification.dart';

const Color kHouseOrange = Color(0xFFF97316);
const Color kHouseAmber = Color(0xFFF59E0B);

class SimulationScene2 extends StatefulWidget {
  const SimulationScene2({super.key});

  @override
  State<SimulationScene2> createState() => _SimulationScene2State();
}

class _SimulationScene2State extends State<SimulationScene2> {
  static const int _moduleNo = 2;
  static const String _unitySceneName = 'House_FireEscape';
  static const String _sceneLabel = 'Module 2 - Scene 2';

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  final SimulationHistoryService _simulationHistoryService =
      SimulationHistoryService();

  String? _moduleId;
  String? _simulationAttemptId;
  bool _simulationMarkedComplete = false;
  bool _isUnityLaunching = false;
  String? _launchError;

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

  Future<void> _persistUnityResult(
    UnityLaunchResult unityResult,
    Future<void> trackingFuture,
  ) async {
    try {
      await trackingFuture;
      await ProfileProgressSync.updateLastSimulation(_sceneLabel);

      if (unityResult.completed) {
        await _completeSimulationTracking();
        await ProfileProgressSync.syncCompletedSimulations();
      }
    } catch (e) {
      debugPrint('SIMULATION RESULT SAVE ERROR: $e');
    }
  }

  Future<void> _openSceneFlow() async {
    if (_isUnityLaunching) return;

    try {
      setState(() {
        _isUnityLaunching = true;
        _launchError = null;
      });

      final trackingFuture =
          _moduleId == null || _simulationAttemptId == null
              ? _startSimulationTracking()
              : Future<void>.value();

      final unityResult = await UnityLauncher.openScene(_unitySceneName);
      unawaited(_persistUnityResult(unityResult, trackingFuture));

      if (!mounted) return;
      setState(() => _isUnityLaunching = false);
      Navigator.of(context).pop(unityResult.completed);
    } on PlatformException catch (e) {
      if (!mounted) return;

      final message = _isTl
          ? 'Hindi mabuksan ang Unity: ${e.message ?? e.code}'
          : 'Failed to open Unity: ${e.message ?? e.code}';

      setState(() => _launchError = message);
      setState(() => _isUnityLaunching = false);

      showAppNotification(
        context,
        message: message,
        type: AppNotificationType.error,
        accentColor: kHouseOrange,
      );
    } catch (e) {
      if (!mounted) return;

      final message = _isTl
          ? 'Hindi ma-save ang progreso ng simulasyon: $e'
          : 'Failed to save simulation progress: $e';

      setState(() => _launchError = message);
      setState(() => _isUnityLaunching = false);

      showAppNotification(
        context,
        message: message,
        type: AppNotificationType.error,
        accentColor: kHouseOrange,
      );
    }
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isTl ? 'Binubuksan ang Eksena 2' : 'Opening Scene 2';
    final subtitle = _isTl
        ? 'Tutorial sa Ligtas na Paglikas sa Sunog sa Bahay'
        : 'House Fire Escape Tutorial';
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
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
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
                                    colors: [kHouseOrange, kHouseAmber],
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
                                  color: kHouseOrange.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _isTl ? 'MODYUL 2' : 'MODULE 2',
                                  style: const TextStyle(
                                    color: kHouseOrange,
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
                                  color: kHouseOrange,
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
                                      : kHouseOrange,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_isUnityLaunching) ...[
                                const CircularProgressIndicator(
                                  color: kHouseOrange,
                                ),
                              ] else if (_launchError != null) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [kHouseOrange, kHouseAmber],
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
