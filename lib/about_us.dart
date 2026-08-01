import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'localization/language_controller.dart';
import 'login.dart';
import 'widgets/main_tab_header.dart';
import 'profile_refresh_notifier.dart';

enum AboutFilter { all, about, team, bfpDasmarinas, contacts }

/// Index of the Profile tab within [IgnisHomePage]'s tab list
/// (Module = 0, About Us = 1, Profile = 2). Kept as a local constant
/// because importing `home.dart`'s `HomeTab` enum here would create a
/// circular import (home.dart already imports this file).
const int _profileTabIndex = 2;

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

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  static const Color brandRed = Color(0xFFB11217);

  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;

  // navbar
  // search + filter
  String _searchQuery = '';
  AboutFilter _filter = AboutFilter.all;

  @override
  void initState() {
    super.initState();
    profileRefreshNotifier.addListener(_handleProfileChanged);
    _loadProfile();
  }

  void _handleProfileChanged() => _loadProfile();

  @override
  void dispose() {
    profileRefreshNotifier.removeListener(_handleProfileChanged);
    super.dispose();
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
    widget.onRequestTabChange?.call(_profileTabIndex);
  }

  void _onSearchChanged(String v) => setState(() => _searchQuery = v);

  void _openFilterMenu(BuildContext context) async {
    final selected = await showMenu<AboutFilter>(
      context: context,
      position: const RelativeRect.fromLTRB(9999, 120, 16, 0),
      items: [
        PopupMenuItem(
          value: AboutFilter.all,
          child: Text(t(context, 'All', 'Lahat')),
        ),
        PopupMenuItem(
          value: AboutFilter.about,
          child: Text(t(context, 'About', 'Tungkol')),
        ),
        PopupMenuItem(
          value: AboutFilter.team,
          child: Text(t(context, 'Team', 'Koponan')),
        ),
        PopupMenuItem(
          value: AboutFilter.bfpDasmarinas,
          child: Text(t(context, 'BFP Dasmariñas', 'BFP Dasmariñas')),
        ),
        PopupMenuItem(
          value: AboutFilter.contacts,
          child: Text(t(context, 'Contacts', 'Mga Kontak')),
        ),
      ],
    );

    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  bool _matchesFilter(_AboutSection s) {
    switch (_filter) {
      case AboutFilter.all:
        return true;
      case AboutFilter.about:
        return s.type == _AboutSectionType.about;
      case AboutFilter.team:
        return s.type == _AboutSectionType.team;
      case AboutFilter.bfpDasmarinas:
        return s.type == _AboutSectionType.partner;
      case AboutFilter.contacts:
        return s.type == _AboutSectionType.contact;
    }
  }

  bool _matchesSearch(_AboutSection s, String q) {
    if (q.isEmpty) return true;
    final hay = ('${s.title} ${s.searchText}'.toLowerCase());
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.trim().toLowerCase();

    final sections = _buildSections();
    final visible = sections
        .where((s) => _matchesFilter(s) && _matchesSearch(s, q))
        .toList();
    final avatarProvider = _avatarUrl != null && _avatarUrl!.trim().isNotEmpty
        ? NetworkImage(_avatarUrl!) as ImageProvider
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          const MainTabHeaderBackdrop(height: 270),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compactWidth = width < 370;
                final horizontalPadding = compactWidth ? 16.0 : 22.0;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MainTabHeader(
                        greeting: _firstName.isEmpty && _lastName.isEmpty
                            ? t(context, 'Hi!', 'Kumusta!')
                            : t(
                                context,
                                'Hi, $_firstName $_lastName'.trim(),
                                'Kumusta, $_firstName $_lastName'.trim(),
                              ),
                        accountLabel: t(
                          context,
                          'Welcome to IGNIS SAFE',
                          'Mabuhay sa IGNIS SAFE',
                        ),
                        title: t(context, 'About Us', 'Tungkol sa Amin'),
                        subtitle: t(
                          context,
                          'Discover our mission, identity, and the people behind the app.',
                          'Kilalanin ang aming layunin, pagkakakilanlan, at ang team sa likod ng app.',
                        ),
                        titleIcon: Icons.info_rounded,
                        avatarImage: avatarProvider,
                        profileLabel: t(context, 'Profile', 'Profile'),
                        logoutLabel: t(context, 'Log Out', 'Mag-logout'),
                        onProfile: _goToProfile,
                        onLogout: _logout,
                      ),
                      const SizedBox(height: 20),
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
                                  hintText: t(context, 'Search', 'Maghanap'),
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: t(context, 'Filter', 'Salain'),
                              onPressed: () => _openFilterMenu(context),
                              icon: Icon(
                                Icons.filter_list_rounded,
                                color: _filter == AboutFilter.all
                                    ? const Color(0xFF9E9E9E)
                                    : brandRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildAboutContent(
                          visible: visible,
                          horizontalPadding: 0,
                          searchActive: q.isNotEmpty,
                        ),
                      ),
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

  Widget _buildAboutContent({
    required List<_AboutSection> visible,
    required double horizontalPadding,
    required bool searchActive,
  }) {
    return ScrollConfiguration(
      behavior: const _NoOverscrollScrollBehavior(),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (visible.isEmpty)
              _EmptyState(
                onClear: () => setState(() {
                  _searchQuery = '';
                  _filter = AboutFilter.all;
                }),
              )
            else
              for (int index = 0; index < visible.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visible.length - 1 ? 0 : 14,
                  ),
                  child: _ExpandableSectionCard(
                    key: ValueKey(visible[index].title),
                    icon: visible[index].icon,
                    title: visible[index].title,
                    subtitle: visible[index].subtitle,
                    initiallyExpanded: searchActive || index == 0,
                    child: visible[index].builder(context),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  List<_AboutSection> _buildSections() {
    return [
      _AboutSection(
        type: _AboutSectionType.about,
        title: "IGNIS SAFE",
        searchText: "Ignis Safe interactive 3D fire safety simulation mission",
        icon: Icons.local_fire_department_rounded,
        subtitle: t(
          context,
          "Our mission and what the app offers",
          "Ang aming misyon at inaalok ng app",
        ),
        builder: (context) => const _ModernAboutCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.about,
        title: t(context, "Logo Meaning", "Kahulugan ng Logo"),
        searchText:
            "logo shield fire truck hose flame water spray ignis latin fire safe protected secure mission prevention preparedness",
        icon: Icons.shield_rounded,
        subtitle: t(
          context,
          "The story behind our shield and flame",
          "Ang kuwento sa likod ng aming kalasag at apoy",
        ),
        builder: (context) => const _LogoMeaningCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.team,
        title: t(context, "Meet the Developers", "Kilalanin ang mga Developer"),
        searchText:
            "Fatima Klye M Sierra fatimaklyesierra081005@gmail.com Andrei C Quias Rave Paulo Sierra Sarah Flor Macandile Maricis Punzalan Adviser",
        icon: Icons.groups_rounded,
        subtitle: t(
          context,
          "The team behind Ignis Safe",
          "Ang koponan sa likod ng Ignis Safe",
        ),
        builder: (context) => const _TeamCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.partner,
        title: "BFP R4A Dasmariñas City Fire Station",
        searchText:
            "Bureau of Fire Protection Philippines fire safety education",
        icon: Icons.local_fire_department_outlined,
        subtitle: t(
          context,
          "Our partner fire station",
          "Aming kasosyong istasyon ng bumbero",
        ),
        builder: (context) => const _PartnerCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.contact,
        title: t(
          context,
          "Emergency Contact Information",
          "Impormasyon sa Emergency",
        ),
        searchText: "hotline emergency 046 884 6131 416 0875 0995 336 9534",
        icon: Icons.phone_in_talk_rounded,
        subtitle: t(
          context,
          "Hotlines you can call anytime",
          "Mga hotline na maaari mong tawagan",
        ),
        builder: (context) => const _ContactCard(),
      ),
      _AboutSection(
        type: _AboutSectionType.contact,
        title: t(context, "Cavite BFP Directory", "Direktoryo ng Cavite BFP"),
        searchText:
            "Office of the Provincial Fire Director Cavite City Kawit Noveleta Rosario Bacoor Imus Dasmarinas Carmona GMA Silang General Trias Amadeo Indang Tanza Trece Martires Alfonso Aguinaldo Magallanes Maragondon Mendez Naic Tagaytay Ternate",
        icon: Icons.apartment_rounded,
        subtitle: t(
          context,
          "Fire stations across Cavite by district",
          "Mga istasyon ng bumbero sa Cavite ayon sa distrito",
        ),
        builder: (context) => _CaviteBfpDirectoryCard(query: _searchQuery),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// Sections + UI blocks
// ─────────────────────────────────────────────────────────────

enum _AboutSectionType { about, team, partner, contact }

class _AboutSection {
  final _AboutSectionType type;
  final String title;
  final String searchText;
  final IconData icon;
  final String subtitle;
  final Widget Function(BuildContext) builder;

  _AboutSection({
    required this.type,
    required this.title,
    required this.searchText,
    required this.icon,
    required this.subtitle,
    required this.builder,
  });
}

class _ExpandableSectionCard extends StatefulWidget {
  static const Color brandRed = Color(0xFFB11217);

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const _ExpandableSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableSectionCard> createState() => _ExpandableSectionCardState();
}

class _ExpandableSectionCardState extends State<_ExpandableSectionCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _expanded
                    ? _ExpandableSectionCard.brandRed.withOpacity(0.35)
                    : const Color(0xFFF0F0F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _expanded
                          ? const [
                              _ExpandableSectionCard.brandRed,
                              Color(0xFFE65A5F),
                            ]
                          : const [Color(0xFFF3F3F3), Color(0xFFECECEC)],
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _expanded
                        ? Colors.white
                        : _ExpandableSectionCard.brandRed,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _expanded
                        ? _ExpandableSectionCard.brandRed
                        : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.child,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ModernAboutCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _ModernAboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brandRed, Color(0xFFE65A5F)],
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "IGNIS SAFE",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t(
                context,
                "An interactive 3D fire safety simulation that helps users learn proper prevention and emergency response through realistic, hands-on scenarios in a controlled environment.",
                "Isang interactive na 3D fire safety simulation na tumutulong sa mga gumagamit na matuto ng wastong pag-iwas at pagtugon sa emerhensiya sa pamamagitan ng mga makatotohanang senaryo sa kontroladong kapaligiran.",
              ),
              style: const TextStyle(
                height: 1.35,
                fontSize: 13.5,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  text: t(context, "3D Scenarios", "3D na Senaryo"),
                  icon: Icons.view_in_ar_rounded,
                ),
                _Chip(
                  text: t(
                    context,
                    "Hands-on Practice",
                    "Hands-on na Pagsasanay",
                  ),
                  icon: Icons.touch_app_rounded,
                ),
                _Chip(
                  text: t(context, "Safe Learning", "Ligtas na Pag-aaral"),
                  icon: Icons.verified_rounded,
                ),
                _Chip(
                  text: t(context, "Fire Awareness", "Kaalaman sa Sunog"),
                  icon: Icons.school_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: brandRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t(
                        context,
                        "Goal: Improve readiness through correct decision-making and proper extinguisher handling.",
                        "Layunin: Palakasin ang kahandaan sa pamamagitan ng tamang paggawa ng desisyon at wastong paggamit ng pamatay-sunog.",
                      ),
                      style: const TextStyle(
                        fontSize: 12.8,
                        height: 1.25,
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMeaningCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _LogoMeaningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: logo left + paragraph right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEDEDED)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      "assets/logo.png",
                      fit: BoxFit.fitHeight,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_rounded,
                        size: 46,
                        color: brandRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    t(
                      context,
                      "The IGNIS SAFE logo is built around a shield, symbolizing protection and safety. "
                          "The fire truck and hose show readiness to respond quickly during emergencies. "
                          "The flame represents fire risk, while the water spray represents control and prevention.",
                      "Ang logo ng IGNIS SAFE ay nakabase sa isang kalasag, na sumasalamin sa proteksyon at kaligtasan. "
                          "Ang fire truck at hose ay nagpapakita ng kahandaang tumugon nang mabilis sa mga emerhensiya. "
                          "Ang apoy ay kumakatawan sa panganib ng sunog, habang ang tubig ay kumakatawan sa kontrol at pag-iwas.",
                    ),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 12.8,
                      height: 1.35,
                      color: Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "IGNIS SAFE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: 0.6,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ignis / Safe blocks
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MeaningMiniBlock(
                    title: "Ignis",
                    body: t(
                      context,
                      "is a Latin word meaning fire.",
                      "ay isang salitang Latin na nangangahulugang apoy.",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MeaningMiniBlock(
                    title: "Safe",
                    body: t(
                      context,
                      "means protected or secure.",
                      "ay nangangahulugang protektado o ligtas.",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              t(
                context,
                "Together, Ignis Safe means protection from fire or fire safety. "
                    "It reflects a mission focused on preventing fire risks, ensuring preparedness, "
                    "and keeping people and property safe from fire-related hazards.",
                "Magkasama, ang Ignis Safe ay nangangahulugang proteksyon mula sa sunog o kaligtasan sa sunog. "
                    "Sumasalamin ito sa isang misyon na nakatuon sa pag-iwas sa panganib ng sunog, pagtitiyak ng kahandaan, "
                    "at pagpapanatiling ligtas ang mga tao at ari-arian mula sa mga panganib na may kaugnayan sa sunog.",
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              t(
                context,
                "Ignis Safe focuses on fire safety, prevention, and emergency preparedness.",
                "Ang Ignis Safe ay nakatuon sa kaligtasan sa sunog, pag-iwas, at paghahanda para sa emerhensiya.",
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              t(
                context,
                "It provides fire safety education, training, and awareness programs to help individuals and organizations "
                    "understand fire risks and how to respond properly during emergencies. It also supports inspection, compliance, "
                    "and safety reporting to strengthen overall fire protection systems.",
                "Nagbibigay ito ng edukasyon sa kaligtasan sa sunog, pagsasanay, at mga programa ng kamalayan upang matulungan "
                    "ang mga indibidwal at organisasyon na maunawaan ang mga panganib ng sunog at kung paano tumugon nang wasto sa mga emerhensiya. "
                    "Sinusuportahan din nito ang inspeksyon, pagsunod, at pag-uulat sa kaligtasan upang palakasin ang pangkalahatang sistema ng proteksyon sa sunog.",
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1D5D6)),
              ),
              child: Text(
                t(
                  context,
                  "In essence, Ignis Safe helps prevent fires, prepare people for emergencies, and protect lives and property.",
                  "Sa esensya, tinutulungan ng Ignis Safe ang pag-iwas sa sunog, paghahanda ng mga tao para sa mga emerhensiya, at pagprotekta ng buhay at ari-arian.",
                ),
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 12.8,
                  height: 1.35,
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeaningMiniBlock extends StatelessWidget {
  final String title;
  final String body;
  const _MeaningMiniBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.8,
            height: 1.25,
            color: Color(0xFF2D2D2D),
          ),
          children: [
            TextSpan(
              text: "$title ",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text: body,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard();

  @override
  Widget build(BuildContext context) {
    final team = [
      _TeamMember(
        fullName: "FATIMA KLYE M. SIERRA",
        displayFirst: "FATIMA",
        displayLast: "SIERRA",
        role: "MOBILE DEVELOPER",
        roleTl: "MOBILE DEVELOPER",
        email: "fatimaklyesierra081005@gmail.com",
        bio:
            "Manages mobile application & databases and supports project coordination. She also serves as an Assistant Project Manager, helping ensure timelines and deliverables are met efficiently.",
        bioTl:
            "Namamahala ng mobile application at mga database at sumusuporta sa koordinasyon ng proyekto. Nagsisilbi rin siya bilang Assistant Project Manager, na tumutulong na matiyak na natutugunan ang mga takdang oras at naihahatid ang mga resulta nang mahusay.",
        asset: "assets/dev_fatima1.jpg",
      ),
      _TeamMember(
        fullName: "ANDREI C. QUIAS",
        displayFirst: "ANDREI",
        displayLast: "QUIAS",
        role: "3D UNITY DEVELOPER",
        roleTl: "3D UNITY DEVELOPER",
        email: "",
        bio:
            "Builds interactive and immersive applications. He also serves as a Project Manager, overseeing planning, coordination, and timely delivery of projects.",
        bioTl:
            "Nagtatayo ng mga interactive at immersive na application. Nagsisilbi rin siya bilang Project Manager, na nangunguna sa pagpaplano, koordinasyon, at napapanahong paghahatid ng mga proyekto.",
        asset: "assets/dev_andrei.jpg",
      ),
      _TeamMember(
        fullName: "RAVE PAULO PIOLO V. SIERRA",
        displayFirst: "RAVE",
        displayLast: "SIERRA",
        role: "WEBSITE DEVELOPER",
        roleTl: "WEBSITE DEVELOPER",
        email: "",
        bio:
            "Responsible for designing, building, and maintaining responsive and functional websites, ensuring performance, usability, and a seamless user experience.",
        bioTl:
            "Responsable sa pagdidisenyo, pagtatayo, at pagpapanatili ng mga responsive at functional na website, na tinitiyak ang pagganap, kakayahang magamit, at maayos na karanasan ng gumagamit.",
        asset: "assets/dev_rave.png",
      ),
      _TeamMember(
        fullName: "SARAH FLOR MACANDILE",
        displayFirst: "SARAH",
        displayLast: "MACANDILE",
        role: "DOCUMENTATION",
        roleTl: "DOKUMENTASYON",
        email: "",
        bio:
            "Ensures that all project records, reports, and required materials are accurate, organized, and properly maintained to support compliance and operational efficiency.",
        bioTl:
            "Tinitiyak na ang lahat ng rekord ng proyekto, ulat, at mga kinakailangang materyales ay tumpak, organisado, at maayos na pinapanatili upang suportahan ang pagsunod at kahusayan sa operasyon.",
        asset: "assets/dev_sarah.jpg",
      ),
      _TeamMember(
        fullName: "MARICIS PUNZALAN",
        displayFirst: "MARICIS",
        displayLast: "PUNZALAN",
        role: "ADVISER",
        roleTl: "TAGAPAYO",
        email: "",
        bio:
            "Provides strategic guidance, oversight, and expert recommendations to support informed decision-making and overall project direction.",
        bioTl:
            "Nagbibigay ng estratehikong gabay, pangangasiwa, at mga rekomendasyon ng eksperto upang suportahan ang matalinong paggawa ng desisyon at pangkalahatang direksyon ng proyekto.",
        asset: "assets/dev_maricis.png",
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                context,
                "MEET OUR DEVELOPERS",
                "KILALANIN ANG AMING MGA DEVELOPER",
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB11217),
                letterSpacing: 0.4,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              child: Text(
                t(
                  context,
                  "We are the Ignis Safe Team, fourth-year BSIT students from National University – Dasmariñas.\n\n"
                      "Our group is developing a technology-driven fire safety education platform as part of our capstone project.\n\n "
                      "We focus on building interactive, user-centered solutions that promote fire awareness, prevention, and proper emergency response. "
                      "Our goal is to create a practical system with real-world relevance and community impact.",
                  "Kami ang Ignis Safe Team, mga fourth-year na mag-aaral ng BSIT mula sa National University – Dasmariñas.\n\n"
                      "Ang aming grupo ay nagde-develop ng isang technology-driven na platform para sa fire safety education bilang bahagi ng aming capstone project.\n\n "
                      "Nakatuon kami sa pagbuo ng mga interactive at user-centered na solusyon na nagtataguyod ng kaalaman sa sunog, pag-iwas, at wastong pagtugon sa emerhensiya. "
                      "Ang aming layunin ay lumikha ng isang praktikal na sistema na may kaugnayan sa totoong mundo at epekto sa komunidad.",
                ),
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 12.8,
                  height: 1.35,
                  color: Color(0xFF2D2D2D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 146,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: team.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _DevTile(m: team[i]),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t(
                context,
                "Tip: Tap any profile (optional) to open a short bio dialog.",
                "Tip: I-tap ang anumang profile (opsyonal) upang buksan ang maikling bio dialog.",
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "BFP R4A Dasmariñas City Fire Station",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t(
                context,
                "An official fire service unit operating under the Bureau of Fire Protection (BFP) in the Philippines. The BFP is a national government agency tasked with preventing and suppressing destructive fires, enforcing the Fire Code, and conducting community fire safety education nationwide.",
                "Isang opisyal na yunit ng serbisyong pangsunog na nag-ooperate sa ilalim ng Bureau of Fire Protection (BFP) sa Pilipinas. Ang BFP ay isang pambansang ahensya ng gobyerno na may tungkuling pigilan at supilin ang mga mapanwasak na sunog, ipatupad ang Fire Code, at magsagawa ng edukasyon sa kaligtasan sa sunog sa buong bansa.",
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                height: 1.35,
                fontSize: 13.2,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 14),

            // Dasmariñas City Fire Station block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF5F5), Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "DASMARIÑAS CITY FIRE STATION",
                    style: TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB11217),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // contacts
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 18,
                        color: Color(0xFFB11217),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t(
                            context,
                            "In case of Fire or other Emergencies, call:\n(046) 884-6131 / 416-0875 | 0995 336 9534",
                            "Sa kaso ng Sunog o iba pang Emerhensiya, tumawag sa:\n(046) 884-6131 / 416-0875 | 0995 336 9534",
                          ),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12.8,
                            height: 1.3,
                            color: Color(0xFF2D2D2D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Fire marshal
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "FCINSP MICHAEL JOHN V ESCAÑO",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t(
                            context,
                            "City Fire Marshal",
                            "Lungsod na Fire Marshal",
                          ),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              t(context, "Vision", "Bisyon"),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(
                context,
                "A modern fire service fully capable of ensuring a fire safe nation by 2034.",
                "Isang modernong serbisyong pangsunog na ganap na kayang tiyakin ang isang ligtas na bansang walang sunog sa taong 2034.",
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              t(context, "Mission", "Misyon"),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(
                context,
                "We commit to prevent and suppress destructive fires, investigate its causes; enforce Fire Code and other related laws; respond to man-made and natural disasters and other emergencies.",
                "Kami ay nakatuon sa pagpigil at pagsugpo ng mapanwasak na sunog, pagsisiyasat ng sanhi nito; pagpapatupad ng Fire Code at iba pang kaugnay na batas; pagtugon sa mga man-made at natural na sakuna at iba pang emerhensiya.",
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5F5), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: brandRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t(
                      context,
                      "Emergency Contact Information",
                      "Impormasyon sa Emergency",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              t(
                context,
                "In case of fire or other emergencies, the public may call the station's hotlines:",
                "Sa kaso ng sunog o iba pang emerhensiya, maaaring tumawag ang publiko sa mga hotline ng istasyon:",
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.local_phone_rounded,
              label: t(context, "Landline", "Landline"),
              value: "(046) 884-6131 / 416-0875",
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.smartphone_rounded,
              label: t(context, "Mobile", "Mobile"),
              value: "0995-336-9534",
              onTap: () {},
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              child: Text(
                t(
                  context,
                  "If you are in immediate danger, prioritize evacuation and follow local emergency procedures.",
                  "Kung ikaw ay nasa agarang panganib, unahin ang paglikas at sundin ang mga lokal na pamamaraan sa emerhensiya.",
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: Color(0xFF2D2D2D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB11217)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.25,
                  color: Color(0xFF2D2D2D),
                ),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
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

class _DevTile extends StatelessWidget {
  final _TeamMember m;
  const _DevTile({required this.m});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              m.fullName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, m.role, m.roleTl),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB11217),
                    ),
                  ),
                  if (m.email.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "EMAIL: ${m.email}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    t(context, m.bio, m.bioTl),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t(context, "Close", "Isara")),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 112,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: 52,
                child: Image.asset(
                  m.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFF2F2F2),
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF8C8C8C),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              m.displayFirst,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              m.displayLast,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(context, m.role, m.roleTl),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B6B6B),
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMember {
  final String fullName;
  final String displayFirst;
  final String displayLast;
  final String role;
  final String roleTl;
  final String email;
  final String bio;
  final String bioTl;
  final String asset;

  const _TeamMember({
    required this.fullName,
    required this.displayFirst,
    required this.displayLast,
    required this.role,
    required this.roleTl,
    required this.email,
    required this.bio,
    required this.bioTl,
    required this.asset,
  });
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxChipWidth = screenWidth > 82 ? screenWidth - 82 : screenWidth;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFB11217)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            t(context, "No results found.", "Walang nahanap na resulta."),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t(
              context,
              "Try a different keyword or reset filters.",
              "Subukan ang ibang keyword o i-reset ang mga filter.",
            ),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.25,
              color: Color(0xFF6B6B6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB11217),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                t(context, "Reset", "I-reset"),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaviteBfpDirectoryCard extends StatelessWidget {
  final String query;
  const _CaviteBfpDirectoryCard({required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // Filter groups and entries by query
    final filteredGroups = _caviteBfpGroups
        .map((g) {
          final entries = g.entries.where((e) {
            if (q.isEmpty) return true;
            final hay = [
              e.name,
              e.email,
              ...e.contacts,
            ].join(' ').toLowerCase();
            return hay.contains(q);
          }).toList();

          return _DirectoryGroup(title: g.title, entries: entries);
        })
        .where((g) {
          if (q.isEmpty) return true;
          final groupMatch = g.title.toLowerCase().contains(q);
          return groupMatch || g.entries.isNotEmpty;
        })
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5F5), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apartment_rounded, color: Color(0xFFB11217)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t(
                      context,
                      "Cavite BFP Directory",
                      "Direktoryo ng Cavite BFP",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t(
                context,
                "Search by station name, district, email, or number. Tap to call/email.",
                "Maghanap ayon sa pangalan ng istasyon, distrito, email, o numero. I-tap para tumawag/mag-email.",
              ),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.25,
                color: Color(0xFF5E5E5E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (filteredGroups.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                ),
                child: Text(
                  t(
                    context,
                    "No matching results in Cavite BFP Directory.",
                    "Walang katugmang resulta sa Direktoryo ng Cavite BFP.",
                  ),
                  style: const TextStyle(
                    fontSize: 12.8,
                    height: 1.25,
                    color: Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ...filteredGroups.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DistrictAccordion(
                    group: g,
                    initiallyExpanded: q.isNotEmpty,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DistrictAccordion extends StatelessWidget {
  final _DirectoryGroup group;
  final bool initiallyExpanded;
  const _DistrictAccordion({
    required this.group,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          collapsedIconColor: const Color(0xFFB11217),
          iconColor: const Color(0xFFB11217),
          title: Text(
            group.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B2B2B),
            ),
          ),
          children: group.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _DirectoryEntryTile(entry: e),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DirectoryEntryTile extends StatelessWidget {
  final _DirectoryEntry entry;
  const _DirectoryEntryTile({required this.entry});

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No compatible app is available.')),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$value copied')));
  }

  Uri _phoneUri(String value) =>
      Uri(scheme: 'tel', path: value.replaceAll(RegExp(r'[^0-9+]'), ''));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 10),

          // Email (tappable)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () =>
                _open(context, Uri(scheme: 'mailto', path: entry.email)),
            onLongPress: () => _copy(context, entry.email),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.email_rounded,
                    size: 18,
                    color: Color(0xFFB11217),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.email,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.8,
                        height: 1.25,
                        color: Color(0xFF2D2D2D),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy email',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copy(context, entry.email),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Phones (tappable chips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.contacts
                .map(
                  (c) => InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _open(context, _phoneUri(c)),
                    onLongPress: () => _copy(context, c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c,
                            style: const TextStyle(
                              fontSize: 12.2,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copy(context, c),
                            child: const Tooltip(
                              message: 'Copy phone number',
                              child: Icon(Icons.copy_rounded, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Directory data models + data
// ─────────────────────────────────────────────────────────────

class _DirectoryGroup {
  final String title;
  final List<_DirectoryEntry> entries;
  const _DirectoryGroup({required this.title, required this.entries});
}

class _DirectoryEntry {
  final String name;
  final String email;
  final List<String> contacts;
  const _DirectoryEntry({
    required this.name,
    required this.email,
    required this.contacts,
  });
}

const List<_DirectoryGroup> _caviteBfpGroups = [
  _DirectoryGroup(
    title: "Office of the Provincial Fire Director",
    entries: [
      _DirectoryEntry(
        name: "Provincial Fire Director – Cavite",
        email: "cavitebfp@yahoo.com",
        contacts: ["046-471-3747", "0943-386-8772", "0967-805-5581"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "First District",
    entries: [
      _DirectoryEntry(
        name: "Cavite City",
        email: "admn.cavcityfs@gmail.com",
        contacts: ["(046) 484-2899", "0966-694-1416"],
      ),
      _DirectoryEntry(
        name: "Kawit",
        email: "admn.bfpkawit@yahoo.com.ph",
        contacts: ["(046) 484-5250", "0966-132-0605"],
      ),
      _DirectoryEntry(
        name: "Noveleta",
        email: "noveletafirestation@gmail.com",
        contacts: ["(046) 438-5684", "0917-547-3696"],
      ),
      _DirectoryEntry(
        name: "Rosario",
        email: "admn.rosario.fire214@yahoo.com",
        contacts: ["(046) 438-1616", "0939-232-6045"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Second District",
    entries: [
      _DirectoryEntry(
        name: "Bacoor City",
        email: "bfpbacoor@yahoo.com",
        contacts: ["(046) 417-6060", "0966-695-9711"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Third District",
    entries: [
      _DirectoryEntry(
        name: "Imus City",
        email: "imuscfs@gmail.com",
        contacts: ["(046) 970-5161", "0966-705-9174"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Fourth District",
    entries: [
      _DirectoryEntry(
        name: "Dasmariñas City",
        email: "dasmafscavite@gmail.com",
        contacts: ["416-0875", "424-2537", "0995-336-9534"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Fifth District",
    entries: [
      _DirectoryEntry(
        name: "Carmona",
        email: "carmonafirestation@gmail.com",
        contacts: ["(046) 430-1666", "0915-602-1572"],
      ),
      _DirectoryEntry(
        name: "General Mariano Alvarez (GMA)",
        email: "gma.fire@yahoo.com",
        contacts: ["(046) 443-9110", "0938-781-9294", "0955-790-3765"],
      ),
      _DirectoryEntry(
        name: "Silang",
        email: "silangfirestation@yahoo.com",
        contacts: ["(046) 414-0484", "0915-602-1593"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Sixth District",
    entries: [
      _DirectoryEntry(
        name: "General Trias City",
        email: "gen3bfp210.admn@gmail.com",
        contacts: ["(046) 437-7625", "0917-593-1522"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Seventh District",
    entries: [
      _DirectoryEntry(
        name: "Amadeo",
        email: "amadeobfp@gmail.com",
        contacts: ["(046) 483-2490", "0915-601-6805"],
      ),
      _DirectoryEntry(
        name: "Indang",
        email: "indang_bfp@yahoo.com",
        contacts: ["(046) 415-1217", "0915-603-4245", "0933-824-5948"],
      ),
      _DirectoryEntry(
        name: "Tanza",
        email: "tanzafs@gmail.com",
        contacts: ["(046) 505-6084"],
      ),
      _DirectoryEntry(
        name: "Trece Martires City",
        email: "charliebase13@gmail.com",
        contacts: ["(046) 419-0057", "0918-425-7897"],
      ),
    ],
  ),
  _DirectoryGroup(
    title: "Eighth District",
    entries: [
      _DirectoryEntry(
        name: "Alfonso",
        email: "alfonsocavitefs@gmail.com",
        contacts: ["(046) 522-0480", "0915-602-2113"],
      ),
      _DirectoryEntry(
        name: "General Emilio Aguinaldo",
        email: "aguinaldo.firestation@gmail.com",
        contacts: ["0921-458-593", "0966-256-7730"],
      ),
      _DirectoryEntry(
        name: "Magallanes",
        email: "magallanes_firestation@yahoo.com",
        contacts: ["(046) 529-6245", "0915-602-1644"],
      ),
      _DirectoryEntry(
        name: "Maragondon",
        email: "maragondon219@gmail.com",
        contacts: ["(046) 412-1911", "0966-375-3790"],
      ),
      _DirectoryEntry(
        name: "Mendez",
        email: "mendez_firestation@yahoo.com",
        contacts: ["(046) 413-2237", "0977-200-1102"],
      ),
      _DirectoryEntry(
        name: "Naic",
        email: "bfpnaic.official@yahoo.com",
        contacts: ["(046) 412-1481", "0917-679-7861"],
      ),
      _DirectoryEntry(
        name: "Tagaytay City",
        email: "tagaytayfire@gmail.com",
        contacts: ["(046) 483-1193", "0942-989-8495"],
      ),
      _DirectoryEntry(
        name: "Ternate",
        email: "maragondon219@gmail.com",
        contacts: ["(046) 419-1911", "0966-375-9790"],
      ),
    ],
  ),
];
