import 'dart:ui';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'app_content_refresh.dart';
import 'localization/app_text.dart';
import 'widgets/app_notification.dart';
import 'widgets/main_tab_header.dart';
import 'module_progress_refresh_notifier.dart';
import 'profile_refresh_notifier.dart';
import 'module_progress_overview_service.dart';

import 'module_1_extinguisher.dart/pre_assess_instruction.dart' as pre1;
import 'module_1_extinguisher.dart/module_1_learningmaterials.dart';
import 'module_1_extinguisher.dart/simulation_scene.dart';
import 'module_2_house.dart/pre_assess_instruction.dart' as pre2;
import 'module_2_house.dart/module_2_learningmaterials.dart' as house_lm;
import 'module_5_building.dart/module_5_learningmaterials.dart' as building_lm;
import 'module_4_kitchen.dart/module_4_learningmaterials.dart' as kitchen_lm;
import 'module_3_electrical.dart/module_3_learningmaterials.dart'
    as electrical_lm;
import 'module_2_house.dart/simulation_scene_house.dart' as house_sim;
import 'module_3_electrical.dart/simulation_scene_electrical.dart'
    as electrical_sim;
import 'module_4_kitchen.dart/simulation_scene.dart' as kitchen_sim;
import 'module_5_building.dart/simulation_scene.dart' as building_sim;

import 'module_2_house.dart/post_assess_instruction_house.dart' as house_post;
import 'module_3_electrical.dart/pre_assess_instruction.dart' as pre3;
import 'module_4_kitchen.dart/pre_assess_instruction.dart' as pre4;
import 'module_4_kitchen.dart/post_assessment_kitchen.dart' as kitchen_post;
import 'module_5_building.dart/pre_assess_instruction.dart' as pre5;
import 'module_5_building.dart/post_assessment_building.dart' as building_post;
import 'module_1_extinguisher.dart/post_assess_instruction.dart' as post1;
import 'module_1_extinguisher.dart/module_progression_service.dart';
import 'module_3_electrical.dart/post_assess_instruction.dart' as post3;
import 'module_4_kitchen.dart/post_assess_instruction.dart' as post4;
import 'module_5_building.dart/post_assess_instruction.dart' as post5;

/// Index of the Profile tab within [IgnisHomePage]'s tab list
/// (Module = 0, About Us = 1, Profile = 2).
const int _profileTabIndex = 2;
const double _learningHeaderExtent = 290;
const double _compactLearningHeaderExtent = 310;

class _NoOverscrollScrollBehavior extends ScrollBehavior {
  const _NoOverscrollScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ModuleProgressSnapshot {
  const _ModuleProgressSnapshot({
    required this.loading,
    required this.loaded,
    required this.preTestCompleted,
    required this.canOpenLearning,
    required this.learningCompleted,
    required this.canOpenPostTest,
    required this.postTestCompleted,
    this.error,
  });

  const _ModuleProgressSnapshot.initial()
    : loading = true,
      loaded = false,
      preTestCompleted = false,
      canOpenLearning = false,
      learningCompleted = false,
      canOpenPostTest = false,
      postTestCompleted = false,
      error = null;

  final bool loading;
  final bool loaded;
  final bool preTestCompleted;
  final bool canOpenLearning;
  final bool learningCompleted;
  final bool canOpenPostTest;
  final bool postTestCompleted;
  final String? error;

  _ModuleProgressSnapshot copyWith({
    bool? loading,
    bool? loaded,
    bool? preTestCompleted,
    bool? canOpenLearning,
    bool? learningCompleted,
    bool? canOpenPostTest,
    bool? postTestCompleted,
    String? error,
    bool clearError = false,
  }) {
    return _ModuleProgressSnapshot(
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      preTestCompleted: preTestCompleted ?? this.preTestCompleted,
      canOpenLearning: canOpenLearning ?? this.canOpenLearning,
      learningCompleted: learningCompleted ?? this.learningCompleted,
      canOpenPostTest: canOpenPostTest ?? this.canOpenPostTest,
      postTestCompleted: postTestCompleted ?? this.postTestCompleted,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class LearningMaterialsTab extends StatefulWidget {
  const LearningMaterialsTab({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<LearningMaterialsTab> createState() => _LearningMaterialsTabState();
}

class _LearningMaterialsTabState extends State<LearningMaterialsTab> {
  final _client = Supabase.instance.client;

  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;
  bool _loading = true;
  String? _error;
  List<LearningMaterial> _modules = [];
  RealtimeChannel? _channel;
  Timer? _progressRefreshDebounce;
  Future<void>? _progressRefreshInFlight;
  DateTime? _progressLoadedAt;
  int? _expandedModuleNo;
  String? _selectedModuleActionKey;
  bool _openingModuleOneSimulation = false;
  bool _openingModuleTwoSimulation = false;
  bool _openingModuleThreeSimulation = false;
  bool _openingModuleFourSimulation = false;
  bool _openingModuleFiveSimulation = false;

  /// Module 4 (Kitchen Fire) only: see [_reconcileModuleFourProgress].
  static const int _kitchenModuleNo = 4;
  bool _moduleFourReconcileSettled = false;

  final Set<int> _trackedProgressModules = const <int>{1, 2, 3, 4, 5};
  final Map<int, _ModuleProgressSnapshot> _progressByModule = {
    for (final moduleNo in const <int>[1, 2, 3, 4, 5])
      moduleNo: const _ModuleProgressSnapshot.initial(),
  };

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  @override
  void initState() {
    super.initState();
    profileRefreshNotifier.addListener(_handleProfileChanged);
    moduleProgressRefreshNotifier.addListener(_handleModuleProgressChanged);
    AppContentRefreshRegistry.register(this, _handleAppContentRefresh);
    _loadProfile();
    _loadModules();
    _loadAllTrackedProgress();
    _listenRealtime();
  }

  @override
  void dispose() {
    profileRefreshNotifier.removeListener(_handleProfileChanged);
    moduleProgressRefreshNotifier.removeListener(_handleModuleProgressChanged);
    AppContentRefreshRegistry.unregister(this);
    _progressRefreshDebounce?.cancel();
    final c = _channel;
    if (c != null) _client.removeChannel(c);
    super.dispose();
  }

  void _handleProfileChanged() => _loadProfile();

  /// Re-reads the learner's saved module progress after another screen wrote
  /// it — notably when a finished Pre-Assessment is confirmed saved on the
  /// Score Result screen — so the pre-test shows as completed and the
  /// Learning Materials unlock without waiting for a manual refresh.
  void _handleModuleProgressChanged() {
    _refreshProgressAfterExternalWrite();
  }

  /// Always ends with a read that *started* after the write that triggered it,
  /// so a refresh already in flight when the write landed cannot leave the tab
  /// showing the pre-write state.
  Future<void> _refreshProgressAfterExternalWrite() async {
    if (!mounted) return;

    final inFlight = _progressRefreshInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // Surfaced by the refresh itself; a fresh read follows either way.
      }
      if (!mounted) return;
    }

    await _loadAllTrackedProgress();
  }

  /// Backs the header menu's "Refresh & Check Updates" action for this tab:
  /// re-reads the module list, the learner's progress and the header profile
  /// straight from Supabase and applies them to the live UI.
  Future<void> _handleAppContentRefresh() async {
    await Future.wait([
      _loadProfile(),
      _loadModules(),
      _loadAllTrackedProgress(),
    ]);

    final error = _error;
    if (error != null) throw Exception(error);
  }

  Future<void> _loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
          .from('profiles')
          .select('first_name, last_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || data == null) return;
      AppContentRefreshRegistry.reportContent(this, 'profile', data);
      setState(() {
        _firstName = (data['first_name'] ?? '').toString();
        _lastName = (data['last_name'] ?? '').toString();
        _avatarUrl = data['avatar_url'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _loadModules() async {
    try {
      if (mounted && _modules.isEmpty) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final rows = await _client
          .from('learning_material_mobile_view')
          .select()
          .order('module_no', ascending: true);

      final modules = (rows as List)
          .map((e) => LearningMaterial.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      AppContentRefreshRegistry.reportContent(this, 'modules', rows);
      setState(() {
        _modules = modules;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshModulesAndProgress() async {
    await Future.wait([_loadModules(), _loadAllTrackedProgress()]);
  }

  void _listenRealtime() {
    _channel = _client
        .channel('learning_materials_mobile_list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_materials',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_pages',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_blocks',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_media_assets',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'module_progress',
          callback: (_) => _scheduleProgressRefresh(),
        )
        .subscribe();
  }

  void _scheduleProgressRefresh() {
    _progressRefreshDebounce?.cancel();
    _progressRefreshDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadAllTrackedProgress(),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_tab_index');
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openModule(int moduleNo) async {
    if (_isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo);
      if (!mounted) return;
      if (_isModuleActionLocked(moduleNo, 'learning_materials')) {
        await _showLockedNotice('learning_materials', moduleNo: moduleNo);
        return;
      }
    }

    Widget page;

    switch (moduleNo) {
      case 1:
        page = const LearningMaterialExtinguisherPage();
        break;
      case 2:
        page = house_lm.LearningMaterialHousePage();
        break;
      case 3:
        page = const electrical_lm.LearningMaterialElectricalPage();
        break;
      case 4:
        page = const kitchen_lm.LearningMaterialKitchenPage();
        break;
      case 5:
        page = const building_lm.LearningMaterialTenementPage();
        break;

      default:
        page = DatabaseLearningMaterialPage(moduleNo: moduleNo);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    if (mounted && _isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo, force: true);
    }
  }

  String _t(String en, String tl) => _isTl && tl.trim().isNotEmpty ? tl : en;

  _ModuleProgressSnapshot _progressFor(int moduleNo) {
    return _progressByModule[moduleNo] ??
        const _ModuleProgressSnapshot.initial();
  }

  Future<void> _loadAllTrackedProgress() async {
    final activeRefresh = _progressRefreshInFlight;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresh = _performProgressRefresh();
    _progressRefreshInFlight = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_progressRefreshInFlight, refresh)) {
        _progressRefreshInFlight = null;
      }
    }
  }

  Future<void> _loadProgressForTrackedModule(
    int moduleNo, {
    bool force = false,
  }) async {
    if (!_isTrackedProgressModule(moduleNo)) return;

    final loadedAt = _progressLoadedAt;
    if (!force &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(seconds: 20)) {
      return;
    }

    await _loadAllTrackedProgress();
  }

  Future<void> _performProgressRefresh() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        for (final moduleNo in _trackedProgressModules) {
          _progressByModule[moduleNo] = const _ModuleProgressSnapshot(
            loading: false,
            loaded: true,
            preTestCompleted: false,
            canOpenLearning: false,
            learningCompleted: false,
            canOpenPostTest: false,
            postTestCompleted: false,
            error: 'Please log in again to continue.',
          );
        }
      });
      return;
    }

    try {
      var overview = await ModuleProgressOverviewService(
        client: _client,
      ).load();

      if (await _reconcileModuleFourProgress(overview)) {
        overview = await ModuleProgressOverviewService(client: _client).load();
      }

      if (!mounted) return;
      // Reported as keyed maps (never positional lists) because the
      // fingerprint canonicaliser sorts list items.
      AppContentRefreshRegistry.reportContent(this, 'module_progress', {
        for (final entry in overview.entries)
          '${entry.key}': <String, bool>{
            'pre_test_completed': entry.value.preTestCompleted,
            'can_open_learning': entry.value.canOpenLearning,
            'learning_completed': entry.value.learningCompleted,
            'can_open_post_test': entry.value.canOpenPostTest,
            'post_test_completed': entry.value.postTestCompleted,
          },
      });
      setState(() {
        for (final moduleNo in _trackedProgressModules) {
          final progress = overview[moduleNo];
          _progressByModule[moduleNo] = _ModuleProgressSnapshot(
            loading: false,
            loaded: true,
            preTestCompleted: progress?.preTestCompleted ?? false,
            canOpenLearning: progress?.canOpenLearning ?? false,
            learningCompleted: progress?.learningCompleted ?? false,
            canOpenPostTest: progress?.canOpenPostTest ?? false,
            postTestCompleted: progress?.postTestCompleted ?? false,
          );
        }
        _progressLoadedAt = DateTime.now();
      });
    } catch (e) {
      debugPrint('LOAD MODULE PROGRESS OVERVIEW ERROR: $e');
      if (!mounted) return;
      setState(() {
        for (final moduleNo in _trackedProgressModules) {
          final current = _progressFor(moduleNo);
          _progressByModule[moduleNo] = current.copyWith(
            loading: false,
            loaded: true,
            error: e.toString().replaceFirst('Exception: ', ''),
          );
        }
      });
    }
  }

  /// Heals a Module 4 progress row that records a finished Pre-Assessment but
  /// is missing the attempt id / score the unlock check validates against, so
  /// the Learning Module opens without a restart or manual refresh.
  ///
  /// Everything is rebuilt from the learner's real submitted attempt by
  /// [ModuleProgressionService]; nothing about the completion is assumed here.
  /// Returns true when the row was rewritten and the overview must be re-read.
  Future<bool> _reconcileModuleFourProgress(
    Map<int, ModuleProgressOverview> overview,
  ) async {
    if (_moduleFourReconcileSettled) return false;

    final progress = overview[_kitchenModuleNo];
    if (progress == null) return false;
    if (!progress.preTestCompleted || progress.canOpenLearning) return false;

    try {
      final state = await ModuleProgressionService(
        client: _client,
      ).getState(moduleNo: _kitchenModuleNo);
      if (state.hasValidPreTest) return true;
    } catch (e) {
      debugPrint('RECONCILE MODULE $_kitchenModuleNo PROGRESS ERROR: $e');
    }

    // Nothing left to recover from: a new submission now saves the full
    // pre-test result, so retrying on every refresh would only add queries.
    _moduleFourReconcileSettled = true;
    return false;
  }

  bool _isTrackedProgressModule(int moduleNo) {
    return _trackedProgressModules.contains(moduleNo);
  }

  bool _progressLoadingFor(int moduleNo) {
    if (!_isTrackedProgressModule(moduleNo)) return false;
    final progress = _progressFor(moduleNo);
    return progress.loading || !progress.loaded;
  }

  String? _progressErrorFor(int moduleNo) {
    if (!_isTrackedProgressModule(moduleNo)) return null;
    return _progressFor(moduleNo).error;
  }

  bool _preTestCompletedFor(int moduleNo) {
    if (!_isTrackedProgressModule(moduleNo)) return false;
    return _progressFor(moduleNo).preTestCompleted;
  }

  bool _canOpenLearningFor(int moduleNo) {
    if (!_isTrackedProgressModule(moduleNo)) return true;
    return _progressFor(moduleNo).canOpenLearning;
  }

  bool _canOpenPostTestFor(int moduleNo) {
    if (!_isTrackedProgressModule(moduleNo)) return true;
    return _progressFor(moduleNo).canOpenPostTest;
  }

  bool _postTestCompletedFor(int moduleNo) {
    if (!_isTrackedProgressModule(moduleNo)) return false;
    return _progressFor(moduleNo).postTestCompleted;
  }

  bool _isModuleActionLocked(int moduleNo, String actionKey) {
    if (!_isTrackedProgressModule(moduleNo)) return false;
    if (actionKey == 'simulation') return false;
    if (actionKey != 'pre_test' &&
        actionKey != 'learning_materials' &&
        actionKey != 'post_test') {
      return false;
    }

    if (_progressLoadingFor(moduleNo)) return true;
    if (_progressErrorFor(moduleNo) != null) return true;

    if (actionKey == 'pre_test') {
      return _preTestCompletedFor(moduleNo);
    }
    if (actionKey == 'learning_materials') {
      return !_canOpenLearningFor(moduleNo);
    }
    if (actionKey == 'post_test') {
      return !_canOpenPostTestFor(moduleNo);
    }
    return false;
  }

  String _lockedMessageFor(int moduleNo, String actionKey) {
    if (_progressLoadingFor(moduleNo)) {
      return _t(
        'Checking your saved progress. Please try again in a moment.',
        'Sinusuri pa ang naka-save mong progress. Subukan muli pagkaraan ng ilang sandali.',
      );
    }

    if (_progressErrorFor(moduleNo) != null) {
      return _progressErrorFor(moduleNo)!;
    }

    if (actionKey == 'pre_test') {
      return _t(
        'The Pre-Assessment can only be taken once. You can now continue to the Learning Module.',
        'Isang beses lang maaaring kunin ang Paunang Pagsusulit. Maaari ka nang magpatuloy sa Modyul sa Pag-aaral.',
      );
    }
    if (actionKey == 'learning_materials') {
      return _t(
        'Complete the Pre-Assessment first to unlock it.',
        'Tapusin muna ang Paunang Pagsusulit upang mabuksan ito.',
      );
    }
    if (actionKey == 'post_test') {
      if (_postTestCompletedFor(moduleNo)) {
        return _t(
          'The Post-Assessment can only be taken once. You can review the Learning Module.',
          'Isang beses lang maaaring kunin ang Panghuling Pagsusulit. Maaari mong balikan ang Modyul sa Pag-aaral.',
        );
      }
      return _t(
        'Complete the Learning Module first to unlock it.',
        'Tapusin muna ang Modyul sa Pag-aaral upang mabuksan ito.',
      );
    }
    return _t('This section is locked.', 'Naka-lock pa ang bahaging ito.');
  }

  String? _lockedSubtitleFor(int moduleNo, String actionKey) {
    if (!_isModuleActionLocked(moduleNo, actionKey)) return null;

    if (_isTrackedProgressModule(moduleNo) && _progressLoadingFor(moduleNo)) {
      return _t(
        'Checking saved progress...',
        'Sinusuri ang naka-save na progress...',
      );
    }

    if (_isTrackedProgressModule(moduleNo) && actionKey == 'pre_test') {
      return _t(
        'You can only take the Pre-Assessment once.',
        'Isang beses lang maaaring kunin ang Paunang Pagsusulit.',
      );
    }

    if (_isTrackedProgressModule(moduleNo) &&
        actionKey == 'learning_materials') {
      return _t(
        'Complete the Pre-Assessment first to unlock it.',
        'Tapusin muna ang Paunang Pagsusulit upang mabuksan ito.',
      );
    }

    if (_isTrackedProgressModule(moduleNo) && actionKey == 'post_test') {
      if (_postTestCompletedFor(moduleNo)) {
        return _t(
          'You can only take the Post-Assessment once.',
          'Isang beses lang maaaring kunin ang Panghuling Pagsusulit.',
        );
      }
      return _t(
        'Complete the Learning Module first to unlock it.',
        'Tapusin muna ang Modyul sa Pag-aaral upang mabuksan ito.',
      );
    }

    return _t('Locked', 'Naka-lock');
  }

  String _lockedTitleFor(String actionKey) {
    if (actionKey == 'pre_test') {
      return _t('Pre-Assessment Locked', 'Naka-lock ang Paunang Pagsusulit');
    }
    if (actionKey == 'learning_materials') {
      return _t('Learning Module Locked', 'Naka-lock ang Modyul sa Pag-aaral');
    }
    if (actionKey == 'post_test') {
      return _t(
        'Post-Assessment Locked',
        'Naka-lock ang Panghuling Pagsusulit',
      );
    }
    return _t('Locked', 'Naka-lock');
  }

  Future<void> _showLockedNotice(String actionKey, {int moduleNo = 1}) async {
    if (!mounted) return;

    final title = _lockedTitleFor(actionKey);
    final message = _lockedMessageFor(moduleNo, actionKey);
    final accent = _moduleAccent(moduleNo);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final compact = MediaQuery.of(dialogContext).size.width < 360;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 22,
                  compact ? 22 : 26,
                  compact ? 18 : 22,
                  compact ? 18 : 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 52 : 58,
                      height: compact ? 52 : 58,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: accent,
                        size: compact ? 28 : 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF111827),
                        fontSize: compact ? 17 : 19,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.45,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          _t('OK', 'OK'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF6B7280),
                  tooltip: _t('Close', 'Isara'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleModule(int moduleNo) {
    setState(() {
      _expandedModuleNo = _expandedModuleNo == moduleNo ? null : moduleNo;
    });
  }

  Future<void> _handleModuleAction(int moduleNo, String actionKey) async {
    setState(() {
      _expandedModuleNo = moduleNo;
    });

    if (_isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo);
      if (!mounted) return;

      if (_isModuleActionLocked(moduleNo, actionKey)) {
        setState(() => _selectedModuleActionKey = null);
        await _showLockedNotice(actionKey, moduleNo: moduleNo);
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedModuleActionKey = '$moduleNo:$actionKey';
    });

    switch (actionKey) {
      case 'pre_test':
        await _openPreAssessment(moduleNo);
        return;
      case 'learning_materials':
        await _openModule(moduleNo);
        return;
      case 'post_test':
        await _openPostAssessment(moduleNo);
        return;
      case 'simulation':
        _showModuleSimulationDialog(moduleNo);
        return;
      default:
        return;
    }
  }

  Future<void> _showModuleSimulationDialog(int moduleNo) async {
    if (moduleNo != 1 &&
        moduleNo != 2 &&
        moduleNo != 3 &&
        moduleNo != 4 &&
        moduleNo != 5) {
      _showActionNotice(_t('3D Simulation', '3D Simulasyon'));
      return;
    }

    if (!mounted) return;

    String barrierLabel;
    Widget Function(BuildContext dialogContext) dialogBuilder;

    switch (moduleNo) {
      case 2:
        barrierLabel = 'house_fire_escape_tutorial';
        dialogBuilder = (dialogContext) => _HouseFireEscapeSimulationDialog(
          isTl: _isTl,
          accent: _moduleAccent(2),
          accent2: _moduleAccent2(2),
          onClose: () => Navigator.pop(dialogContext),
          onStart: () {
            Navigator.pop(dialogContext);
            Future.microtask(() {
              if (mounted) {
                _openModuleTwoSimulation();
              }
            });
          },
        );
        break;

      case 3:
        barrierLabel = 'electrical_fire_safety_tutorial';
        dialogBuilder = (dialogContext) => _ElectricalFireSimulationDialog(
          isTl: _isTl,
          accent: _moduleAccent(3),
          accent2: _moduleAccent2(3),
          onClose: () => Navigator.pop(dialogContext),
          onStart: () {
            Navigator.pop(dialogContext);
            Future.microtask(() {
              if (mounted) {
                _openModuleThreeSimulation();
              }
            });
          },
        );
        break;

      case 4:
        barrierLabel = 'kitchen_fire_safety_tutorial';
        dialogBuilder = (dialogContext) => _KitchenFireSimulationDialog(
          isTl: _isTl,
          accent: _moduleAccent(4),
          accent2: _moduleAccent2(4),
          onClose: () => Navigator.pop(dialogContext),
          onStart: () {
            Navigator.pop(dialogContext);
            Future.microtask(() {
              if (mounted) {
                _openModuleFourSimulation();
              }
            });
          },
        );
        break;

      case 5:
        barrierLabel = 'tenement_fire_evacuation_tutorial';
        dialogBuilder = (dialogContext) => _TenementFireSimulationDialog(
          isTl: _isTl,
          accent: _moduleAccent(5),
          accent2: _moduleAccent2(5),
          onClose: () => Navigator.pop(dialogContext),
          onStart: () {
            Navigator.pop(dialogContext);
            Future.microtask(() {
              if (mounted) {
                _openModuleFiveSimulation();
              }
            });
          },
        );
        break;

      default:
        barrierLabel = 'pass_method_tutorial';
        dialogBuilder = (dialogContext) => _PassMethodSimulationDialog(
          isTl: _isTl,
          accent: _moduleAccent(1),
          accent2: _moduleAccent2(1),
          onClose: () => Navigator.pop(dialogContext),
          onStart: () {
            Navigator.pop(dialogContext);
            Future.microtask(() {
              if (mounted) {
                _openModuleOneSimulation();
              }
            });
          },
        );
    }

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: barrierLabel,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.42),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
              Center(child: dialogBuilder(dialogContext)),
            ],
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openModuleOneSimulation() async {
    if (!mounted || _openingModuleOneSimulation) return;

    setState(() => _openingModuleOneSimulation = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SimulationScene()),
      );
    } finally {
      if (mounted) {
        setState(() => _openingModuleOneSimulation = false);
      } else {
        _openingModuleOneSimulation = false;
      }
    }
  }

  Future<void> _openModuleTwoSimulation() async {
    if (!mounted || _openingModuleTwoSimulation) return;

    setState(() => _openingModuleTwoSimulation = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const house_sim.SimulationScene2()),
      );
    } finally {
      if (mounted) {
        setState(() => _openingModuleTwoSimulation = false);
      } else {
        _openingModuleTwoSimulation = false;
      }
    }
  }

  Future<void> _openModuleThreeSimulation() async {
    if (!mounted || _openingModuleThreeSimulation) return;

    setState(() => _openingModuleThreeSimulation = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const electrical_sim.SimulationScene3(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingModuleThreeSimulation = false);
      } else {
        _openingModuleThreeSimulation = false;
      }
    }
  }

  Future<void> _openModuleFourSimulation() async {
    if (!mounted || _openingModuleFourSimulation) return;

    setState(() => _openingModuleFourSimulation = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const kitchen_sim.SimulationScene4()),
      );
    } finally {
      if (mounted) {
        setState(() => _openingModuleFourSimulation = false);
      } else {
        _openingModuleFourSimulation = false;
      }
    }
  }

  Future<void> _openModuleFiveSimulation() async {
    if (!mounted || _openingModuleFiveSimulation) return;

    setState(() => _openingModuleFiveSimulation = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const building_sim.SimulationScene5(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingModuleFiveSimulation = false);
      } else {
        _openingModuleFiveSimulation = false;
      }
    }
  }

  Future<void> _openPreAssessment(int moduleNo) async {
    if (_isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo);
      if (!mounted) return;
      if (_isModuleActionLocked(moduleNo, 'pre_test')) {
        await _showLockedNotice('pre_test', moduleNo: moduleNo);
        return;
      }
    }

    Widget page;

    switch (moduleNo) {
      case 1:
        page = const pre1.PreAssessmentIntroPage();
        break;
      case 2:
        page = const pre2.PreAssessmentIntroPage2();
        break;
      case 3:
        page = const pre3.PreAssessmentIntroPage2();
        break;
      case 4:
        page = const pre4.PreAssessmentIntroPage2();
        break;
      case 5:
        page = const pre5.PreAssessmentIntroPage2();
        break;
      default:
        _showActionNotice(
          _t(
            'This module is not available yet.',
            'Hindi pa available ang modyul na ito.',
          ),
        );
        return;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    if (mounted && _isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo, force: true);
    }
  }

  Future<void> _openPostAssessment(int moduleNo) async {
    if (_isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo);
      if (!mounted) return;
      if (_isModuleActionLocked(moduleNo, 'post_test')) {
        await _showLockedNotice('post_test', moduleNo: moduleNo);
        return;
      }
    }

    Widget page;

    switch (moduleNo) {
      case 1:
        page = const post1.PostAssessmentIntroPage();
        break;
      case 2:
        page = const house_post.PostAssessmentIntroPage();
        break;
      case 3:
        page = const post3.PostAssessmentIntroPage();
        break;
      case 4:
        page = const post4.PostAssessmentIntroPage2();
        break;
      case 5:
        page = const post5.PostAssessmentIntroPage();
        break;
      default:
        _showActionNotice(
          _t(
            'This module is not available yet.',
            'Hindi pa available ang modyul na ito.',
          ),
        );
        return;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    if (mounted && _isTrackedProgressModule(moduleNo)) {
      await _loadProgressForTrackedModule(moduleNo, force: true);
    }
  }

  void _showActionNotice(String sectionName) {
    showAppNotification(
      context,
      message: _t(
        '$sectionName is shown here for the module menu. Connect its existing route when the page is ready.',
        '$sectionName ay ipinapakita rito para sa module menu. Ikonekta ang existing route kapag handa na ang page.',
      ),
      type: AppNotificationType.info,
      accentColor: const Color(0xFFB11217),
    );
  }

  ImageProvider? _buildAvatarProvider() {
    if (_avatarUrl == null || _avatarUrl!.trim().isEmpty) return null;

    if (_avatarUrl!.startsWith('http')) {
      return NetworkImage(_avatarUrl!);
    }

    return AssetImage(_avatarUrl!);
  }

  Widget _buildModuleProgressCard() {
    final moduleNumbers = _trackedProgressModules.toList()..sort();
    final completedCount = moduleNumbers
        .where((moduleNo) => _postTestCompletedFor(moduleNo))
        .length;
    final isLoading = moduleNumbers.any(_progressLoadingFor);
    final hasError = moduleNumbers.any(
      (moduleNo) => _progressErrorFor(moduleNo) != null,
    );
    final progress = completedCount / moduleNumbers.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loadAllTrackedProgress,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFFB11217),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Module Progress', 'Progreso ng Modyul'),
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasError
                              ? _t(
                                  'Tap to refresh saved progress',
                                  'I-tap para i-refresh ang naka-save na progreso',
                                )
                              : _t(
                                  '$completedCount of ${moduleNumbers.length} modules completed',
                                  '$completedCount sa ${moduleNumbers.length} modyul ang natapos',
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasError
                                ? const Color(0xFFB11217)
                                : const Color(0xFF717784),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isLoading)
                    const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFFB11217),
                      ),
                    )
                  else
                    Text(
                      '$completedCount/${moduleNumbers.length}',
                      style: const TextStyle(
                        color: Color(0xFFB11217),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF3E7E5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFB11217),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _buildAvatarProvider();
    final headerExtent = MediaQuery.sizeOf(context).width < 370
        ? _compactLearningHeaderExtent
        : _learningHeaderExtent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactWidth = constraints.maxWidth < 370;
                final horizontalPadding = compactWidth ? 16.0 : 22.0;

                // Mirrors FloatingNavBar's own responsive height (navbar.dart)
                // so the list clears the glass nav bar without leaving a
                // fixed, oversized gap below the last card on taller screens.
                final navBarHeight = (constraints.maxWidth * 0.18)
                    .clamp(54.0, 64.0)
                    .clamp(0.0, 62.0);
                const navBarBottomGap = 14.0;
                final breathingRoom = (MediaQuery.sizeOf(context).height * 0.02)
                    .clamp(14.0, 24.0);
                final bottomInset = MediaQuery.paddingOf(context).bottom +
                    navBarHeight +
                    navBarBottomGap +
                    breathingRoom;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildList(
                    _modules,
                    topInset: headerExtent + 12,
                    bottomInset: bottomInset,
                  ),
                );
              },
            ),
          ),
          MainTabHeaderBackdrop(height: headerExtent),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactWidth = constraints.maxWidth < 370;
                final horizontalPadding = compactWidth ? 16.0 : 22.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MainTabHeader(
                        greeting: _firstName.isEmpty && _lastName.isEmpty
                            ? context.tr('hi')
                            : context.tr(
                                'hi_name',
                                params: {
                                  'name': '$_firstName $_lastName'.trim(),
                                },
                              ),
                        accountLabel: context.tr('welcome_to_ignis_safe_short'),
                        title: context.tr('learning_materials'),
                        subtitle: _isTl
                            ? 'Matuto, magsanay nang ligtas, at laging maging handa.'
                            : 'Build knowledge, practice safely, and stay prepared.',
                        titleIcon: Icons.menu_book_rounded,
                        avatarImage: avatarProvider,
                        profileLabel: context.tr('profile'),
                        refreshLabel: context.tr('refresh_and_check_updates'),
                        logoutLabel: context.tr('log_out'),
                        onProfile: () =>
                            widget.onRequestTabChange?.call(_profileTabIndex),
                        onLogout: _logout,
                      ),
                      const SizedBox(height: 16),
                      _buildModuleProgressCard(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<LearningMaterial> items, {
    double topInset = 0,
    double bottomInset = 12,
  }) {
    if (_loading) {
      return ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, topInset, 0, bottomInset),
        children: const [
          SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFB11217)),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, topInset, 0, bottomInset),
        children: [
          _MessageCard(
            icon: Icons.error_outline_rounded,
            title: _isTl
                ? 'Hindi ma-load ang learning materials'
                : 'Cannot load learning materials',
            message: _error!,
            buttonText: _isTl ? 'Subukan muli' : 'Retry',
            color: const Color(0xFFB11217),
            onPressed: _loadModules,
          ),
        ],
      );
    }

    final hasItems = items.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _refreshModulesAndProgress,
      color: const Color(0xFFB11217),
      child: ScrollConfiguration(
        behavior: const _NoOverscrollScrollBehavior(),
        child: ListView.separated(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, topInset, 0, bottomInset),
          clipBehavior: Clip.hardEdge,
          itemCount: hasItems ? items.length : 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            if (!hasItems) {
              return _MessageCard(
                icon: Icons.menu_book_outlined,
                title: _isTl
                    ? 'Wala pang learning materials'
                    : 'No learning materials yet',
                message: _isTl
                    ? 'Bumalik muli sa ibang pagkakataon o i-refresh ang pahina.'
                    : 'Check again later or refresh the page.',
                buttonText: _isTl ? 'I-refresh' : 'Refresh',
                color: const Color(0xFFB11217),
                onPressed: _refreshModulesAndProgress,
              );
            }

            final m = items[index];
            return _ModuleCard(
              moduleNo: m.moduleNo,
              moduleLabel: m.moduleLabel(_isTl),
              title: m.title(_isTl),
              description: m.subtitle(_isTl),
              image: m.heroImage,
              isTl: _isTl,
              isCompleted: _postTestCompletedFor(m.moduleNo),
              isExpanded: _expandedModuleNo == m.moduleNo,
              selectedActionKey: _selectedModuleActionKey,
              isActionLocked: (actionKey) =>
                  _isModuleActionLocked(m.moduleNo, actionKey),
              lockedSubtitle: (actionKey) =>
                  _lockedSubtitleFor(m.moduleNo, actionKey),
              onHeaderTap: () => _toggleModule(m.moduleNo),
              onChildTap: (actionKey) {
                _handleModuleAction(m.moduleNo, actionKey);
              },
            );
          },
        ),
      ),
    );
  }
}

class DatabaseLearningMaterialPage extends StatefulWidget {
  const DatabaseLearningMaterialPage({super.key, required this.moduleNo});

  final int moduleNo;

  @override
  State<DatabaseLearningMaterialPage> createState() =>
      _DatabaseLearningMaterialPageState();
}

class _DatabaseLearningMaterialPageState
    extends State<DatabaseLearningMaterialPage> {
  final _client = Supabase.instance.client;
  final _scroll = ScrollController();

  LearningMaterial? _material;
  List<FireClassGuide> _fireGuides = [];
  bool _loading = true;
  String? _error;
  int _pageIndex = 0;
  double _progress = 0;
  bool _canNext = false;
  final Set<int> _introDialogsShown = <int>{};
  final Set<String> _completionDialogsShown = <String>{};
  bool _dialogOpen = false;
  RealtimeChannel? _channel;

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';
  Color get _accent => _moduleAccent(widget.moduleNo);
  Color get _accent2 => _moduleAccent2(widget.moduleNo);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMaterial();
    _listenRealtime();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    final c = _channel;
    if (c != null) _client.removeChannel(c);
    super.dispose();
  }

  Future<void> _loadMaterial() async {
    try {
      if (mounted && _material == null) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final row = await _client
          .from('learning_material_mobile_view')
          .select()
          .eq('module_no', widget.moduleNo)
          .maybeSingle();

      if (row == null) {
        throw Exception(
          'Module ${widget.moduleNo} has no learning material row.',
        );
      }

      final material = LearningMaterial.fromMap(Map<String, dynamic>.from(row));
      List<FireClassGuide> guides = [];

      if (widget.moduleNo == 1) {
        final rows = await _client
            .from('learning_material_fire_class_guides')
            .select()
            .eq('module_no', 1)
            .eq('is_active', true)
            .order('display_order', ascending: true);

        guides = (rows as List)
            .map((e) => FireClassGuide.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _material = material;
        _fireGuides = guides;
        _loading = false;
        _error = null;
        if (_pageIndex >= material.pages.length) {
          _pageIndex = material.pages.isEmpty ? 0 : material.pages.length - 1;
        }
      });
      _scheduleIntroDialog(material);
      _resetScroll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _listenRealtime() {
    _channel = _client
        .channel('learning_material_${widget.moduleNo}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_materials',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_pages',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_blocks',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_media_assets',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_fire_class_guides',
          callback: (_) => _loadMaterial(),
        )
        .subscribe();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final off = _scroll.offset;

    if (max <= 0) {
      if (_progress != 1 || !_canNext) {
        setState(() {
          _progress = 1;
          _canNext = true;
        });
      }
      _maybeShowCompletionDialog();
      return;
    }

    final p = (off / max).clamp(0.0, 1.0).toDouble();
    final nearBottom = off >= max - 8;
    if (_progress != p || _canNext != nearBottom) {
      setState(() {
        _progress = p;
        _canNext = nearBottom;
      });
    }

    if (nearBottom) {
      _maybeShowCompletionDialog();
    }
  }

  void _scheduleIntroDialog(LearningMaterial material) {
    if (_introDialogsShown.contains(material.moduleNo)) return;
    _introDialogsShown.add(material.moduleNo);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showLearningDialog(
        icon: Icons.menu_book_rounded,
        title: _t('Before you continue', 'Bago ka magpatuloy'),
        message: _t(
          'Please read each section carefully. These materials will help you prepare for the assessment and 3D simulation.',
          'Basahin nang mabuti ang bawat bahagi. Makakatulong ang mga materyal na ito sa paghahanda mo para sa pagsusulit at 3D simulation.',
        ),
        buttonText: _t('Got it', 'Naiintindihan ko'),
      );
      if (mounted) _maybeShowCompletionDialog();
    });
  }

  void _maybeShowCompletionDialog() {
    final m = _material;
    if (m == null || m.pages.isEmpty || !_canNext || _dialogOpen) return;

    final key = '${m.moduleNo}:$_pageIndex';
    if (_completionDialogsShown.contains(key)) return;

    final last = _pageIndex >= m.pages.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_canNext ||
          _dialogOpen ||
          _completionDialogsShown.contains(key)) {
        return;
      }

      _completionDialogsShown.add(key);
      _showLearningDialog(
        icon: last ? Icons.verified_rounded : Icons.check_circle_rounded,
        title: last
            ? _t(
                'Learning materials completed',
                'Tapos na ang modyul sa pag-aaral',
              )
            : _t('Section complete', 'Tapos na ang seksyon'),
        message: last
            ? _t(
                'Great job! You have completed the learning materials. You may now proceed to the next activity.',
                'Mahusay! Natapos mo na ang modyul sa pag-aaral. Maaari ka nang magpatuloy sa susunod na gawain.',
              )
            : _t(
                'Good. You reached the end of this section. You may continue when ready.',
                'Maganda. Nakarating ka na sa dulo ng seksyong ito. Maaari kang magpatuloy kapag handa ka na.',
              ),
        buttonText: last ? _t('Continue', 'Magpatuloy') : _t('Next', 'Susunod'),
      );
    });
  }

  Future<void> _showLearningDialog({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
  }) async {
    if (!mounted || _dialogOpen) return;

    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _LearningDialogCard(
        icon: icon,
        accent: _accent,
        accent2: _accent2,
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: () => Navigator.pop(dialogContext),
      ),
    );

    if (mounted) {
      _dialogOpen = false;
    } else {
      _dialogOpen = false;
    }
  }

  void _showReadRequiredSnack() {
    showAppNotification(
      context,
      message: _t(
        'Please scroll to the bottom of this section before continuing.',
        'Paki-scroll muna hanggang dulo ng seksyong ito bago magpatuloy.',
      ),
      type: AppNotificationType.warning,
      accentColor: _accent,
    );
  }

  void _resetScroll() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _progress = 0;
      _canNext = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _back() {
    if (_pageIndex == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _pageIndex--);
      _resetScroll();
    }
  }

  void _next() {
    final m = _material;
    if (m == null || m.pages.isEmpty) return;
    final last = _pageIndex >= m.pages.length - 1;

    if (!_canNext) {
      _showReadRequiredSnack();
      return;
    }

    if (!last) {
      setState(() => _pageIndex++);
      _resetScroll();
      return;
    }

    _completeLearningMaterialAndOpenPostAssessment(m.moduleNo);
  }

  Future<void> _completeLearningMaterialAndOpenPostAssessment(
    int moduleNo,
  ) async {
    try {
      final progression = ModuleProgressionService(client: _client);
      await progression.markLearningMaterialCompleted(moduleNo: moduleNo);
      await progression.ensureCanStartPostTest(moduleNo: moduleNo);
      if (!mounted) return;

      Widget page;
      switch (moduleNo) {
        case 1:
          page = const post1.PostAssessmentIntroPage();
          break;
        case 2:
          page = const house_post.PostAssessmentIntroPage();
          break;
        case 3:
          page = const post3.PostAssessmentIntroPage();
          break;
        case 4:
          page = const post4.PostAssessmentIntroPage2();
          break;
        case 5:
          page = const post5.PostAssessmentIntroPage();
          break;
        default:
          await _showLearningDialog(
            icon: Icons.info_outline_rounded,
            title: _t('Module unavailable', 'Hindi pa available ang modyul'),
            message: _t(
              'This module is not available yet.',
              'Hindi pa available ang modyul na ito.',
            ),
            buttonText: _t('OK', 'Sige'),
          );
          return;
      }

      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    } on ProgressionAccessDenied catch (e) {
      if (!mounted) return;
      await _showLearningDialog(
        icon: Icons.lock_outline_rounded,
        title: _t(
          'Post-Assessment Locked',
          'Naka-lock ang Panghuling Pagsusulit',
        ),
        message: e.message,
        buttonText: _t('OK', 'Sige'),
      );
    } catch (e) {
      if (!mounted) return;
      await _showLearningDialog(
        icon: Icons.error_outline_rounded,
        title: _t('Completion not saved', 'Hindi na-save ang completion'),
        message: e.toString().replaceFirst('Exception: ', ''),
        buttonText: _t('OK', 'Sige'),
      );
    }
  }

  String _t(String en, String tl) => _isTl && tl.trim().isNotEmpty ? tl : en;

  List<LearningSource> _pageSources(LearningPage page) {
    final seen = <String>{};
    final sources = <LearningSource>[];

    for (final block in page.blocks) {
      final title = block.sourceTitle.trim();
      final organization = block.sourceOrganization.trim();
      final url = block.sourceUrl.trim();
      final accessedAt = block.sourceAccessedAt.trim();

      if (title.isEmpty && organization.isEmpty) continue;

      final key = '$title|$organization|$url';

      if (seen.add(key)) {
        sources.add(
          LearningSource(
            title: title,
            organization: organization,
            url: url,
            accessedAt: accessedAt,
          ),
        );
      }
    }

    return sources;
  }

  @override
  Widget build(BuildContext context) {
    final m = _material;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: _MessageCard(
                        icon: Icons.error_outline_rounded,
                        title: _t(
                          'Cannot load learning material',
                          'Hindi ma-load ang learning material',
                        ),
                        message: _error!,
                        buttonText: _t('Retry', 'Subukan muli'),
                        color: _accent,
                        onPressed: _loadMaterial,
                      ),
                    ),
                  )
                : m == null || m.pages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: _MessageCard(
                        icon: Icons.menu_book_outlined,
                        title: _t('No content', 'Walang content'),
                        message: _t(
                          'No learning material content found.',
                          'Walang learning material content na nakita.',
                        ),
                        buttonText: _t('Back', 'Balik'),
                        color: _accent,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  )
                : _buildContent(m),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LearningMaterial m) {
    final page = m.pages[_pageIndex];
    final last = _pageIndex >= m.pages.length - 1;
    final supportingImages = m.mediaAssets
        .where(
          (x) =>
              x.assetType != 'background' &&
              x.assetType != 'hero' &&
              x.assetType != 'fire_class_image',
        )
        .toList();
    final sources = _pageSources(page);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = constraints.maxWidth < 370;
        final compactHeight = constraints.maxHeight < 660;
        final horizontalPadding = compactWidth ? 12.0 : 16.0;
        final headerTopPadding = compactHeight ? 8.0 : 12.0;
        final sectionGap = compactHeight ? 8.0 : 12.0;
        final bottomTopPadding = compactHeight ? 6.0 : 10.0;
        final bottomPadding = compactHeight ? 8.0 : 16.0;
        final scrollBottomGap = compactHeight ? 12.0 : 18.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                headerTopPadding,
                horizontalPadding,
                0,
              ),
              child: _DetailHeader(
                accent: _accent,
                accent2: _accent2,
                moduleLabel: m.moduleLabel(_isTl),
                title: m.title(_isTl),
                pageTitle: page.title(_isTl),
                currentPage: _pageIndex + 1,
                totalPages: m.pages.length,
                progress: _progress,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SizedBox(height: sectionGap),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  scrollBottomGap,
                ),
                child: Column(
                  children: [
                    _ContentCard(
                      accent: _accent,
                      accent2: _accent2,
                      title: page.title(_isTl),
                      trailing: Text(
                        '${_pageIndex + 1}/${m.pages.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_pageIndex == 0 && m.heroImage != null) ...[
                            _ResponsiveImageFrame(
                              accent: _accent,
                              child: _DbImage(asset: m.heroImage!),
                            ),
                            SizedBox(height: compactHeight ? 12 : 16),
                          ],
                          ...page.blocks.map((b) => _blockWidget(b)),
                        ],
                      ),
                    ),
                    if (sources.isNotEmpty) ...[
                      SizedBox(height: sectionGap),
                      _SourceReferenceCard(
                        sources: sources,
                        isTl: _isTl,
                        accent: _accent,
                      ),
                    ],
                    if (m.moduleNo == 1 &&
                        page.pageNo == 2 &&
                        _fireGuides.isNotEmpty) ...[
                      SizedBox(height: sectionGap),
                      _ExpandableSection(
                        accent: _accent,
                        title: _t(
                          'Fire Class Guide',
                          'Gabay sa Klase ng Sunog',
                        ),
                        initiallyExpanded: true,
                        child: _FireGuide(
                          guides: _fireGuides,
                          isTl: _isTl,
                          accent: _accent,
                        ),
                      ),
                    ],
                    if (last && supportingImages.isNotEmpty) ...[
                      SizedBox(height: sectionGap),
                      _ExpandableSection(
                        accent: _accent,
                        title: _t(
                          'Learning material images',
                          'Mga larawan ng materyal',
                        ),
                        initiallyExpanded: true,
                        child: _ImageGallery(
                          title: _t(
                            'Learning material images',
                            'Mga larawan ng materyal',
                          ),
                          images: supportingImages,
                          isTl: _isTl,
                          accent: _accent,
                        ),
                      ),
                    ],
                    SizedBox(height: sectionGap),
                    _ReadingCheckpointCard(
                      accent: _accent,
                      progress: _progress,
                      completed: _canNext,
                      isLast: last,
                      isTl: _isTl,
                    ),
                    SizedBox(height: scrollBottomGap),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  bottomTopPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: _BottomActionBar(
                  accent: _accent,
                  accent2: _accent2,
                  canNext: _canNext,
                  last: last,
                  onBack: _back,
                  onNext: _next,
                  backText: _t('Back', 'Balik'),
                  nextText: last
                      ? _t('Start pre test', 'Simulan ang paunang pagsusulit')
                      : _t('Next', 'Sunod'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blockWidget(LearningBlock b) {
    final text = b.text(_isTl).trim();
    if (text.isEmpty) return const SizedBox.shrink();

    if (b.blockType == 'heading') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          softWrap: true,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _accent,
            height: 1.3,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    if (b.blockType == 'label') {
      return _LearningTipCard(
        accent: _accent,
        title: _t(
          'Tap to reveal safety reminder',
          'I-tap para makita ang paalala',
        ),
        text: text,
      );
    }

    if (b.blockType == 'list_or_multiline' || text.contains('\n')) {
      final lines = text
          .split('\n')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
      return _Bullets(items: lines, accent: _accent);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        softWrap: true,
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: Color(0xFF1F2937),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class LearningMaterial {
  final int moduleNo;
  final String titleEn;
  final String titleTl;
  final String subtitleEn;
  final String subtitleTl;
  final String heroAsset;
  final List<LearningPage> pages;
  final List<LearningMediaAsset> mediaAssets;

  LearningMaterial({
    required this.moduleNo,
    required this.titleEn,
    required this.titleTl,
    required this.subtitleEn,
    required this.subtitleTl,
    required this.heroAsset,
    required this.pages,
    required this.mediaAssets,
  });

  factory LearningMaterial.fromMap(Map<String, dynamic> m) {
    final pages =
        _list(m['pages'])
            .map((x) => LearningPage.fromMap(Map<String, dynamic>.from(x)))
            .toList()
          ..sort((a, b) => a.pageNo.compareTo(b.pageNo));
    final media =
        _list(m['media_assets'])
            .map(
              (x) => LearningMediaAsset.fromMap(Map<String, dynamic>.from(x)),
            )
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return LearningMaterial(
      moduleNo: _int(m['module_no']),
      titleEn: _str(m['title']),
      titleTl: _str(m['title_tl']),
      subtitleEn: _str(m['subtitle']),
      subtitleTl: _str(m['subtitle_tl']),
      heroAsset: _str(m['hero_asset']),
      pages: pages,
      mediaAssets: media,
    );
  }

  String moduleLabel(bool isTl) =>
      isTl ? 'MODYUL $moduleNo' : 'MODULE $moduleNo';
  String title(bool isTl) =>
      isTl && titleTl.trim().isNotEmpty ? titleTl : titleEn;
  String subtitle(bool isTl) =>
      isTl && subtitleTl.trim().isNotEmpty ? subtitleTl : subtitleEn;

  LearningMediaAsset? get heroImage {
    bool hasUsablePath(LearningMediaAsset img) {
      return img.assetPath.trim().isNotEmpty || img.publicUrl.trim().isNotEmpty;
    }

    // Force Module 2 to use the exact Supabase Storage preview image first.
    if (moduleNo == 2) {
      for (final img in mediaAssets) {
        final key = img.assetKey.trim().toLowerCase();

        if (key == 'module2_house_fire_preview_image' && hasUsablePath(img)) {
          return img;
        }
      }

      if (heroAsset.trim().isNotEmpty) {
        return LearningMediaAsset(
          displayOrder: 0,
          assetKey: 'module2_house_fire_preview_image',
          assetPath: heroAsset.trim(), // must be house.jpg
          publicUrl: '',
          assetType: 'image',
          altEn: titleEn,
          altTl: titleTl,
        );
      }
    }

    // For other modules, prefer exact preview image before generic hero.
    for (final img in mediaAssets) {
      final key = img.assetKey.trim().toLowerCase();
      final type = img.assetType.trim().toLowerCase();

      if (type == 'image' && key.contains('preview') && hasUsablePath(img)) {
        return img;
      }
    }

    for (final img in mediaAssets) {
      if (img.assetType.trim().toLowerCase() == 'hero' && hasUsablePath(img)) {
        return img;
      }
    }

    if (heroAsset.trim().isNotEmpty) {
      return LearningMediaAsset(
        displayOrder: 0,
        assetKey: 'hero',
        assetPath: heroAsset.trim(),
        publicUrl: '',
        assetType: 'hero',
        altEn: titleEn,
        altTl: titleTl,
      );
    }

    for (final img in mediaAssets) {
      if (img.assetType.trim().toLowerCase() == 'image' && hasUsablePath(img)) {
        return img;
      }
    }

    return null;
  }
}

class LearningPage {
  final int pageNo;
  final String titleEn;
  final String titleTl;
  final List<LearningBlock> blocks;

  LearningPage({
    required this.pageNo,
    required this.titleEn,
    required this.titleTl,
    required this.blocks,
  });

  factory LearningPage.fromMap(Map<String, dynamic> m) {
    final blocks =
        _list(m['blocks'])
            .map((x) => LearningBlock.fromMap(Map<String, dynamic>.from(x)))
            .toList()
          ..sort((a, b) => a.blockNo.compareTo(b.blockNo));
    return LearningPage(
      pageNo: _int(m['page_no']),
      titleEn: _str(m['title_en']),
      titleTl: _str(m['title_tl']),
      blocks: blocks,
    );
  }

  String title(bool isTl) =>
      isTl && titleTl.trim().isNotEmpty ? titleTl : titleEn;
}

class LearningBlock {
  final int blockNo;
  final String blockType;
  final String textEn;
  final String textTl;
  final String sourceTitle;
  final String sourceOrganization;
  final String sourceUrl;
  final String sourceAccessedAt;

  LearningBlock({
    required this.blockNo,
    required this.blockType,
    required this.textEn,
    required this.textTl,
    required this.sourceTitle,
    required this.sourceOrganization,
    required this.sourceUrl,
    required this.sourceAccessedAt,
  });

  factory LearningBlock.fromMap(Map<String, dynamic> m) {
    return LearningBlock(
      blockNo: _int(m['block_no']),
      blockType: _str(m['block_type']).isEmpty
          ? 'paragraph'
          : _str(m['block_type']),
      textEn: _str(m['text_en']),
      textTl: _str(m['text_tl']),
      sourceTitle: _str(m['source_title']),
      sourceOrganization: _str(m['source_organization']),
      sourceUrl: _str(m['source_url']),
      sourceAccessedAt: _str(m['source_accessed_at']),
    );
  }

  String text(bool isTl) => isTl && textTl.trim().isNotEmpty ? textTl : textEn;

  bool get hasSource =>
      sourceTitle.trim().isNotEmpty ||
      sourceOrganization.trim().isNotEmpty ||
      sourceUrl.trim().isNotEmpty;
}

class LearningSource {
  final String title;
  final String organization;
  final String url;
  final String accessedAt;

  LearningSource({
    required this.title,
    required this.organization,
    required this.url,
    required this.accessedAt,
  });
}

class LearningMediaAsset {
  final int displayOrder;
  final String assetKey;
  final String assetPath;
  final String publicUrl;
  final String assetType;
  final String altEn;
  final String altTl;

  LearningMediaAsset({
    required this.displayOrder,
    required this.assetKey,
    required this.assetPath,
    required this.publicUrl,
    required this.assetType,
    required this.altEn,
    required this.altTl,
  });

  factory LearningMediaAsset.fromMap(Map<String, dynamic> m) {
    return LearningMediaAsset(
      displayOrder: _int(m['display_order']),
      assetKey: _str(m['asset_key']),
      assetPath: _str(m['asset_path']),
      publicUrl: _str(m['public_url']),
      assetType: _str(m['asset_type']),
      altEn: _str(m['alt_en']),
      altTl: _str(m['alt_tl']),
    );
  }

  String alt(bool isTl) => isTl && altTl.trim().isNotEmpty ? altTl : altEn;
}

class FireClassGuide {
  final String classNameEn;
  final String classNameTl;
  final String imageAsset;
  final List<String> examplesEn;
  final List<String> examplesTl;
  final List<String> agentsEn;
  final List<String> agentsTl;

  FireClassGuide({
    required this.classNameEn,
    required this.classNameTl,
    required this.imageAsset,
    required this.examplesEn,
    required this.examplesTl,
    required this.agentsEn,
    required this.agentsTl,
  });

  factory FireClassGuide.fromMap(Map<String, dynamic> m) {
    return FireClassGuide(
      classNameEn: _str(m['class_name_en']),
      classNameTl: _str(m['class_name_tl']),
      imageAsset: _str(m['image_asset']),
      examplesEn: _stringList(m['examples_en']),
      examplesTl: _stringList(m['examples_tl']),
      agentsEn: _stringList(m['agents_en']),
      agentsTl: _stringList(m['agents_tl']),
    );
  }

  String name(bool isTl) =>
      isTl && classNameTl.trim().isNotEmpty ? classNameTl : classNameEn;
  List<String> examples(bool isTl) =>
      isTl && examplesTl.isNotEmpty ? examplesTl : examplesEn;
  List<String> agents(bool isTl) =>
      isTl && agentsTl.isNotEmpty ? agentsTl : agentsEn;
}

class _ProfileHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _ProfileHeader({
    required this.greeting,
    required this.subtitle,
    required this.avatarUrl,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) async {
              if (value == 'profile') onProfile();
              if (value == 'logout') onLogout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded),
                    const SizedBox(width: 8),
                    Text(context.tr('profile')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded),
                    const SizedBox(width: 8),
                    Text(context.tr('log_out')),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE5E7EB),
              backgroundImage:
                  (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.trim().isEmpty)
                  ? const Icon(Icons.person, color: Color(0xFF6B7280))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final int moduleNo;
  final String moduleLabel;
  final String title;
  final String description;
  final LearningMediaAsset? image;
  final bool isTl;
  final bool isCompleted;
  final bool isExpanded;
  final String? selectedActionKey;
  final bool Function(String actionKey)? isActionLocked;
  final String? Function(String actionKey)? lockedSubtitle;
  final VoidCallback onHeaderTap;
  final ValueChanged<String> onChildTap;

  const _ModuleCard({
    required this.moduleNo,
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.image,
    required this.isTl,
    required this.isCompleted,
    required this.isExpanded,
    required this.selectedActionKey,
    this.isActionLocked,
    this.lockedSubtitle,
    required this.onHeaderTap,
    required this.onChildTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _moduleAccent(moduleNo);
    final actions = _ModuleAction.items(isTl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        final imgSize = (constraints.maxWidth * 0.20)
            .clamp(compact ? 52.0 : 62.0, compact ? 68.0 : 84.0)
            .toDouble();
        final cardPadding = compact ? 12.0 : 14.0;
        final horizontalGap = compact ? 10.0 : 12.0;
        final arrowSize = compact ? 36.0 : 40.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded
                  ? accent.withOpacity(0.42)
                  : Colors.black.withOpacity(0.06),
              width: isExpanded ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isExpanded ? 0.14 : 0.10),
                blurRadius: isExpanded ? 20 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onHeaderTap,
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Row(
                        crossAxisAlignment: isExpanded
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: imgSize,
                            height: imgSize,
                            padding: EdgeInsets.all(compact ? 8 : 10),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: image == null
                                ? FittedBox(
                                    child: Icon(
                                      _moduleIcon(moduleNo),
                                      color: accent,
                                    ),
                                  )
                                : _DbImage(asset: image!),
                          ),
                          SizedBox(width: horizontalGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact ? 8 : 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          moduleLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: compact ? 6 : 8),
                                    if (isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F4EE),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF2E7D5B),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              isTl ? 'Tapos' : 'Done',
                                              style: const TextStyle(
                                                color: Color(0xFF2E7D5B),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Icon(
                                        _moduleIcon(moduleNo),
                                        color: accent,
                                        size: 18,
                                      ),
                                  ],
                                ),
                                SizedBox(height: compact ? 8 : 10),
                                Text(
                                  title,
                                  maxLines: isExpanded
                                      ? null
                                      : (compact ? 2 : 3),
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: const Color(0xFF111827),
                                    fontSize: compact ? 14.5 : 15.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.24,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  maxLines: isExpanded
                                      ? null
                                      : (compact ? 2 : 3),
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: const Color(0xFF4B5563),
                                    fontSize: compact ? 12 : 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: compact ? 6 : 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: arrowSize,
                            height: arrowSize,
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? accent
                                  : accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isExpanded ? Colors.white : accent,
                                size: compact ? 25 : 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: EdgeInsets.fromLTRB(
                        cardPadding,
                        0,
                        cardPadding,
                        cardPadding,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(
                            height: 18,
                            color: Colors.black.withOpacity(0.07),
                          ),
                          ...actions.map(
                            (action) => _ModuleActionTile(
                              action: action,
                              accent: accent,
                              isActive:
                                  selectedActionKey ==
                                  '$moduleNo:${action.key}',
                              isLocked:
                                  isActionLocked?.call(action.key) ?? false,
                              lockedSubtitle: lockedSubtitle?.call(action.key),
                              onTap: () => onChildTap(action.key),
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 230),
                    reverseDuration: const Duration(milliseconds: 170),
                    sizeCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModuleAction {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ModuleAction({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static List<_ModuleAction> items(bool isTl) {
    return [
      _ModuleAction(
        key: 'pre_test',
        icon: Icons.assignment_outlined,
        title: isTl ? 'Paunang Pagsusulit' : 'Pre-Assessment',
        subtitle: isTl
            ? 'Sagutan muna bago aralin ang modyul.'
            : 'Start the assessment before studying the module.',
      ),
      _ModuleAction(
        key: 'learning_materials',
        icon: Icons.menu_book_rounded,
        title: isTl ? 'Modyul sa Pag-aaral' : 'Learning Materials',
        subtitle: isTl
            ? 'Basahin ang module pages at references.'
            : 'Read the module pages and references.',
      ),
      _ModuleAction(
        key: 'post_test',
        icon: Icons.fact_check_outlined,
        title: isTl ? 'Panghuling Pagsusulit' : 'Post-Assessment',
        subtitle: isTl
            ? 'Gamitin pagkatapos ng Modyul sa Pag-aaral.'
            : 'Use after completing the learning materials.',
      ),
      _ModuleAction(
        key: 'simulation',
        icon: Icons.sports_esports_rounded,
        title: isTl ? '3D Simulasyon' : '3D Simulation',
        subtitle: isTl
            ? 'Buksan ang interactive 3D activity.'
            : 'Open the interactive 3D activity.',
      ),
    ];
  }
}

class _ModuleActionTile extends StatelessWidget {
  final _ModuleAction action;
  final Color accent;
  final bool isActive;
  final bool isLocked;
  final String? lockedSubtitle;
  final VoidCallback onTap;

  const _ModuleActionTile({
    required this.action,
    required this.accent,
    required this.isActive,
    required this.isLocked,
    this.lockedSubtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isLocked
                ? const Color(0xFFF3F4F6)
                : isActive
                ? accent.withOpacity(0.10)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLocked
                  ? Colors.black.withOpacity(0.06)
                  : isActive
                  ? accent.withOpacity(0.38)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFFE5E7EB)
                      : isActive
                      ? accent
                      : accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : action.icon,
                  color: isLocked
                      ? const Color(0xFF6B7280)
                      : isActive
                      ? Colors.white
                      : accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLocked
                            ? const Color(0xFF6B7280)
                            : isActive
                            ? accent
                            : const Color(0xFF111827),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLocked && lockedSubtitle != null
                          ? lockedSubtitle!
                          : action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.5,
                        height: 1.30,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: isLocked
                    ? const Color(0xFF9CA3AF)
                    : isActive
                    ? accent
                    : const Color(0xFF9CA3AF),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final Color accent;
  final Color accent2;
  final String moduleLabel;
  final String title;
  final String pageTitle;
  final int currentPage;
  final int totalPages;
  final double progress;
  final VoidCallback onBack;

  const _DetailHeader({
    required this.accent,
    required this.accent2,
    required this.moduleLabel,
    required this.title,
    required this.pageTitle,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        final buttonSize = compact ? 38.0 : 42.0;
        final outerPadding = compact ? 12.0 : 14.0;
        final headerAccent = _softHeaderAccent(accent);
        final headerAccent2 = _softHeaderAccent2(accent, accent2);

        return Container(
          padding: EdgeInsets.all(outerPadding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: headerAccent.withOpacity(0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: headerAccent,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [headerAccent, headerAccent2],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                moduleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: headerAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$currentPage/$totalPages',
                                style: TextStyle(
                                  color: headerAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 16 : 18,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              Text(
                pageTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: compact ? 7 : 8,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(headerAccent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(totalPages, (index) {
                  final active = index == currentPage - 1;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active ? headerAccent : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Color accent;
  final Color accent2;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _ContentCard({
    required this.accent,
    required this.accent2,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        final padding = compact ? 14.0 : 16.0;
        final headerAccent = _softHeaderAccent(accent);
        final headerAccent2 = _softHeaderAccent2(accent, accent2);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 7 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [headerAccent, headerAccent2],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.2,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 64),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topRight,
                        child: trailing!,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 12 : 16),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveImageFrame extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _ResponsiveImageFrame({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final ratio = compact ? 4 / 3 : 16 / 9;

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            color: accent.withOpacity(0.06),
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: AspectRatio(
              aspectRatio: ratio,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 320,
                  height: compact ? 240 : 180,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ElectricalFireSimulationDialog extends StatelessWidget {
  final bool isTl;
  final Color accent;
  final Color accent2;
  final VoidCallback onClose;
  final VoidCallback onStart;

  const _ElectricalFireSimulationDialog({
    required this.isTl,
    required this.accent,
    required this.accent2,
    required this.onClose,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTl
        ? 'Eksena 3: Tutorial sa Kaligtasan sa Sunog sa Kuryente'
        : 'Scene 3: Electrical Fire Safety Tutorial';
    final description = isTl
        ? 'Sa eksenang ito, matututunan mo ang tamang hakbang kapag may sunog sa kuryente:'
        : 'In this scene, you will learn the correct steps to respond safely during an electrical fire:';
    final bullets = isTl
        ? const [
            'Patayin ang pinagmumulan ng kuryente kung ligtas gawin',
            'Huwag gumamit ng tubig sa sunog sa kuryente',
            'Gumamit ng tamang pamatay-sunog kung ikaw ay may pagsasanay',
            'Lumayo at humingi ng tulong',
          ]
        : const [
            'Turn off the power source if safe',
            'Do not use water on electrical fire',
            'Use the correct fire extinguisher if trained',
            'Move away and call for help',
          ];
    final buttonText = isTl ? 'SIMULAN ANG SIMULASYON' : 'START SIMULATION';
    final helperText = isTl
        ? 'Ang button na ito ay magdadala sa iyo sa Unity simulation.'
        : 'This button will redirect you to the Unity simulation.';

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final compact = width < 360;
          final horizontalMargin = compact ? 16.0 : 22.0;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: height * 0.82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 22,
                      compact ? 16 : 20,
                      compact ? 18 : 22,
                      compact ? 18 : 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: compact ? 46 : 52,
                              height: compact ? 46 : 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [accent, accent2],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.electric_bolt_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isTl ? 'MODYUL 3' : 'MODULE 3',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    title,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: const Color(0xFF111827),
                                      fontSize: compact ? 17 : 19,
                                      fontWeight: FontWeight.w900,
                                      height: 1.20,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(compact ? 13 : 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: accent.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...bullets.map(
                                (item) => _PassMethodBullet(
                                  text: item,
                                  accent: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [accent, accent2],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.26),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 13 : 15,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: onStart,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              label: Text(
                                buttonText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: accent,
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                helperText,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HouseFireEscapeSimulationDialog extends StatelessWidget {
  final bool isTl;
  final Color accent;
  final Color accent2;
  final VoidCallback onClose;
  final VoidCallback onStart;

  const _HouseFireEscapeSimulationDialog({
    required this.isTl,
    required this.accent,
    required this.accent2,
    required this.onClose,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTl
        ? 'Eksena 2: Tutorial sa Ligtas na Paglikas sa Sunog sa Bahay'
        : 'Scene 2: House Fire Escape Tutorial';
    final description = isTl
        ? 'Sa eksenang ito, matututunan mo ang tamang hakbang sa ligtas na paglikas kapag may sunog sa bahay:'
        : 'In this scene, you will learn the correct steps to escape safely during a house fire:';
    final bullets = isTl
        ? const [
            'Gumapang nang mababa sa ilalim ng usok',
            'Suriin ang pinto kung mainit',
            'Gamitin ang pinakamalapit na ligtas na labasan',
            'Humingi ng tulong kapag nasa labas na',
          ]
        : const [
            'Stay low under smoke',
            'Check doors for heat',
            'Use the nearest safe exit',
            'Call for help once outside',
          ];
    final buttonText = isTl ? 'SIMULAN ANG SIMULASYON' : 'START SIMULATION';
    final helperText = isTl
        ? 'Ang button na ito ay magdadala sa iyo sa Unity simulation.'
        : 'This button will redirect you to the Unity simulation.';

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final compact = width < 360;
          final horizontalMargin = compact ? 16.0 : 22.0;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: height * 0.82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 22,
                      compact ? 16 : 20,
                      compact ? 18 : 22,
                      compact ? 18 : 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: compact ? 46 : 52,
                              height: compact ? 46 : 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [accent, accent2],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.sports_esports_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isTl ? 'MODYUL 2' : 'MODULE 2',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    title,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: const Color(0xFF111827),
                                      fontSize: compact ? 17 : 19,
                                      fontWeight: FontWeight.w900,
                                      height: 1.20,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(compact ? 13 : 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: accent.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...bullets.map(
                                (item) => _PassMethodBullet(
                                  text: item,
                                  accent: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [accent, accent2],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.26),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 13 : 15,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: onStart,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              label: Text(
                                buttonText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: accent,
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                helperText,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PassMethodSimulationDialog extends StatelessWidget {
  final bool isTl;
  final Color accent;
  final Color accent2;
  final VoidCallback onClose;
  final VoidCallback onStart;

  const _PassMethodSimulationDialog({
    required this.isTl,
    required this.accent,
    required this.accent2,
    required this.onClose,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTl
        ? 'Eksena 1: PASS Method Tutorial'
        : 'Scene 1: PASS Method Tutorial';
    final description = isTl
        ? 'Sa eksenang ito, matututunan mo ang tamang hakbang sa paggamit ng pamatay-sunog:'
        : 'In this scene, you will learn the correct steps to use a fire extinguisher:';
    final bullets = isTl
        ? const [
            'Hilahin ang pin',
            'Itutok sa base ng apoy',
            'Pisilin ang hawakan',
            'Igalaw nang pakaliwa at pakanan',
          ]
        : const [
            'Pull the pin',
            'Aim at the base of the fire',
            'Squeeze the handle',
            'Sweep side to side',
          ];
    final buttonText = isTl ? 'SIMULAN ANG SIMULASYON' : 'START SIMULATION';
    final helperText = isTl
        ? 'Ang button na ito ay magdadala sa iyo sa Unity simulation.'
        : 'This button will redirect you to the Unity simulation.';

    const brandRed = Color(0xFFB11217);
    const brandRedDark = Color(0xFF7A1014);
    const brandRedDeep = Color(0xFF4E070A);

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final compact = width < 360;
          final horizontalMargin = compact ? 16.0 : 22.0;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: height * 0.82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 22,
                      compact ? 16 : 20,
                      compact ? 18 : 22,
                      compact ? 18 : 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: compact ? 46 : 52,
                              height: compact ? 46 : 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [brandRed, brandRedDark],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.sports_esports_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: brandRed.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'MODULE 1',
                                      style: TextStyle(
                                        color: brandRed,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    title,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: const Color(0xFF111827),
                                      fontSize: compact ? 17 : 19,
                                      fontWeight: FontWeight.w900,
                                      height: 1.20,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(compact ? 13 : 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F7),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: brandRed.withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...bullets.map(
                                (item) => _PassMethodBullet(
                                  text: item,
                                  accent: brandRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [brandRed, brandRedDark],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: brandRedDeep.withOpacity(0.26),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 13 : 15,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: onStart,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              label: Text(
                                buttonText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: brandRedDeep,
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                helperText,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KitchenFireSimulationDialog extends StatelessWidget {
  final bool isTl;
  final Color accent;
  final Color accent2;
  final VoidCallback onClose;
  final VoidCallback onStart;

  const _KitchenFireSimulationDialog({
    required this.isTl,
    required this.accent,
    required this.accent2,
    required this.onClose,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTl
        ? 'Eksena 4: Tutorial sa Kaligtasan sa Sunog sa Kusina'
        : 'Scene 4: Kitchen Fire Safety Tutorial';
    final description = isTl
        ? 'Sa eksenang ito, matututunan mo ang tamang hakbang kapag may sunog sa kusina:'
        : 'In this scene, you will learn the correct steps to respond safely during a kitchen fire:';
    final bullets = isTl
        ? const [
            'Patayin ang kalan kung ligtas gawin',
            'Takpan ang kawali gamit ang takip upang mapahina ang apoy',
            'Huwag gumamit ng tubig sa sunog mula sa mantika o langis',
            'Lumayo at humingi ng tulong kung lumalaki ang apoy',
          ]
        : const [
            'Turn off the stove if safe',
            'Cover the pan with a lid to smother flames',
            'Do not use water on grease or oil fire',
            'Move away and call for help if the fire grows',
          ];
    final buttonText = isTl ? 'SIMULAN ANG SIMULASYON' : 'START SIMULATION';
    final helperText = isTl
        ? 'Ang button na ito ay magdadala sa iyo sa Unity simulation.'
        : 'This button will redirect you to the Unity simulation.';

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final compact = width < 360;
          final horizontalMargin = compact ? 16.0 : 22.0;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: height * 0.82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 22,
                      compact ? 16 : 20,
                      compact ? 18 : 22,
                      compact ? 18 : 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: compact ? 46 : 52,
                              height: compact ? 46 : 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [accent, accent2],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isTl ? 'MODYUL 4' : 'MODULE 4',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    title,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: const Color(0xFF111827),
                                      fontSize: compact ? 17 : 19,
                                      fontWeight: FontWeight.w900,
                                      height: 1.20,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(compact ? 13 : 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...bullets.map(
                                (item) => _PassMethodBullet(
                                  text: item,
                                  accent: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [accent, accent2],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.26),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 13 : 15,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: onStart,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              label: Text(
                                buttonText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: accent,
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                helperText,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TenementFireSimulationDialog extends StatelessWidget {
  final bool isTl;
  final Color accent;
  final Color accent2;
  final VoidCallback onClose;
  final VoidCallback onStart;

  const _TenementFireSimulationDialog({
    required this.isTl,
    required this.accent,
    required this.accent2,
    required this.onClose,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTl
        ? 'Eksena 5: Tutorial sa Paglikas sa Sunog sa Tenement'
        : 'Scene 5: Tenement Fire Evacuation Tutorial';

    final description = isTl
        ? 'Sa eksenang ito, matututunan mo ang tamang hakbang kapag may sunog sa tenement:'
        : 'In this scene, you will learn the correct steps to respond safely during a tenement fire:';

    final bullets = isTl
        ? const [
            'I-alert agad ang mga tao sa paligid',
            'Yumuko at manatiling mababa kapag may usok',
            'Iwasang gumamit ng elevator',
            'Gamitin ang ligtas na labasan at pumunta sa assembly area',
          ]
        : const [
            'Alert occupants immediately',
            'Stay low when moving through smoke',
            'Avoid elevators',
            'Use safe exits and go to the assembly area',
          ];

    final buttonText = isTl ? 'SIMULAN ANG SIMULASYON' : 'START SIMULATION';

    final helperText = isTl
        ? 'Ang button na ito ay magdadala sa iyo sa Unity simulation.'
        : 'This button will redirect you to the Unity simulation.';

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final compact = width < 360;
          final horizontalMargin = compact ? 16.0 : 22.0;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: height * 0.82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 22,
                      compact ? 16 : 20,
                      compact ? 18 : 22,
                      compact ? 18 : 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: compact ? 46 : 52,
                              height: compact ? 46 : 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [accent, accent2],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isTl ? 'MODYUL 5' : 'MODULE 5',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    title,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: const Color(0xFF111827),
                                      fontSize: compact ? 17 : 19,
                                      fontWeight: FontWeight.w900,
                                      height: 1.20,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(compact ? 13 : 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: accent.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...bullets.map(
                                (item) => _PassMethodBullet(
                                  text: item,
                                  accent: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [accent, accent2],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.26),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 13 : 15,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: onStart,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              label: Text(
                                buttonText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: accent,
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                helperText,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PassMethodBullet extends StatelessWidget {
  final String text;
  final Color accent;

  const _PassMethodBullet({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningDialogCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accent2;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _LearningDialogCard({
    required this.icon,
    required this.accent,
    required this.accent2,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = MediaQuery.of(context).size.width < 360;

          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 430),
            padding: EdgeInsets.all(compact ? 18 : 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 54 : 62,
                  height: compact ? 54 : 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, accent2]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: compact ? 27 : 31,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.45,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accent, accent2]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: onPressed,
                      child: Text(
                        buttonText,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LearningTipCard extends StatefulWidget {
  final Color accent;
  final String title;
  final String text;

  const _LearningTipCard({
    required this.accent,
    required this.title,
    required this.text,
  });

  @override
  State<_LearningTipCard> createState() => _LearningTipCardState();
}

class _LearningTipCardState extends State<_LearningTipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accent.withOpacity(0.18)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: widget.accent,
          collapsedIconColor: widget.accent,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _expanded ? Icons.visibility_rounded : Icons.touch_app_rounded,
              color: widget.accent,
              size: 18,
            ),
          ),
          title: Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.accent,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              height: 1.25,
              fontFamily: 'Poppins',
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.text,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingCheckpointCard extends StatelessWidget {
  final Color accent;
  final double progress;
  final bool completed;
  final bool isLast;
  final bool isTl;

  const _ReadingCheckpointCard({
    required this.accent,
    required this.progress,
    required this.completed,
    required this.isLast,
    required this.isTl,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final percent = (safeProgress * 100).round();

    final title = completed
        ? (isTl ? 'Nabasa mo na ang seksyong ito' : 'Section read')
        : (isTl ? 'Basahin muna hanggang dulo' : 'Read to the end first');

    final message = completed
        ? (isLast
              ? (isTl
                    ? 'Maaari mo nang simulan ang paunang pagsusulit.'
                    : 'You may now start the pre-assessment.')
              : (isTl
                    ? 'Maaari ka nang pumunta sa susunod na bahagi.'
                    : 'You may now continue to the next section.'))
        : (isTl
              ? 'Mag-scroll hanggang mapuno ang progress bar bago magpatuloy.'
              : 'Scroll until the progress bar is complete before continuing.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? accent.withOpacity(0.09) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? accent.withOpacity(0.24)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: completed ? accent : accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.auto_stories_rounded,
              color: completed ? Colors.white : accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: completed ? accent : const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 12,
                    height: 1.35,
                    fontFamily: 'Poppins',
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

class _ExpandableSection extends StatelessWidget {
  final String title;
  final Color accent;
  final bool initiallyExpanded;
  final Widget child;

  const _ExpandableSection({
    required this.title,
    required this.accent,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: initiallyExpanded,
          iconColor: accent,
          collapsedIconColor: accent,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Color accent;
  final Color accent2;
  final bool canNext;
  final bool last;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String backText;
  final String nextText;

  const _BottomActionBar({
    required this.accent,
    required this.accent2,
    required this.canNext,
    required this.last,
    required this.onBack,
    required this.onNext,
    required this.backText,
    required this.nextText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final buttonPadding = EdgeInsets.symmetric(
          vertical: compact ? 12 : 14,
          horizontal: compact ? 10 : 14,
        );

        Widget backButton() {
          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
              padding: buttonPadding,
              minimumSize: const Size(0, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: Text(
              backText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }

        Widget nextButton() {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: canNext
                  ? LinearGradient(colors: [accent, accent2])
                  : null,
              color: canNext ? null : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF9CA3AF),
                padding: buttonPadding,
                minimumSize: const Size(0, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: canNext ? onNext : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      nextText,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    last
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }

        final content = compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, child: nextButton()),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: backButton()),
                ],
              )
            : Row(
                children: [
                  Expanded(child: backButton()),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: nextButton()),
                ],
              );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

class _DbImage extends StatelessWidget {
  final LearningMediaAsset asset;

  const _DbImage({required this.asset});

  static const String _bucketName = 'Learning Materials';

  String _cleanPath(String value) {
    final path = value.trim();
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return path.substring(1);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final directUrl = asset.publicUrl.trim();
    final storagePath = _cleanPath(asset.assetPath);

    final imageUrl = directUrl.isNotEmpty
        ? directUrl
        : storagePath.isNotEmpty
        ? Supabase.instance.client.storage
              .from(_bucketName)
              .getPublicUrl(storagePath)
        : '';

    if (imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() => const Icon(
    Icons.local_fire_department_rounded,
    color: Color(0xFFB11217),
    size: 38,
  );
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  final Color accent;

  const _Bullets({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((raw) {
        final text = raw.replaceFirst(RegExp(r'^[-•]\s*'), '').trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    height: 1.5,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FireGuide extends StatelessWidget {
  final List<FireClassGuide> guides;
  final bool isTl;
  final Color accent;

  const _FireGuide({
    required this.guides,
    required this.isTl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ex = isTl ? 'Halimbawa' : 'Examples';
    final ag = isTl ? 'Pamatay' : 'Agents';

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        final imageSize = narrow ? 64.0 : 72.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: guides.map((g) {
            final image = Container(
              width: imageSize,
              height: imageSize,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                g.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.fire_extinguisher, color: accent),
              ),
            );

            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.name(isTl),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$ex: ${g.examples(isTl).join(', ')}',
                  softWrap: true,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  '$ag: ${g.agents(isTl).join(', ')}',
                  softWrap: true,
                  style: const TextStyle(height: 1.4),
                ),
              ],
            );

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.12)),
              ),
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [image, const SizedBox(height: 10), text],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        image,
                        const SizedBox(width: 12),
                        Expanded(child: text),
                      ],
                    ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final String title;
  final List<LearningMediaAsset> images;
  final bool isTl;
  final Color accent;

  const _ImageGallery({
    required this.title,
    required this.images,
    required this.isTl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: images
          .map(
            (img) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _DbImage(asset: img),
                      ),
                    ),
                  ),
                  if (img.alt(isTl).trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      img.alt(isTl),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final Color color;
  final VoidCallback onPressed;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceReferenceCard extends StatelessWidget {
  final List<LearningSource> sources;
  final bool isTl;
  final Color accent;

  const _SourceReferenceCard({
    required this.sources,
    required this.isTl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final title = isTl ? 'Pinagmulan ng impormasyon' : 'Information source';
    final note = isTl
        ? 'Ang nilalaman ng pahinang ito ay batay sa sumusunod na sanggunian.'
        : 'This page is based on the following reference.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 11.5,
                    height: 1.35,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                ...sources.map((source) {
                  final organization = source.organization.trim();
                  final sourceTitle = source.title.trim();
                  final accessedAt = source.accessedAt.trim();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.isNotEmpty
                              ? organization
                              : (isTl
                                    ? 'Hindi tinukoy na organisasyon'
                                    : 'Unspecified organization'),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            height: 1.3,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (sourceTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sourceTitle,
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 12,
                              height: 1.35,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                        if (accessedAt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            isTl
                                ? 'Na-access noong: $accessedAt'
                                : 'Accessed: $accessedAt',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 10.5,
                              height: 1.3,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isBrandRed(Color color) => color.toARGB32() == 0xFFB11217;

Color _softHeaderAccent(Color accent) {
  return _isBrandRed(accent) ? const Color(0xFFD95A60) : accent;
}

Color _softHeaderAccent2(Color accent, Color accent2) {
  return _isBrandRed(accent) ? const Color(0xFFE97872) : accent2;
}

Color _moduleAccent(int moduleNo) {
  switch (moduleNo) {
    case 2:
      return const Color(0xFFF97316);
    case 3:
      return const Color(0xFF2563EB);
    case 4:
      return const Color(0xFFF59E0B);
    case 5:
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFFB11217);
  }
}

Color _moduleAccent2(int moduleNo) {
  switch (moduleNo) {
    case 2:
      return const Color(0xFFF59E0B);
    case 3:
      return const Color(0xFF1D4ED8);
    case 4:
      return const Color(0xFFF97316);
    case 5:
      return const Color(0xFFF97316);
    default:
      return const Color(0xFFF97316);
  }
}

IconData _moduleIcon(int moduleNo) {
  switch (moduleNo) {
    case 2:
      return Icons.home_rounded;
    case 3:
      return Icons.electric_bolt_rounded;
    case 4:
      return Icons.restaurant_rounded;
    case 5:
      return Icons.apartment_rounded;
    default:
      return Icons.fire_extinguisher_rounded;
  }
}

List<dynamic> _list(dynamic v) => v is List ? v : const [];
String _str(dynamic v) => (v ?? '').toString();
int _int(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
List<String> _stringList(dynamic v) => v is List
    ? v
          .map((x) => (x ?? '').toString())
          .where((x) => x.trim().isNotEmpty)
          .toList()
    : const [];
