import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'module1.dart';
import 'module2.dart';
import 'module3.dart';
import 'navbar.dart';
import 'login.dart';

// ✅ If you have a Profile page/screen file, import it here.
// If your app uses a bottom-nav “Profile tab” instead of a separate page,
// keep this import anyway OR replace the navigation below with your tab logic.
import 'profile.dart';

class LearningMaterialsTab extends StatefulWidget {
  const LearningMaterialsTab({super.key});

  @override
  State<LearningMaterialsTab> createState() => _LearningMaterialsTabState();
}

class _LearningMaterialsTabState extends State<LearningMaterialsTab> {
  String searchQuery = "";

  // ✅ If you want “Profile” to switch tabs (not push a page),
  // set this to the index of your Profile tab in your main navbar screen.
  // If you DON’T have a global tab index here, keep it and use push instead.
  static const int _profileTabIndex = 3;

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
    // OPTION A (recommended for your current file): push Profile page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );

    // OPTION B (only if your app uses a main navbar screen and you want to jump tabs):
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt('last_tab_index', _profileTabIndex);
    // if (!mounted) return;
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (_) => const MainNavShell()), // <-- replace with YOUR navbar screen
    //   (route) => false,
    // );
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
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage("assets/avatar.png"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Hi, Andrei Quias",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
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
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: 5 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 25),
                      itemBuilder: (context, index) {
                        final m = filtered[index];
                        return _ModuleCard(
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 26,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB11217),
                            elevation: 6,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: onPressed,
                          child: const Text(
                            "Learn Materials",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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