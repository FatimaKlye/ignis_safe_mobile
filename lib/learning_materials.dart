import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'module_1.dart/module1.dart';
import 'module_2.dart/module2.dart';
import 'module_3.dart/module3.dart';
import 'login.dart';
import 'profile.dart';


class LearningMaterialsTab extends StatefulWidget {
  const LearningMaterialsTab({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<LearningMaterialsTab> createState() => _LearningMaterialsTabState();
}

class _LearningMaterialsTabState extends State<LearningMaterialsTab> {
  String searchQuery = "";
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
          .select('first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted || data == null) return;
      setState(() {
        _firstName = data['first_name'] ?? '';
        _lastName = data['last_name'] ?? '';
      });
      // avatar_url fetched separately — column may not exist yet
      try {
        final av = await Supabase.instance.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (mounted && av != null) {
          setState(() => _avatarUrl = av['avatar_url'] as String?);
        }
      } catch (_) {}
    } catch (_) {}
  }

  final List<_ModuleItem> modules = const [
    _ModuleItem(
      moduleLabel: "MODULE 1",
      title: "FIRE EXTINGUISHER",
      description:
          "Learn the proper and safe use of fire extinguishers for effective response during fire emergencies.",
      asset: "assets/fire_ex.png",
    ),
    _ModuleItem(
      moduleLabel: "MODULE 2",
      title: "ELECTRICAL FIRE",
      description:
          "Learn how electrical fires occur and the correct actions to take during an electrical fire emergency.",
      asset: "assets/electrical.png",
    ),
    _ModuleItem(
      moduleLabel: "MODULE 3",
      title: "KITCHEN FIRE",
      description:
          "Understand safe cooking practices and proper response to grease and oil fires.",
      asset: "assets/kitchen.png",
    ),
  ];

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
    widget.onRequestTabChange?.call(2); // change 3 to your actual Profile tab index
  }

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final filtered = modules.where((m) {
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

                  // ✅ HEADER (avatar is a menu button: Profile / Logout)
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
                            'Hi, $_firstName $_lastName'.trim() == 'Hi,' ? 'Hi!' : 'Hi, $_firstName $_lastName'.trim(),
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
                      "Learning Materials",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
             
                  // ✅ SEARCH
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
                            onChanged: (v) => setState(() => searchQuery = v),
                            decoration: const InputDecoration(
                              hintText: "Search",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ LIST
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 14,
                        bottom: (MediaQuery.of(context).padding.bottom - 25)
                            .clamp(0.0, 999.0),
                      ),
                      child: Column(
                        children: filtered.asMap().entries.map((entry) {
                          final index = entry.key;
                          final m = entry.value;
                          final isLast = index == filtered.length - 1;

                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
                            child: _ModuleCard(
                              moduleLabel: m.moduleLabel,
                              title: m.title,
                              description: m.description,
                              asset: m.asset,
                              onPressed: () {
                                if (m.moduleLabel == "MODULE 1") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LearningMaterialExtinguisherPage(),
                                    ),
                                  );
                                } else if (m.moduleLabel == "MODULE 2") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LearningMaterialElectricalPage(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LearningMaterialKitchenPage(),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
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
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;

  const _ModuleItem({
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
  });
}

class _ModuleCard extends StatelessWidget {
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;
  final VoidCallback onPressed;

  const _ModuleCard({
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
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
                        const Spacer(),
                        SizedBox(
                          height: 26,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB11217),
                              elevation: 6,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
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