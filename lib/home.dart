import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'navbar.dart';
import 'learning_materials.dart';
import 'firemodules.dart';
import 'profile.dart';

class IgnisHomePage extends StatefulWidget {
  const IgnisHomePage({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  State<IgnisHomePage> createState() => _IgnisHomePageState();
}

class _IgnisHomePageState extends State<IgnisHomePage> {
  static const String _kLastTab = 'last_tab_index';

  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<IconData> _icons = const [
    Icons.menu_book_rounded,
    Icons.view_in_ar_rounded,
    Icons.person_outline_rounded,
    Icons.info_outline_rounded,
  ];

  late final List<Widget> _pages = const [
    LearningMaterialsTab(), // content-only
    FireMaterialsTab(),
    ProfilePage(),     // content-only
    Center(child: Text("About Us Page")),
    
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _restoreLastTab();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _restoreLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastTab);
    if (!mounted || saved == null) return;

    setState(() => _selectedIndex = saved);
    _pageController.jumpToPage(saved); // no animation on app start
  }

  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastTab, index);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
    _saveLastTab(index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ Smooth slide between tabs (no Navigator)
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // keep taps-only
        onPageChanged: (i) {
          setState(() => _selectedIndex = i);
          _saveLastTab(i);
        },
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