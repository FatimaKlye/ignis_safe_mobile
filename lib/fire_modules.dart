import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'localization/app_text.dart';
import 'profile_refresh_notifier.dart';

import 'module_1_extinguisher.dart/pre_assess_instruction.dart' as pre1;
import 'module_1_extinguisher.dart/post_assessment_extinguisher.dart';
import 'module_1_extinguisher.dart/simulation_scene.dart';


import 'module_2_house.dart/post_assessment_house.dart' as house_post;
import 'module_2_house.dart/pre_assess_instruction.dart' as house_pre;
import 'module_2_house.dart/simulation_scene_house.dart' as house_sim;


import 'module_3_electrical.dart/post_assessment_electrical.dart' as electrical_post;
import 'module_3_electrical.dart/pre_assess_instruction.dart' as electrical_pre;
import 'module_3_electrical.dart/simulation_scene_electrical.dart' as electrical_sim;

import 'module_4_kitchen.dart/pre_assess_instruction.dart' as kitchen_pre;
import 'module_4_kitchen.dart/post_assessment_kitchen.dart' as kitchen_post;
import 'module_4_kitchen.dart/simulation_scene.dart' as kitchen_sim;

import 'module_5_building.dart/pre_assess_instruction.dart' as building_pre;
import 'module_5_building.dart/post_assessment_building.dart' as building_post;
import 'module_5_building.dart/simulation_scene.dart' as building_sim;


enum ModuleFilter { all, pending, inProgress, completed }

class FireMaterialsTab extends StatefulWidget {
  const FireMaterialsTab({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<FireMaterialsTab> createState() => _FireMaterialsTabState();
}

class _FireMaterialsTabState extends State<FireMaterialsTab> {
  static const Color brandRed = Color(0xFFB11217);

  String _searchQuery = "";
  ModuleFilter _filter = ModuleFilter.all;

  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;

  bool _isProgressLoading = true;

  RealtimeChannel? _moduleProgressChannel;

  final Map<int, String> _moduleDbIdByNo = {};
  final Map<int, ModuleProgress> _progressByModuleNo = {
    1: const ModuleProgress(preDone: false, simDone: false, postDone: false),
    2: const ModuleProgress(preDone: false, simDone: false, postDone: false),
    3: const ModuleProgress(preDone: false, simDone: false, postDone: false),
    4: const ModuleProgress(preDone: false, simDone: false, postDone: false),
    5: const ModuleProgress(preDone: false, simDone: false, postDone: false),
  };

  List<_ModuleItem> _modules(BuildContext context) => [
        _ModuleItem(
          moduleNo: 1,
          moduleLabel: context.tr('module_1'),
          title: context.tr('title_fire_extinguisher'),
          description: context.tr('desc_m1'),
          asset: "assets/fire_ex.png",
        ),
        _ModuleItem(
          moduleNo: 2,
          moduleLabel: context.tr('module_2'),
          title: context.tr('title_house_fire'),
          description: context.tr('desc_m2_fire_modules'),
          asset: "assets/house.jpg",
        ),
        _ModuleItem(
          moduleNo: 3,
          moduleLabel: context.tr('module_3'),
          title: context.tr('title_electrical_fire'),
          description: context.tr('desc_m3_fire_modules'),
          asset: "assets/electrical.png",
        ),
        _ModuleItem(
          moduleNo: 4,
          moduleLabel: context.tr('module_4'),
          title: context.tr('title_kitchen_fire'),
          description: context.tr('desc_m4_fire_modules'),
          asset: "assets/kitchen.png",
        ),
        _ModuleItem(
          moduleNo: 5,
          moduleLabel: context.tr('module_5'),
          title: context.tr('title_tenement_fire'),
          description: context.tr('desc_m5_fire_modules'),
          asset: "assets/condo.jpg",
        ),
      ];

  @override
  void initState() {
    super.initState();
    profileRefreshNotifier.addListener(_handleProfileChanged);
    _initializePage();
  }

  void _handleProfileChanged() => _loadProfile();

  Future<void> _initializePage() async {
    await _loadProfile();
    await _loadModuleProgressFromDatabase();
    _subscribeToModuleProgress();
  }

  void _subscribeToModuleProgress() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _moduleProgressChannel?.unsubscribe();

    _moduleProgressChannel = Supabase.instance.client
        .channel('module_progress_live_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'module_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            if (!mounted) return;
            await _loadModuleProgressFromDatabase();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    profileRefreshNotifier.removeListener(_handleProfileChanged);
    _moduleProgressChannel?.unsubscribe();
    super.dispose();
  }

  void _onSearchChanged(String v) => setState(() => _searchQuery = v);

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || data == null) return;

      setState(() {
        _firstName = (data['first_name'] ?? '').toString();
        _lastName = (data['last_name'] ?? '').toString();
        _avatarUrl = data['avatar_url'] as String?;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> _loadModuleProgressFromDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isProgressLoading = false);
        return;
      }

      final moduleRows = await Supabase.instance.client
          .from('modules')
          .select('id, module_no')
          .inFilter('module_no', [1, 2, 3, 4, 5]);

      final moduleDbIdByNo = <int, String>{};
      final moduleNoByDbId = <String, int>{};

      for (final row in moduleRows) {
        final moduleNo = row['module_no'] as int;
        final moduleId = row['id'].toString();
        moduleDbIdByNo[moduleNo] = moduleId;
        moduleNoByDbId[moduleId] = moduleNo;
      }

      final progressMap = <int, ModuleProgress>{
        1: const ModuleProgress(preDone: false, simDone: false, postDone: false),
        2: const ModuleProgress(preDone: false, simDone: false, postDone: false),
        3: const ModuleProgress(preDone: false, simDone: false, postDone: false),
        4: const ModuleProgress(preDone: false, simDone: false, postDone: false),
        5: const ModuleProgress(preDone: false, simDone: false, postDone: false),
      };

      if (moduleDbIdByNo.isNotEmpty) {
        final progressRows = await Supabase.instance.client
            .from('module_progress')
            .select(
              'module_id, pre_test_completed_at, simulation_completed_at, post_test_completed_at',
            )
            .eq('user_id', user.id)
            .inFilter('module_id', moduleDbIdByNo.values.toList());

        for (final row in progressRows) {
          final moduleId = row['module_id'].toString();
          final moduleNo = moduleNoByDbId[moduleId];
          if (moduleNo == null) continue;

          progressMap[moduleNo] = ModuleProgress(
            preDone: row['pre_test_completed_at'] != null,
            simDone: row['simulation_completed_at'] != null,
            postDone: row['post_test_completed_at'] != null,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _moduleDbIdByNo
          ..clear()
          ..addAll(moduleDbIdByNo);

        _progressByModuleNo
          ..clear()
          ..addAll(progressMap);

        _isProgressLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load module progress: $e');
      if (!mounted) return;
      setState(() => _isProgressLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_tab_index');
    try {
      await Supabase.instance.client.auth.signOut();
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

  Future<void> _goToProfile() async {
    widget.onRequestTabChange?.call(2);
  }

  Future<void> _openModuleActions(_ModuleItem m) async {
    final progress = _progressByModuleNo[m.moduleNo] ??
        const ModuleProgress(preDone: false, simDone: false, postDone: false);

    if (!mounted) return;

    await _showCenteredPopup(m, progress);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showCenteredPopup(
    _ModuleItem m,
    ModuleProgress progress,
  ) async {
    if (!mounted) return;

    final postLocked = false;

    await showGeneralDialog(
      context: context,
      barrierLabel: "module_actions",
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
                child: _ModuleActionPopup(
                  moduleLabel: m.moduleLabel,
                  moduleTitle: m.title,
                  progress: progress,
                  postLocked: postLocked,
                  onClose: () => Navigator.pop(context),
                  onPreTap: () {
                    Navigator.pop(context);
                    _goToPre(m);
                  },
                  onSimTap: () {
                    Navigator.pop(context);
                    _goToSim(m);
                  },
                  onPostTap: () {
                    Navigator.pop(context);
                    _goToPost(m);
                  },
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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

  Future<void> _goToPre(_ModuleItem m) async {
    switch (m.moduleNo) {
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const pre1.PreAssessmentIntroPage(),
          ),
        );
        break;

      case 2:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const house_pre.PreAssessmentIntroPage2(),
          ),
        );
        break;

      case 3:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const electrical_pre.PreAssessmentIntroPage2(),
          ),
        );
        break;

      case 4:
        await Navigator.push(
          context,
          MaterialPageRoute(
           builder: (_) => const kitchen_pre.PreAssessmentIntroPage2(),
          ),
        );
        break;

      case 5:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const building_pre.PreAssessmentIntroPage2(),
          ),
        );
        break;
    }

    await _loadModuleProgressFromDatabase();
  }

  Future<void> _goToSim(_ModuleItem m) async {
    switch (m.moduleNo) {
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SimulationScene(),
          ),
        );
        break;

      case 2:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const house_sim.SimulationScene2(),
          ),
        );
        break;

      case 3:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const electrical_sim.SimulationScene3()
          ),
        );
        break;

      case 4:
        await Navigator.push(
          context,
          MaterialPageRoute(
           builder: (_) => const kitchen_sim.SimulationScene4()
          ),
        );
        break;

      case 5:
        await Navigator.push(
          context,
          MaterialPageRoute(
           builder: (_) => const building_sim.SimulationScene5()
          ),
        );
        break;
    }

    await _loadModuleProgressFromDatabase();
  }

  Future<void> _goToPost(_ModuleItem m) async {
    switch (m.moduleNo) {
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PostAssessmentPassPage(),
          ),
        );
        break;

      case 2:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const house_post.PostAssessmentHousePage(),
          ),
        );
        break;

      case 3:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const electrical_post.PostAssessmentElectricalPage(),
          ),
        );
        break;

      case 4:
        await Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => const kitchen_post.PostAssessmentKitchenPage(),
          ),
        );
        break;

      case 5:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const building_post.PostAssessmentBuildingPage(),
          ),
        );
        break;
    }

    await _loadModuleProgressFromDatabase();
  }

  Future<void> _openFilterMenu(BuildContext context) async {
    final selected = await showMenu<ModuleFilter>(
      context: context,
      position: const RelativeRect.fromLTRB(9999, 120, 16, 0),
      items: [
        PopupMenuItem(value: ModuleFilter.all, child: Text(context.tr('all'))),
        PopupMenuItem(
          value: ModuleFilter.pending,
          child: Text(context.tr('pending_not_started')),
        ),
        PopupMenuItem(
          value: ModuleFilter.inProgress,
          child: Text(context.tr('in_progress')),
        ),
        PopupMenuItem(
          value: ModuleFilter.completed,
          child: Text(context.tr('completed')),
        ),
      ],
    );

    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  bool _matchesFilter(ModuleProgress p) {
    switch (_filter) {
      case ModuleFilter.all:
        return true;
      case ModuleFilter.pending:
        return p.value == 0.0;
      case ModuleFilter.inProgress:
        return p.value > 0.0 && p.value < 1.0;
      case ModuleFilter.completed:
        return p.value == 1.0;
    }
  }

  ImageProvider? _buildAvatarProvider() {
    if (_avatarUrl == null || _avatarUrl!.trim().isEmpty) return null;

    if (_avatarUrl!.startsWith('http')) {
      return NetworkImage(_avatarUrl!);
    }

    return AssetImage(_avatarUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.trim().toLowerCase();

    final searchedModules = _modules(context).where((m) {
      if (q.isEmpty) return true;
      return m.title.toLowerCase().contains(q) ||
          m.moduleLabel.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height,
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB11217),
                    Color(0xFFB11217),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        tooltip: "",
                        offset: const Offset(0, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onSelected: (value) async {
                          if (value == "profile") {
                            await _goToProfile();
                            return;
                          }
                          if (value == "logout") {
                            await _logout();
                            return;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: "profile",
                            child: Row(
                              children: [
                                Icon(Icons.person_outline_rounded),
                                SizedBox(width: 8),
                                Text(context.tr('profile')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: "logout",
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded),
                                SizedBox(width: 8),
                                Text(context.tr('log_out')),
                              ],
                            ),
                          ),
                        ],
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade400,
                          backgroundImage: _buildAvatarProvider(),
                          child: _buildAvatarProvider() == null
                              ? const Icon(
                                  Icons.person,
                                  size: 22,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _firstName.isEmpty && _lastName.isEmpty
                                ? context.tr('hi')
                                : context.tr(
                                    'hi_name',
                                    params: {'name': '$_firstName $_lastName'.trim()},
                                  ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('welcome_to_ignis_safe_short'),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Text(
                      context.tr('fire_scenario_module'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.075).clamp(20.0, 30.0),
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: context.tr('search'),
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('filter'),
                          onPressed: () => _openFilterMenu(context),
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: _filter == ModuleFilter.all
                                ? const Color(0xFF9E9E9E)
                                : brandRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _isProgressLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Builder(
                            builder: (context) {
                              final filteredModules = searchedModules.where((m) {
                                final progress =
                                    _progressByModuleNo[m.moduleNo] ??
                                        const ModuleProgress(
                                          preDone: false,
                                          simDone: false,
                                          postDone: false,
                                        );
                                return _matchesFilter(progress);
                              }).toList();

                              return ListView.builder(
                                padding: EdgeInsets.only(
                                  top: 14,
                                  bottom:
                                      (MediaQuery.of(context).padding.bottom + 12)
                                          .clamp(0.0, 999.0),
                                ),
                                itemCount: filteredModules.length,
                                itemBuilder: (context, index) {
                                  final m = filteredModules[index];
                                  final isLast =
                                      index == filteredModules.length - 1;
                                  final progress =
                                      _progressByModuleNo[m.moduleNo] ??
                                          const ModuleProgress(
                                            preDone: false,
                                            simDone: false,
                                            postDone: false,
                                          );

                                  return Padding(
                                    padding:
                                        EdgeInsets.only(bottom: isLast ? 0 : 30),
                                    child: _ModuleCard(
                                      moduleLabel: m.moduleLabel,
                                      title: m.title,
                                      description: m.description,
                                      asset: m.asset,
                                      progress: progress,
                                      onPressed: () => _openModuleActions(m),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final int moduleNo;
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;

  const _ModuleItem({
    required this.moduleNo,
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
  });
}

class ModuleProgress {
  final bool preDone;
  final bool simDone;
  final bool postDone;

  const ModuleProgress({
    required this.preDone,
    required this.simDone,
    required this.postDone,
  });

  int get completedCount {
    int count = 0;
    if (preDone) count++;
    if (simDone) count++;
    if (postDone) count++;
    return count;
  }

  double get value {
    switch (completedCount) {
      case 1:
        return 1 / 3;
      case 2:
        return 2 / 3;
      case 3:
        return 1.0;
      default:
        return 0.0;
    }
  }

  String get percentLabel {
    switch (completedCount) {
      case 1:
        return "33.3%";
      case 2:
        return "66.6%";
      case 3:
        return "100%";
      default:
        return "0%";
    }
  }

  Color get color {
    switch (completedCount) {
      case 1:
        return const Color(0xFF4F46E5);
      case 2:
        return const Color(0xFFF2C94C);
      case 3:
        return const Color(0xFF2EB872);
      default:
        return const Color(0xFFB11217);
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;
  final ModuleProgress progress;
  final VoidCallback onPressed;

  const _ModuleCard({
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
    required this.progress,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final imgSize = (MediaQuery.of(context).size.width * 0.22).clamp(72.0, 92.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: imgSize,
                height: imgSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFB11217),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          progress.percentLabel,
                          style: TextStyle(
                            color: progress.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress.value,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFEFEFEF),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 26,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB11217),
                              elevation: 6,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: onPressed,
                            child: Text(
                              context.tr('view'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -14,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB11217),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              moduleLabel,
              style: const TextStyle(
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

class _ModuleActionPopup extends StatelessWidget {
  final String moduleLabel;
  final String moduleTitle;
  final ModuleProgress progress;
  final bool postLocked;
  final VoidCallback onClose;
  final VoidCallback onPreTap;
  final VoidCallback onSimTap;
  final VoidCallback onPostTap;

  const _ModuleActionPopup({
    required this.moduleLabel,
    required this.moduleTitle,
    required this.progress,
    required this.postLocked,
    required this.onClose,
    required this.onPreTap,
    required this.onSimTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        moduleLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        moduleTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: context.tr('pre_assessment'),
                    enabled: true,
                    locked: false,
                    onTap: onPreTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineActionButton(
                    label: context.tr('simulation'),
                    enabled: true,
                    locked: false,
                    onTap: onSimTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineActionButton(
                    label: context.tr('post_assessment'),
                    enabled: !postLocked,
                    locked: postLocked,
                    onTap: onPostTap,
                    onLockedTap: postLocked
                        ? () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFB11217),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        context.tr('simulation_required'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  context.tr('simulation_required_message'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFB11217),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: Text(
                                      context.tr('ok'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onLockedTap;

  const _OutlineActionButton({
    required this.label,
    required this.enabled,
    required this.locked,
    required this.onTap,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        enabled ? const Color(0xFFB11217) : Colors.black.withOpacity(0.18);

    return InkWell(
      onTap: enabled ? onTap : onLockedTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
          color: enabled ? Colors.white : const Color(0xFFF6F6F6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.lock,
                  size: 16,
                  color: Color(0xFF999999),
                ),
              ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: enabled ? Colors.black : const Color(0xFF999999),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ModuleUnderConstructionPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ModuleUnderConstructionPage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFB11217),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 64,
                color: Color(0xFFB11217),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
