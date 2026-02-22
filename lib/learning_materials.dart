import 'package:flutter/material.dart';
import 'module1.dart';
import 'navbar.dart';

class LearningMaterialsPage extends StatefulWidget {
  const LearningMaterialsPage({super.key});

  @override
  State<LearningMaterialsPage> createState() => _LearningMaterialsPageState();
}

class _LearningMaterialsPageState extends State<LearningMaterialsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _LearningMaterialsContent(),
    Center(child: Text("3D Simulation Page")),
    Center(child: Text("About Us Page")),
    Center(child: Text("Profile Page")),
  ];

  final List<IconData> _icons = const [
    Icons.menu_book_rounded,
    Icons.view_in_ar_rounded,
    Icons.info_outline_rounded,
    Icons.person_outline_rounded,
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        icons: _icons,
      ),
    );
  }
}

class _LearningMaterialsContent extends StatefulWidget {
  const _LearningMaterialsContent();

  @override
  State<_LearningMaterialsContent> createState() =>
      _LearningMaterialsContentState();
}

class _LearningMaterialsContentState extends State<_LearningMaterialsContent> {
  String searchQuery = "";

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

  @override
  Widget build(BuildContext context) {
    final filtered = modules.where((m) {
      final q = searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return m.title.toLowerCase().contains(q) ||
          m.moduleLabel.toLowerCase().contains(q);
    }).toList();

   return Stack(
  children: [
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 900,
      child: Image.asset(
        'assets/bg.png',
        fit: BoxFit.cover,
      ),
    ),


        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header: avatar + welcome + name
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage("assets/avatar.png"),
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

                // Big title (centered)
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

                // Search bar
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

                const SizedBox(height: 45),

                // Cards
                for (final m in filtered) ...[
                  _ModuleCard(
                    moduleLabel: m.moduleLabel,
                    title: m.title,
                    description: m.description,
                    asset: m.asset,
                    onPressed: () {
                      // Replace these routes with your real pages
                      if (m.moduleLabel == "MODULE 1") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningMaterialPage(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 25),
                ],

                const SizedBox(height: 90), // spacing above nav bar
              ],
            ),
          ),
        ),
      ],
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
        // Card
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
              // Left image (square like screenshot)
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

              // Text + button
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
                                horizontal: 12, vertical: 0),
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

        // Module pill (top-left, outside card)
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
                )
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
