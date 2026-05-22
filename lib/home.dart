import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'navbar.dart';
import 'learning_materials.dart';
import 'profile.dart';
import 'about_us.dart';

enum HomeTab { learn, profile, about }

class IgnisHomePage extends StatefulWidget {
  const IgnisHomePage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<IgnisHomePage> createState() => _IgnisHomePageState();
}

class _IgnisHomePageState extends State<IgnisHomePage> {
  static const String _kLastTab = 'last_tab_index';

  late HomeTab _currentTab;

  final List<IconData> _icons = const [
    Icons.menu_book_rounded,
    Icons.person_outline_rounded,
    Icons.info_outline_rounded,
  ];

  late final List<Widget> _pages = [
    LearningMaterialsTab(
      onRequestTabChange: _onItemTapped,
    ),
    const ProfilePage(),
    AboutUsPage(
      onRequestTabChange: _onItemTapped,
    ),
  ];

  int get _selectedIndex => _currentTab.index;

  @override
  void initState() {
    super.initState();

    final safeInitial =
        widget.initialTabIndex.clamp(0, HomeTab.values.length - 1);
    _currentTab = HomeTab.values[safeInitial];

    _restoreLastTab();
  }

  Future<void> _restoreLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastTab);

    if (!mounted || saved == null) return;
    if (saved < 0 || saved >= HomeTab.values.length) return;

    setState(() {
      _currentTab = HomeTab.values[saved];
    });
  }

  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastTab, index);
  }

  void _onItemTapped(int index) {
    if (index < 0 || index >= HomeTab.values.length) return;
    if (index == _selectedIndex) return;

    setState(() {
      _currentTab = HomeTab.values[index];
    });

    _saveLastTab(index);
  }

  Widget _buildBody() {
    return Stack(
      children: List.generate(_pages.length, (i) {
        final isActive = i == _selectedIndex;

        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: TickerMode(
              enabled: isActive,
              child: _pages[i],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        icons: _icons,
      ),
    );
  }
}