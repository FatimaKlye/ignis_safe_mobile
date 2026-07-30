import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'navbar.dart';
import 'learning_materials.dart';
import 'about_us.dart';
import 'profile.dart';

enum HomeTab { module, about, profile }

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
    Icons.menu_book_outlined,
    Icons.info_outline_rounded,
    Icons.person_outline_rounded,
  ];

  final List<IconData> _activeIcons = const [
    Icons.menu_book_rounded,
    Icons.info_rounded,
    Icons.person_rounded,
  ];

  late final List<Widget> _pages = [
    LearningMaterialsTab(
      onRequestTabChange: _onItemTapped,
    ),
    AboutUsPage(
      onRequestTabChange: _onItemTapped,
    ),
    const ProfilePage(),
  ];

  int get _selectedIndex => _currentTab.index;

  int _safeTabIndex(int index) {
    return index.clamp(0, HomeTab.values.length - 1).toInt();
  }

  @override
  void initState() {
    super.initState();

    _currentTab = HomeTab.values[_safeTabIndex(widget.initialTabIndex)];
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
    final safeIndex = _safeTabIndex(index);

    if (safeIndex == _selectedIndex) return;

    setState(() {
      _currentTab = HomeTab.values[safeIndex];
    });

    _saveLastTab(safeIndex);
  }

  Widget _buildBody() {
    return Stack(
      children: List.generate(_pages.length, (index) {
        final isActive = index == _selectedIndex;

        return Positioned.fill(
          child: IgnorePointer(
            ignoring: !isActive,
            child: AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: TickerMode(
                enabled: isActive,
                child: _pages[index],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: _buildBody(),
        bottomNavigationBar: FloatingNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          icons: _icons,
          activeIcons: _activeIcons,
          labels: const ['Module', 'About', 'Profile'],
          activeColor: const Color(0xFF111111),
          inactiveColor: const Color(0xFF6F6F6F),
          navBarColor: Colors.white.withOpacity(0.68),
          borderColor: Colors.black.withOpacity(0.10),
          navBarHeight: 62.0,
          horizontalMargin: 28.0,
          bottomPadding: 14.0,
          blurSigma: 22.0,
        ),
      ),
    );
  }
}
