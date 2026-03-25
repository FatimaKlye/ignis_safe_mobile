import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'module_1_extinguisher.dart/module_1_learningmaterials.dart';
import 'module_2_house.dart/module_2_learningmaterials.dart' as house_learning;
import 'module_3_electrical.dart/module_3_learningmaterials.dart' as electrical_learning;
import 'module_4_kitchen.dart/module_4_learningmaterials.dart' as kitchen_learning;
import 'module_5_building.dart/module_5_learningmaterials.dart' as building_learning;
import 'login.dart';

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
          .select('first_name, last_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || data == null) return;

      setState(() {
        _firstName = (data['first_name'] ?? '').toString();
        _lastName = (data['last_name'] ?? '').toString();
        _avatarUrl = data['avatar_url'] as String?;
      });
    } catch (_) {}
  }

  final List<_ModuleItem> modules = const [
    _ModuleItem(
      moduleLabel: "MODULE 1",
      title: "FIRE EXTINGUISHER",
      description:
          "Learn the proper and safe use of fire extinguishers for effective response during fire emergencies.",
      asset: "assets/fire_ex.png",
      moduleNo: 1,
    ),
    _ModuleItem(
      moduleLabel: "MODULE 2",
      title: "HOUSE FIRE",
      description:
          "Learn the common causes of house fires and the correct actions to take during a residential fire emergency.",
      asset: "assets/house.jpg",
      moduleNo: 2,
    ),
    _ModuleItem(
      moduleLabel: "MODULE 3",
      title: "ELECTRICAL FIRE",
      description:
          "Learn how electrical fires occur and the correct actions to take during an electrical fire emergency.",
      asset: "assets/electrical.png",
      moduleNo: 3,
    ),
    _ModuleItem(
      moduleLabel: "MODULE 4",
      title: "KITCHEN FIRE",
      description:
          "Understand safe cooking practices and proper response to grease and oil fires.",
      asset: "assets/kitchen.png",
      moduleNo: 4,
    ),
    _ModuleItem(
      moduleLabel: "MODULE 5",
      title: "BUILDING FIRE",
      description:
          "Learn how to respond safely during building fire incidents, including evacuation and hazard awareness.",
      asset: "assets/condo.jpg",
      moduleNo: 5,
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
    widget.onRequestTabChange?.call(2);
  }

  void _openModule(int moduleNo) {
    switch (moduleNo) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LearningMaterialExtinguisherPage(),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const house_learning.LearningMaterialHousePage(),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const electrical_learning.LearningMaterialElectricalPage(),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const kitchen_learning.LearningMaterialKitchenPage(),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const building_learning.LearningMaterialTenementPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final filtered = modules.where((m) {
      if (q.isEmpty) return true;
      return m.title.toLowerCase().contains(q) ||
          m.moduleLabel.toLowerCase().contains(q);
    }).toList();

    final greetingName = '$_firstName $_lastName'.trim();
    final greeting = greetingName.isEmpty ? 'Hi!' : 'Hi, $greetingName';

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
                          backgroundColor: Colors.grey,
                          backgroundImage: (_avatarUrl != null &&
                                  _avatarUrl!.trim().isNotEmpty)
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: (_avatarUrl == null || _avatarUrl!.trim().isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 22,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
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

                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        top: 14,
                        bottom: (MediaQuery.of(context).padding.bottom + 20)
                            .clamp(20.0, 999.0),
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final m = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: _ModuleCard(
                            moduleLabel: m.moduleLabel,
                            title: m.title,
                            description: m.description,
                            asset: m.asset,
                            onPressed: () => _openModule(m.moduleNo),
                          ),
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
  final String moduleLabel;
  final String title;
  final String description;
  final String asset;
  final int moduleNo;

  const _ModuleItem({
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.asset,
    required this.moduleNo,
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
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_fire_department,
                    size: 42,
                    color: Color(0xFFB11217),
                  ),
                ),
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