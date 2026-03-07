// fire_materials_tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'module_1.dart/pre_test_module1.dart';
import 'module_1.dart/simulation_scene.dart';

import 'module_2.dart/simulation_scene.dart' as sim2;
import 'module_3.dart/simulation_scene.dart' as sim3;
import 'module_2.dart/pre_test_module2.dart' as pre2;
import 'module_3.dart/pre_test_module3.dart' as pre3;
import 'profile.dart';
import 'login.dart';

enum ModuleFilter { all, pending, inProgress, completed }

class FireMaterialsTab extends StatefulWidget {
  const FireMaterialsTab({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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
        _firstName = data['first_name'] ?? '';
        _lastName = data['last_name'] ?? '';
        _avatarUrl = data['avatar_url'] as String?;
      });
    } catch (_) {}
  }

  final List<_ModuleItem> _modules = const [
    _ModuleItem(
      moduleId: "1",
      moduleLabel: "MODULE 1",
      title: "FIRE EXTINGUISHER",
      description:
          "Learn the proper and safe use of fire extinguishers for effective response during fire emergencies.",
      asset: "assets/fire_ex.png",
    ),
    _ModuleItem(
      moduleId: "2",
      moduleLabel: "MODULE 2",
      title: "ELECTRICAL FIRE",
      description:
          "Learn how electrical fires occur and the correct actions to take during an electrical fire emergency.",
      asset: "assets/electrical.png",
    ),
    _ModuleItem(
      moduleId: "3",
      moduleLabel: "MODULE 3",
      title: "KITCHEN FIRE",
      description:
          "Understand safe cooking practices and proper response to grease and oil fires.",
      asset: "assets/kitchen.png",
    ),
  ];

  void _onSearchChanged(String v) => setState(() => _searchQuery = v);

  // ✅ Your logout (fixed + included here so it won't error)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_tab_index');
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _goToProfile() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  // ---------- POPUP TRIGGER FROM "VIEW" ----------
  Future<void> _openModuleActions(_ModuleItem m) async {
    final progress = await ModuleProgressStore.load(m.moduleId);
    if (!mounted) return;

    await _showCenteredPopup(m, progress);

    if (mounted) setState(() {}); // refresh progress UI after closing
  }

  // ---------- Centered popup with blur ----------
  Future<void> _showCenteredPopup(_ModuleItem m, ModuleProgress progress) async {
    if (!mounted) return;

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
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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

  void _goToPre(_ModuleItem m) {
    if (m.moduleId == "1") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PreAssessmentIntroPage(),
        ),
      );
    } else if (m.moduleId == "2") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const pre2.PreAssessmentIntroPage2(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const pre3.PreAssessmentIntroPage2(),
        ),
      );
    }
  }

  void _goToSim(_ModuleItem m) {
    if (m.moduleId == "1") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SimulationScene(),
        ),
      );
    } else if (m.moduleId == "2") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const sim2.SimulationScene2(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const sim3.SimulationScene3(),
        ),
      );
    }
  }

  void _goToPost(_ModuleItem m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PlaceholderPage(title: "${m.moduleLabel} - Post Assessment"),
      ),
    );
  }

  // ---------- FILTER MENU (inside search bar) ----------
  Future<void> _openFilterMenu(BuildContext context) async {
    final selected = await showMenu<ModuleFilter>(
      context: context,
      position: const RelativeRect.fromLTRB(9999, 120, 16, 0),
      items: const [
        PopupMenuItem(value: ModuleFilter.all, child: Text("All")),
        PopupMenuItem(
          value: ModuleFilter.pending,
          child: Text("Pending / Not Started"),
        ),
        PopupMenuItem(value: ModuleFilter.inProgress, child: Text("In Progress")),
        PopupMenuItem(value: ModuleFilter.completed, child: Text("Completed")),
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

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.trim().toLowerCase();

    // ✅ Search filter first so the list doesn't render empty separators
    final searchedModules = _modules.where((m) {
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
            height: 900,
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ✅ header (avatar menu)
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
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "profile",
                            child: Row(
                              children: [
                                Icon(Icons.person_outline_rounded),
                                SizedBox(width: 8),
                                Text("Profile"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: "logout",
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded),
                                SizedBox(width: 8),
                                Text("Log Out"),
                              ],
                            ),
                          ),
                        ],
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade400,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : null,
                          child: _avatarUrl == null
                              ? const Icon(Icons.person, size: 22, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _firstName.isEmpty && _lastName.isEmpty
                                ? 'Hi!'
                                : 'Hi, $_firstName $_lastName'.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Welcome to Ignis Safe",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      "Fire Scenario Module",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // search + filter
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
                            decoration: const InputDecoration(
                              hintText: "Search",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Filter",
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
              child: ListView.builder(
                clipBehavior: Clip.none, // ✅ allow overflow (pill + shadow)
                padding: EdgeInsets.only(
                  top: 14, 
                  bottom: 10 + MediaQuery.of(context).padding.bottom,
                ),
                itemCount: searchedModules.length,
                itemBuilder: (context, index) {
                  final m = searchedModules[index];

                  return FutureBuilder<ModuleProgress>(
                    future: ModuleProgressStore.load(m.moduleId),
                    builder: (context, snap) {
                      final progress = snap.data ??
                          const ModuleProgress(preDone: false, simDone: false, postDone: false);

                      if (!_matchesFilter(progress)) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25),
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

/* ---------------------- Data model ---------------------- */

class _ModuleItem {
  final String moduleId;
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;

  const _ModuleItem({
    required this.moduleId,
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
  });
}

/* ---------------------- Progress storage ---------------------- */

class ModuleProgressStore {
  static String _k(String moduleId, String key) => 'module_${moduleId}_$key';

  static Future<ModuleProgress> load(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    return ModuleProgress(
      preDone: prefs.getBool(_k(moduleId, 'pre')) ?? false,
      simDone: prefs.getBool(_k(moduleId, 'sim')) ?? false,
      postDone: prefs.getBool(_k(moduleId, 'post')) ?? false,
    );
  }

  static Future<void> setPreDone(String moduleId, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k(moduleId, 'pre'), v);
  }

  static Future<void> setSimDone(String moduleId, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k(moduleId, 'sim'), v);
  }

  static Future<void> setPostDone(String moduleId, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k(moduleId, 'post'), v);
  }
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

  double get value {
    if (postDone) return 1.0;
    if (simDone) return 0.66;
    if (preDone) return 0.33;
    return 0.0;
  }

  int get percent => (value * 100).round();

  Color get color {
    if (postDone) return const Color(0xFF2EB872);
    if (simDone) return const Color(0xFFF2C94C);
    return const Color(0xFFB11217);
  }
}

/* ---------------------- Module card ---------------------- */

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
                width: 90,
                height: 90,
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
                          "${progress.percent}%",
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(progress.color),
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
                            child: const Text(
                              "View",
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

/* ---------------------- Popup UI (Module Actions) ---------------------- */

class _ModuleActionPopup extends StatelessWidget {
  final String moduleLabel;
  final String moduleTitle;
  final ModuleProgress progress;
  final VoidCallback onClose;
  final VoidCallback onPreTap;
  final VoidCallback onSimTap;
  final VoidCallback onPostTap;

  const _ModuleActionPopup({
    required this.moduleLabel,
    required this.moduleTitle,
    required this.progress,
    required this.onClose,
    required this.onPreTap,
    required this.onSimTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final postLocked = !progress.simDone;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        moduleLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        moduleTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Color(0xFF444444),
                        ),
                        textAlign: TextAlign.center,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: "PRE -\nASSESSMENT",
                    enabled: true,
                    locked: false,
                    onTap: onPreTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineActionButton(
                    label: "SIMULATION",
                    enabled: true,
                    locked: false,
                    onTap: onSimTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineActionButton(
                    label: "POST -\nASSESSMENT",
                    enabled: !postLocked,
                    locked: postLocked,
                    onTap: onPostTap,
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

  const _OutlineActionButton({
    required this.label,
    required this.enabled,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        enabled ? const Color(0xFFB11217) : Colors.black.withOpacity(0.18);

    return InkWell(
      onTap: enabled ? onTap : null,
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
                child: Icon(Icons.lock, size: 16, color: Color(0xFF999999)),
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: enabled ? Colors.black : const Color(0xFF999999),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------- Placeholder page ---------------------- */

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text("Replace this with your real page.")),
    );
  }
}