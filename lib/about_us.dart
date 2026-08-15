import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'localization/language_controller.dart';
import 'login.dart';
import 'widgets/main_tab_header.dart';
import 'profile_refresh_notifier.dart';

enum AboutFilter { all, about, bfpDasmarinas, contacts }

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
  String _searchQuery = '';
  AboutFilter _filter = AboutFilter.all;
  _AboutUsData? _aboutData;
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    profileRefreshNotifier.addListener(_handleProfileChanged);
    _loadProfile();
    _loadAboutUs();
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
        _firstName = (data['first_name'] ?? '').toString();
        _lastName = (data['last_name'] ?? '').toString();
        _avatarUrl = data['avatar_url'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _loadAboutUs() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final client = Supabase.instance.client;
      final responses = await Future.wait<dynamic>([
        client.from('about_us_ui_texts').select('key,text_en,text_tl'),
        client
            .from('about_us_sections')
            .select()
            .eq('is_active', true)
            .order('display_order'),
        client.from('about_us_ignis').select().eq('section_key', 'ignis_safe').single(),
        client
            .from('about_us_ignis_chips')
            .select()
            .eq('section_key', 'ignis_safe')
            .eq('is_active', true)
            .order('display_order'),
        client
            .from('about_us_name_meanings')
            .select()
            .eq('section_key', 'ignis_safe')
            .eq('is_active', true)
            .order('display_order'),
        client
            .from('about_us_team_members')
            .select()
            .eq('section_key', 'ignis_safe')
            .eq('is_active', true)
            .order('display_order'),
        client
            .from('about_us_partner_info')
            .select()
            .eq('section_key', 'bfp_dasmarinas')
            .single(),
        client
            .from('about_us_emergency_info')
            .select()
            .eq('section_key', 'emergency_contacts')
            .single(),
        client
            .from('about_us_emergency_numbers')
            .select()
            .eq('section_key', 'emergency_contacts')
            .eq('is_active', true)
            .order('display_order'),
        client
            .from('about_us_contact_points')
            .select()
            .eq('is_active', true),
        client
            .from('about_us_partner_contact_links')
            .select()
            .eq('section_key', 'bfp_dasmarinas')
            .order('display_order'),
        client
            .from('about_us_directory_info')
            .select()
            .eq('section_key', 'cavite_directory')
            .single(),
        client
            .from('about_us_directory_groups')
            .select()
            .eq('section_key', 'cavite_directory')
            .eq('is_active', true)
            .order('display_order'),
        client
            .from('about_us_directory_entries')
            .select()
            .eq('is_active', true)
            .order('display_order'),
        client
            .from('about_us_directory_phones')
            .select()
            .eq('is_active', true)
            .order('display_order'),
      ]);

      final uiTexts = <String, _LocalizedText>{};
      for (final raw in (responses[0] as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        uiTexts[row['key'].toString()] = _LocalizedText.fromRow(
          row,
          enKey: 'text_en',
          tlKey: 'text_tl',
        );
      }

      final sectionRows = (responses[1] as List)
          .map((e) => _SectionRecord.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();

      final ignis = _IgnisRecord.fromRow(
        Map<String, dynamic>.from(responses[2] as Map),
        chips: (responses[3] as List)
            .map((e) => _IgnisChip.fromRow(Map<String, dynamic>.from(e as Map)))
            .toList(),
        meanings: (responses[4] as List)
            .map((e) => _NameMeaning.fromRow(Map<String, dynamic>.from(e as Map)))
            .toList(),
        team: (responses[5] as List)
            .map((e) => _TeamMember.fromRow(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

      final contactPoints = <String, _ContactPoint>{};
      for (final raw in (responses[9] as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final point = _ContactPoint.fromRow(row);
        contactPoints[point.key] = point;
      }

      final partnerContactKeys = (responses[10] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)['contact_key'].toString())
          .toList();

      final partner = _PartnerRecord.fromRow(
        Map<String, dynamic>.from(responses[6] as Map),
        contacts: partnerContactKeys
            .map((key) => contactPoints[key]!)
            .toList(),
      );

      final emergency = _EmergencyRecord.fromRow(
        Map<String, dynamic>.from(responses[7] as Map),
        numbers: (responses[8] as List)
            .map((e) {
              final row = Map<String, dynamic>.from(e as Map);
              return _EmergencyNumber.fromRow(
                row,
                contact: contactPoints[row['contact_key'].toString()]!,
              );
            })
            .toList(),
      );

      final directoryInfo = _DirectoryInfo.fromRow(
        Map<String, dynamic>.from(responses[11] as Map),
      );
      final groupRows = (responses[12] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final entryRows = (responses[13] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final phoneRows = (responses[14] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final phonesByEntry = <String, List<_DirectoryPhone>>{};
      for (final row in phoneRows) {
        final key = row['entry_key'].toString();
        phonesByEntry.putIfAbsent(key, () => []).add(_DirectoryPhone.fromRow(row));
      }

      final entriesByGroup = <String, List<_DirectoryEntry>>{};
      for (final row in entryRows) {
        final groupKey = row['group_key'].toString();
        final entryKey = row['entry_key'].toString();
        entriesByGroup.putIfAbsent(groupKey, () => []).add(
              _DirectoryEntry.fromRow(
                row,
                phones: phonesByEntry[entryKey] ?? const [],
              ),
            );
      }

      final groups = groupRows
          .map(
            (row) => _DirectoryGroup.fromRow(
              row,
              entries: entriesByGroup[row['group_key'].toString()] ?? const [],
            ),
          )
          .toList();

      final data = _AboutUsData(
        uiTexts: uiTexts,
        sections: sectionRows,
        ignis: ignis,
        partner: partner,
        emergency: emergency,
        directoryInfo: directoryInfo,
        directoryGroups: groups,
      );

      if (!mounted) return;
      setState(() {
        _aboutData = data;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load About Us content: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  String _ui(BuildContext context, String key) {
    final value = _aboutData!.uiTexts[key]!;
    return value.resolve(context);
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

  Future<void> _openFilterMenu(BuildContext context) async {
    final selected = await showMenu<AboutFilter>(
      context: context,
      position: const RelativeRect.fromLTRB(9999, 120, 16, 0),
      items: [
        PopupMenuItem(value: AboutFilter.all, child: Text(_ui(context, 'filter_all'))),
        PopupMenuItem(value: AboutFilter.about, child: Text(_ui(context, 'filter_about'))),
        PopupMenuItem(
          value: AboutFilter.bfpDasmarinas,
          child: Text(_ui(context, 'filter_partner')),
        ),
        PopupMenuItem(
          value: AboutFilter.contacts,
          child: Text(_ui(context, 'filter_contacts')),
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
      case AboutFilter.bfpDasmarinas:
        return s.type == _AboutSectionType.partner;
      case AboutFilter.contacts:
        return s.type == _AboutSectionType.contact;
    }
  }

  bool _matchesSearch(_AboutSection s, String q) {
    if (q.isEmpty) return true;
    return s.searchText.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatarUrl != null && _avatarUrl!.trim().isNotEmpty
        ? NetworkImage(_avatarUrl!) as ImageProvider
        : null;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/bg.png', fit: BoxFit.cover)),
            const MainTabHeaderBackdrop(height: 270),
            const SafeArea(
              child: Center(child: CircularProgressIndicator(color: brandRed)),
            ),
          ],
        ),
      );
    }

    if (_loadError != null || _aboutData == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/bg.png', fit: BoxFit.cover)),
            const MainTabHeaderBackdrop(height: 270),
            SafeArea(
              child: Center(
                child: IconButton(
                  onPressed: _loadAboutUs,
                  icon: const Icon(Icons.refresh_rounded, color: brandRed, size: 36),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final q = _searchQuery.trim().toLowerCase();
    final sections = _buildSections();
    final visible = sections
        .where((s) => _matchesFilter(s) && _matchesSearch(s, q))
        .toList();
    final fullName = '$_firstName $_lastName'.trim();
    final greeting = fullName.isEmpty
        ? _ui(context, 'greeting_guest')
        : _ui(context, 'greeting_user').replaceAll('{name}', fullName);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bg.png', fit: BoxFit.cover)),
          const MainTabHeaderBackdrop(height: 270),
          SafeArea(
            bottom: false,
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
                        greeting: greeting,
                        accountLabel: _ui(context, 'welcome_label'),
                        title: _ui(context, 'page_title'),
                        subtitle: _ui(context, 'page_subtitle'),
                        titleIcon: Icons.info_rounded,
                        avatarImage: avatarProvider,
                        profileLabel: _ui(context, 'profile_label'),
                        logoutLabel: _ui(context, 'logout_label'),
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
                                  hintText: _ui(context, 'search_placeholder'),
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _ui(context, 'filter_label'),
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
          MediaQuery.paddingOf(context).bottom + 96,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (visible.isEmpty)
              _EmptyState(
                title: _ui(context, 'empty_title'),
                body: _ui(context, 'empty_body'),
                resetLabel: _ui(context, 'reset'),
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
                    key: ValueKey(visible[index].key),
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
    final data = _aboutData!;
    return data.sections.map((record) {
      final title = record.title.resolve(context);
      final subtitle = record.subtitle.resolve(context);
      Widget child;
      switch (record.sectionKey) {
        case 'ignis_safe':
          child = _IgnisSafeSectionContent(
            data: data.ignis,
            uiTexts: data.uiTexts,
          );
          break;
        case 'bfp_dasmarinas':
          child = _PartnerCard(data: data.partner);
          break;
        case 'emergency_contacts':
          child = _ContactCard(data: data.emergency, uiTexts: data.uiTexts);
          break;
        case 'cavite_directory':
          child = _CaviteBfpDirectoryCard(
            query: _searchQuery,
            info: data.directoryInfo,
            groups: data.directoryGroups,
            uiTexts: data.uiTexts,
          );
          break;
        default:
          child = const SizedBox.shrink();
      }

      return _AboutSection(
        key: record.sectionKey,
        type: record.type,
        title: title,
        searchText: [
          record.title.en,
          record.title.tl,
          record.subtitle.en,
          record.subtitle.tl,
          data.searchTextFor(record.sectionKey),
        ].join(' '),
        icon: _iconFromKey(record.iconKey),
        subtitle: subtitle,
        builder: (_) => child,
      );
    }).toList();
  }
}

enum _AboutSectionType { about, partner, contact }

class _AboutSection {
  final String key;
  final _AboutSectionType type;
  final String title;
  final String searchText;
  final IconData icon;
  final String subtitle;
  final Widget Function(BuildContext) builder;

  _AboutSection({
    required this.key,
    required this.type,
    required this.title,
    required this.searchText,
    required this.icon,
    required this.subtitle,
    required this.builder,
  });
}

class _IgnisSafeSectionContent extends StatelessWidget {
  const _IgnisSafeSectionContent({required this.data, required this.uiTexts});

  final _IgnisRecord data;
  final Map<String, _LocalizedText> uiTexts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModernAboutCard(data: data),
        const SizedBox(height: 14),
        _LogoMeaningCard(data: data),
        const SizedBox(height: 14),
        _TeamCard(data: data, uiTexts: uiTexts),
      ],
    );
  }
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
  const _ModernAboutCard({required this.data});

  final _IgnisRecord data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
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
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.heading.resolve(context),
                    style: const TextStyle(
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
              data.description.resolve(context),
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
              children: data.chips
                  .map(
                    (chip) => _Chip(
                      text: chip.label.resolve(context),
                      icon: _iconFromKey(chip.iconKey),
                    ),
                  )
                  .toList(),
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
                      data.goal.resolve(context),
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
  const _LogoMeaningCard({required this.data});

  final _IgnisRecord data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      data.logoAssetPath,
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
                    data.logoDescription.resolve(context),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                data.brandHeading.resolve(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < data.meanings.length; i++) ...[
                  Expanded(
                    child: _MeaningMiniBlock(
                      title: data.meanings[i].term.resolve(context),
                      body: data.meanings[i].body.resolve(context),
                    ),
                  ),
                  if (i != data.meanings.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _bodyText(data.together.resolve(context)),
            const SizedBox(height: 12),
            Text(
              data.focusHeading.resolve(context),
              style: const TextStyle(
                fontSize: 12.8,
                height: 1.35,
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _bodyText(data.focusBody.resolve(context)),
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
                data.essence.resolve(context),
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

  Widget _bodyText(String text) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 12.8,
        height: 1.35,
        color: Color(0xFF2D2D2D),
        fontWeight: FontWeight.w600,
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
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.8,
            height: 1.25,
            color: Color(0xFF2D2D2D),
          ),
          children: [
            TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w900)),
            TextSpan(text: body, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Display order of the developers in the About Us team section.
/// Applied here so no database changes are required.
const List<String> _developerDisplayOrder = <String>[
  'ANDREI C. QUIAS',
  'FATIMA KLYE M. SIERRA',
  'RAVE PAULO PIOLO V. SIERRA',
  'SARAH FLOR MACANDILE',
];

/// Sorts developers by [_developerDisplayOrder]. Anyone not listed keeps their
/// original database order and is appended after the listed members.
List<_TeamMember> _sortDevelopers(List<_TeamMember> members) {
  int rankOf(_TeamMember member) {
    final name = member.fullName.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final index = _developerDisplayOrder.indexOf(name);
    return index == -1 ? _developerDisplayOrder.length : index;
  }

  final entries = <MapEntry<int, _TeamMember>>[
    for (int i = 0; i < members.length; i++) MapEntry(i, members[i]),
  ];
  entries.sort((a, b) {
    final byRank = rankOf(a.value).compareTo(rankOf(b.value));
    return byRank != 0 ? byRank : a.key.compareTo(b.key);
  });
  return [for (final entry in entries) entry.value];
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.data, required this.uiTexts});

  final _IgnisRecord data;
  final Map<String, _LocalizedText> uiTexts;

  String _ui(BuildContext context, String key) => uiTexts[key]!.resolve(context);

  @override
  Widget build(BuildContext context) {
    final developers = _sortDevelopers(data.team.where((m) => !m.isAdviser).toList());
    final advisers = data.team.where((m) => m.isAdviser).toList();

    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final compact = width < 300;
            final devAvatar = compact ? 56.0 : (width < 340 ? 62.0 : 68.0);
            final nameSize = compact ? 13.5 : 15.0;
            final roleSize = compact ? 10.5 : 11.5;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.teamHeading.resolve(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB11217),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEDEDED)),
                  ),
                  child: Text(
                    data.teamIntro.resolve(context),
                    style: const TextStyle(
                      fontSize: 12.8,
                      height: 1.35,
                      color: Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < developers.length; i++) ...[
                  _DeveloperCard(
                    member: developers[i],
                    avatarSize: devAvatar,
                    nameSize: nameSize,
                    roleSize: roleSize,
                    onTap: () => _showMemberBio(
                      context,
                      member: developers[i],
                      closeLabel: _ui(context, 'close'),
                      emailPrefix: _ui(context, 'email_prefix'),
                      emailPending: _ui(context, 'email_pending'),
                    ),
                  ),
                  if (i != developers.length - 1) const SizedBox(height: 10),
                ],
                if (advisers.isNotEmpty) ...[
                  SizedBox(height: developers.isEmpty ? 0 : 18),
                  _TeamGroupLabel(
                    text: t(context, 'PROJECT ADVISER', 'TAGAPAYO NG PROYEKTO'),
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < advisers.length; i++) ...[
                    _AdviserCard(
                      member: advisers[i],
                      avatarSize: devAvatar - 14,
                      nameSize: nameSize - 1.5,
                      roleSize: roleSize - 0.5,
                      onTap: () => _showMemberBio(
                        context,
                        member: advisers[i],
                        closeLabel: _ui(context, 'close'),
                        emailPrefix: _ui(context, 'email_prefix'),
                        emailPending: _ui(context, 'email_pending'),
                      ),
                    ),
                    if (i != advisers.length - 1) const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 12),
                Text(
                  data.teamTip.resolve(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.data});
  final _PartnerRecord data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.heading.resolve(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.description.resolve(context),
              style: const TextStyle(
                height: 1.35,
                fontSize: 13.2,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
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
                  Text(
                    data.stationHeading.resolve(context),
                    style: const TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB11217),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.phone_in_talk_rounded, size: 18, color: Color(0xFFB11217)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${data.emergencyLabel.resolve(context)}\n${data.contacts.map((c) => c.displayValue).join(' | ')}',
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
                  Text(
                    data.fireMarshalName,
                    style: const TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.fireMarshalTitle.resolve(context),
                    style: const TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.visionLabel.resolve(context),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            _partnerBody(data.vision.resolve(context)),
            const SizedBox(height: 10),
            Text(
              data.missionLabel.resolve(context),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            _partnerBody(data.mission.resolve(context)),
          ],
        ),
      ),
    );
  }

  Widget _partnerBody(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.8,
          height: 1.35,
          color: Color(0xFF2D2D2D),
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ContactCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);
  const _ContactCard({required this.data, required this.uiTexts});
  final _EmergencyRecord data;
  final Map<String, _LocalizedText> uiTexts;

  String _ui(BuildContext context, String key) => uiTexts[key]!.resolve(context);

  Future<void> _dial(String number) async {
    await launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$value ${_ui(context, 'copied_suffix')}')),
    );
  }

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
                    data.heading.resolve(context),
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
              data.intro.resolve(context),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3A3A3A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < data.numbers.length; i++) ...[
              _ContactRow(
                icon: _iconFromKey(data.numbers[i].iconKey),
                label: data.numbers[i].label.resolve(context),
                value: data.numbers[i].displayValue,
                onTap: () => _dial(data.numbers[i].dialValue),
                onCopy: () => _copy(context, data.numbers[i].displayValue),
                copyTooltip: _ui(context, 'copy_phone_tooltip'),
              ),
              if (i != data.numbers.length - 1) const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDEDED)),
              ),
              child: Text(
                data.safetyNote.resolve(context),
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
  final VoidCallback? onCopy;
  final String copyTooltip;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onCopy,
    this.copyTooltip = '',
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
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
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
          if (onCopy != null)
            IconButton(
              tooltip: copyTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 17, color: Color(0xFFB11217)),
            ),
        ],
      ),
    );
  }
}

Future<void> _showMemberBio(
  BuildContext context, {
  required _TeamMember member,
  required String closeLabel,
  required String emailPrefix,
  required String emailPending,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        member.fullName,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.role.resolve(context),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFB11217),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: member.email == null
                  ? null
                  : () => launchUrl(
                        Uri(scheme: 'mailto', path: member.email),
                        mode: LaunchMode.externalApplication,
                      ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  member.email == null
                      ? '$emailPrefix: $emailPending'
                      : '$emailPrefix: ${member.email}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: member.email == null
                        ? const Color(0xFF777777)
                        : const Color(0xFF2D2D2D),
                    fontStyle: member.email == null ? FontStyle.italic : FontStyle.normal,
                    decoration: member.email == null
                        ? TextDecoration.none
                        : TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              member.bio.resolve(context),
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
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.size,
    required this.ringColors,
    this.ringWidth = 2.5,
  });

  final _TeamMember member;
  final double size;
  final List<Color> ringColors;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ringColors,
        ),
      ),
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            member.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: const Color(0xFFF2F2F2),
              child: Icon(
                Icons.person_rounded,
                color: const Color(0xFF8C8C8C),
                size: size * 0.58,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  static const Color brandRed = Color(0xFFB11217);

  const _DeveloperCard({
    required this.member,
    required this.avatarSize,
    required this.nameSize,
    required this.roleSize,
    required this.onTap,
  });

  final _TeamMember member;
  final double avatarSize;
  final double nameSize;
  final double roleSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFFF7F7)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: brandRed.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MemberAvatar(
                  member: member,
                  size: avatarSize,
                  ringColors: const [brandRed, Color(0xFFE65A5F)],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E1E1E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFF1D5D6)),
                          ),
                          child: Text(
                            member.role.resolve(context),
                            style: TextStyle(
                              fontSize: roleSize,
                              fontWeight: FontWeight.w800,
                              color: brandRed,
                              height: 1.2,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1D5D6)),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: brandRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamGroupLabel extends StatelessWidget {
  const _TeamGroupLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          size: 15,
          color: Color(0xFF9A9A9A),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A8A8A),
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEDEDED),
          ),
        ),
      ],
    );
  }
}

class _AdviserCard extends StatelessWidget {
  const _AdviserCard({
    required this.member,
    required this.avatarSize,
    required this.nameSize,
    required this.roleSize,
    required this.onTap,
  });

  final _TeamMember member;
  final double avatarSize;
  final double nameSize;
  final double roleSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MemberAvatar(
                  member: member,
                  size: avatarSize,
                  ringWidth: 2,
                  ringColors: const [Color(0xFFE2E2E2), Color(0xFFF0F0F0)],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3A3A3A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        member.role.resolve(context),
                        style: TextStyle(
                          fontSize: roleSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8A8A8A),
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFFB0B0B0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  final String title;
  final String body;
  final String resetLabel;
  final VoidCallback onClear;

  const _EmptyState({
    required this.title,
    required this.body,
    required this.resetLabel,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18, blur: 14, offsetY: 6, opacity: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(resetLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaviteBfpDirectoryCard extends StatelessWidget {
  const _CaviteBfpDirectoryCard({
    required this.query,
    required this.info,
    required this.groups,
    required this.uiTexts,
  });

  final String query;
  final _DirectoryInfo info;
  final List<_DirectoryGroup> groups;
  final Map<String, _LocalizedText> uiTexts;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filteredGroups = groups
        .map((g) {
          final entries = g.entries.where((e) {
            if (q.isEmpty) return true;
            return [
              e.name.en,
              e.name.tl,
              e.email,
              ...e.phones.map((p) => p.displayValue),
            ].join(' ').toLowerCase().contains(q);
          }).toList();
          return g.copyWith(entries: entries);
        })
        .where((g) {
          if (q.isEmpty) return true;
          return g.title.en.toLowerCase().contains(q) ||
              g.title.tl.toLowerCase().contains(q) ||
              g.entries.isNotEmpty;
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
                    info.heading.resolve(context),
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
              info.intro.resolve(context),
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
                  info.noResults.resolve(context),
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
                    uiTexts: uiTexts,
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
  const _DistrictAccordion({
    required this.group,
    required this.uiTexts,
    this.initiallyExpanded = false,
  });

  final _DirectoryGroup group;
  final bool initiallyExpanded;
  final Map<String, _LocalizedText> uiTexts;

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
            group.title.resolve(context),
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
                  child: _DirectoryEntryTile(entry: e, uiTexts: uiTexts),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DirectoryEntryTile extends StatelessWidget {
  const _DirectoryEntryTile({required this.entry, required this.uiTexts});

  final _DirectoryEntry entry;
  final Map<String, _LocalizedText> uiTexts;

  String _ui(BuildContext context, String key) => uiTexts[key]!.resolve(context);

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_ui(context, 'no_compatible_app'))),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$value ${_ui(context, 'copied_suffix')}')),
    );
  }

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
            entry.name.resolve(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _open(context, Uri(scheme: 'mailto', path: entry.email)),
            onLongPress: () => _copy(context, entry.email),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, size: 18, color: Color(0xFFB11217)),
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
                    tooltip: _ui(context, 'copy_email_tooltip'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copy(context, entry.email),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.phones
                .map(
                  (phone) => InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _open(context, Uri(scheme: 'tel', path: phone.dialValue)),
                    onLongPress: () => _copy(context, phone.displayValue),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            phone.displayValue,
                            style: const TextStyle(
                              fontSize: 12.2,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copy(context, phone.displayValue),
                            child: Tooltip(
                              message: _ui(context, 'copy_phone_tooltip'),
                              child: const Icon(Icons.copy_rounded, size: 15),
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

class _LocalizedText {
  const _LocalizedText(this.en, this.tl);
  final String en;
  final String tl;

  String resolve(BuildContext context) => t(context, en, tl);

  factory _LocalizedText.fromRow(
    Map<String, dynamic> row, {
    required String enKey,
    required String tlKey,
  }) {
    return _LocalizedText(row[enKey].toString(), row[tlKey].toString());
  }
}

class _SectionRecord {
  const _SectionRecord({
    required this.sectionKey,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconKey,
  });

  final String sectionKey;
  final _AboutSectionType type;
  final _LocalizedText title;
  final _LocalizedText subtitle;
  final String iconKey;

  factory _SectionRecord.fromRow(Map<String, dynamic> row) {
    return _SectionRecord(
      sectionKey: row['section_key'].toString(),
      type: switch (row['section_type'].toString()) {
        'about' => _AboutSectionType.about,
        'partner' => _AboutSectionType.partner,
        _ => _AboutSectionType.contact,
      },
      title: _LocalizedText.fromRow(row, enKey: 'title_en', tlKey: 'title_tl'),
      subtitle: _LocalizedText.fromRow(row, enKey: 'subtitle_en', tlKey: 'subtitle_tl'),
      iconKey: row['icon_key'].toString(),
    );
  }
}

class _IgnisChip {
  const _IgnisChip({required this.label, required this.iconKey});
  final _LocalizedText label;
  final String iconKey;

  factory _IgnisChip.fromRow(Map<String, dynamic> row) => _IgnisChip(
        label: _LocalizedText.fromRow(row, enKey: 'label_en', tlKey: 'label_tl'),
        iconKey: row['icon_key'].toString(),
      );
}

class _NameMeaning {
  const _NameMeaning({required this.term, required this.body});
  final _LocalizedText term;
  final _LocalizedText body;

  factory _NameMeaning.fromRow(Map<String, dynamic> row) => _NameMeaning(
        term: _LocalizedText.fromRow(row, enKey: 'term_en', tlKey: 'term_tl'),
        body: _LocalizedText.fromRow(row, enKey: 'body_en', tlKey: 'body_tl'),
      );
}

class _TeamMember {
  const _TeamMember({
    required this.fullName,
    required this.displayFirst,
    required this.displayLast,
    required this.role,
    required this.email,
    required this.bio,
    required this.assetPath,
  });

  final String fullName;
  final String displayFirst;
  final String displayLast;
  final _LocalizedText role;
  final String? email;
  final _LocalizedText bio;
  final String assetPath;

  /// Advisers are separated from the developers in the About Us team section.
  /// Detected from the role text so no database changes are required.
  bool get isAdviser {
    final value = '${role.en} ${role.tl}'.toUpperCase();
    return value.contains('ADVISER') ||
        value.contains('ADVISOR') ||
        value.contains('TAGAPAYO');
  }

  factory _TeamMember.fromRow(Map<String, dynamic> row) => _TeamMember(
        fullName: row['full_name'].toString(),
        displayFirst: row['display_first'].toString(),
        displayLast: row['display_last'].toString(),
        role: _LocalizedText.fromRow(row, enKey: 'role_en', tlKey: 'role_tl'),
        email: row['email'] as String?,
        bio: _LocalizedText.fromRow(row, enKey: 'bio_en', tlKey: 'bio_tl'),
        assetPath: row['asset_path'].toString(),
      );
}

class _IgnisRecord {
  const _IgnisRecord({
    required this.heading,
    required this.description,
    required this.goal,
    required this.logoAssetPath,
    required this.logoDescription,
    required this.brandHeading,
    required this.together,
    required this.focusHeading,
    required this.focusBody,
    required this.essence,
    required this.teamHeading,
    required this.teamIntro,
    required this.teamTip,
    required this.chips,
    required this.meanings,
    required this.team,
  });

  final _LocalizedText heading;
  final _LocalizedText description;
  final _LocalizedText goal;
  final String logoAssetPath;
  final _LocalizedText logoDescription;
  final _LocalizedText brandHeading;
  final _LocalizedText together;
  final _LocalizedText focusHeading;
  final _LocalizedText focusBody;
  final _LocalizedText essence;
  final _LocalizedText teamHeading;
  final _LocalizedText teamIntro;
  final _LocalizedText teamTip;
  final List<_IgnisChip> chips;
  final List<_NameMeaning> meanings;
  final List<_TeamMember> team;

  factory _IgnisRecord.fromRow(
    Map<String, dynamic> row, {
    required List<_IgnisChip> chips,
    required List<_NameMeaning> meanings,
    required List<_TeamMember> team,
  }) =>
      _IgnisRecord(
        heading: _LocalizedText.fromRow(row, enKey: 'heading_en', tlKey: 'heading_tl'),
        description: _LocalizedText.fromRow(row, enKey: 'description_en', tlKey: 'description_tl'),
        goal: _LocalizedText.fromRow(row, enKey: 'goal_en', tlKey: 'goal_tl'),
        logoAssetPath: row['logo_asset_path'].toString(),
        logoDescription: _LocalizedText.fromRow(
          row,
          enKey: 'logo_description_en',
          tlKey: 'logo_description_tl',
        ),
        brandHeading: _LocalizedText.fromRow(
          row,
          enKey: 'brand_heading_en',
          tlKey: 'brand_heading_tl',
        ),
        together: _LocalizedText.fromRow(row, enKey: 'together_en', tlKey: 'together_tl'),
        focusHeading: _LocalizedText.fromRow(
          row,
          enKey: 'focus_heading_en',
          tlKey: 'focus_heading_tl',
        ),
        focusBody: _LocalizedText.fromRow(row, enKey: 'focus_body_en', tlKey: 'focus_body_tl'),
        essence: _LocalizedText.fromRow(row, enKey: 'essence_en', tlKey: 'essence_tl'),
        teamHeading: _LocalizedText.fromRow(
          row,
          enKey: 'team_heading_en',
          tlKey: 'team_heading_tl',
        ),
        teamIntro: _LocalizedText.fromRow(row, enKey: 'team_intro_en', tlKey: 'team_intro_tl'),
        teamTip: _LocalizedText.fromRow(row, enKey: 'team_tip_en', tlKey: 'team_tip_tl'),
        chips: chips,
        meanings: meanings,
        team: team,
      );
}

class _PartnerRecord {
  const _PartnerRecord({
    required this.heading,
    required this.description,
    required this.stationHeading,
    required this.emergencyLabel,
    required this.contacts,
    required this.fireMarshalName,
    required this.fireMarshalTitle,
    required this.visionLabel,
    required this.vision,
    required this.missionLabel,
    required this.mission,
  });

  final _LocalizedText heading;
  final _LocalizedText description;
  final _LocalizedText stationHeading;
  final _LocalizedText emergencyLabel;
  final List<_ContactPoint> contacts;
  final String fireMarshalName;
  final _LocalizedText fireMarshalTitle;
  final _LocalizedText visionLabel;
  final _LocalizedText vision;
  final _LocalizedText missionLabel;
  final _LocalizedText mission;

  factory _PartnerRecord.fromRow(
    Map<String, dynamic> row, {
    required List<_ContactPoint> contacts,
  }) => _PartnerRecord(
        heading: _LocalizedText.fromRow(row, enKey: 'heading_en', tlKey: 'heading_tl'),
        description: _LocalizedText.fromRow(row, enKey: 'description_en', tlKey: 'description_tl'),
        stationHeading: _LocalizedText.fromRow(
          row,
          enKey: 'station_heading_en',
          tlKey: 'station_heading_tl',
        ),
        emergencyLabel: _LocalizedText.fromRow(
          row,
          enKey: 'emergency_label_en',
          tlKey: 'emergency_label_tl',
        ),
        contacts: contacts,
        fireMarshalName: row['fire_marshal_name'].toString(),
        fireMarshalTitle: _LocalizedText.fromRow(
          row,
          enKey: 'fire_marshal_title_en',
          tlKey: 'fire_marshal_title_tl',
        ),
        visionLabel: _LocalizedText.fromRow(
          row,
          enKey: 'vision_label_en',
          tlKey: 'vision_label_tl',
        ),
        vision: _LocalizedText.fromRow(row, enKey: 'vision_en', tlKey: 'vision_tl'),
        missionLabel: _LocalizedText.fromRow(
          row,
          enKey: 'mission_label_en',
          tlKey: 'mission_label_tl',
        ),
        mission: _LocalizedText.fromRow(row, enKey: 'mission_en', tlKey: 'mission_tl'),
      );
}

class _ContactPoint {
  const _ContactPoint({
    required this.key,
    required this.displayValue,
    required this.dialValue,
  });

  final String key;
  final String displayValue;
  final String dialValue;

  factory _ContactPoint.fromRow(Map<String, dynamic> row) => _ContactPoint(
        key: row['contact_key'].toString(),
        displayValue: row['display_value'].toString(),
        dialValue: row['dial_value'].toString(),
      );
}

class _EmergencyNumber {
  const _EmergencyNumber({
    required this.label,
    required this.contact,
    required this.iconKey,
  });

  final _LocalizedText label;
  final _ContactPoint contact;
  final String iconKey;

  String get displayValue => contact.displayValue;
  String get dialValue => contact.dialValue;

  factory _EmergencyNumber.fromRow(
    Map<String, dynamic> row, {
    required _ContactPoint contact,
  }) => _EmergencyNumber(
        label: _LocalizedText.fromRow(row, enKey: 'label_en', tlKey: 'label_tl'),
        contact: contact,
        iconKey: row['icon_key'].toString(),
      );
}

class _EmergencyRecord {
  const _EmergencyRecord({
    required this.heading,
    required this.intro,
    required this.safetyNote,
    required this.numbers,
  });

  final _LocalizedText heading;
  final _LocalizedText intro;
  final _LocalizedText safetyNote;
  final List<_EmergencyNumber> numbers;

  factory _EmergencyRecord.fromRow(
    Map<String, dynamic> row, {
    required List<_EmergencyNumber> numbers,
  }) =>
      _EmergencyRecord(
        heading: _LocalizedText.fromRow(row, enKey: 'heading_en', tlKey: 'heading_tl'),
        intro: _LocalizedText.fromRow(row, enKey: 'intro_en', tlKey: 'intro_tl'),
        safetyNote: _LocalizedText.fromRow(
          row,
          enKey: 'safety_note_en',
          tlKey: 'safety_note_tl',
        ),
        numbers: numbers,
      );
}

class _DirectoryInfo {
  const _DirectoryInfo({required this.heading, required this.intro, required this.noResults});
  final _LocalizedText heading;
  final _LocalizedText intro;
  final _LocalizedText noResults;

  factory _DirectoryInfo.fromRow(Map<String, dynamic> row) => _DirectoryInfo(
        heading: _LocalizedText.fromRow(row, enKey: 'heading_en', tlKey: 'heading_tl'),
        intro: _LocalizedText.fromRow(row, enKey: 'intro_en', tlKey: 'intro_tl'),
        noResults: _LocalizedText.fromRow(
          row,
          enKey: 'no_results_en',
          tlKey: 'no_results_tl',
        ),
      );
}

class _DirectoryPhone {
  const _DirectoryPhone({required this.displayValue, required this.dialValue});
  final String displayValue;
  final String dialValue;

  factory _DirectoryPhone.fromRow(Map<String, dynamic> row) => _DirectoryPhone(
        displayValue: row['display_value'].toString(),
        dialValue: row['dial_value'].toString(),
      );
}

class _DirectoryEntry {
  const _DirectoryEntry({
    required this.name,
    required this.email,
    required this.phones,
  });

  final _LocalizedText name;
  final String email;
  final List<_DirectoryPhone> phones;

  factory _DirectoryEntry.fromRow(
    Map<String, dynamic> row, {
    required List<_DirectoryPhone> phones,
  }) =>
      _DirectoryEntry(
        name: _LocalizedText.fromRow(row, enKey: 'name_en', tlKey: 'name_tl'),
        email: row['email'].toString(),
        phones: phones,
      );
}

class _DirectoryGroup {
  const _DirectoryGroup({required this.title, required this.entries});
  final _LocalizedText title;
  final List<_DirectoryEntry> entries;

  factory _DirectoryGroup.fromRow(
    Map<String, dynamic> row, {
    required List<_DirectoryEntry> entries,
  }) =>
      _DirectoryGroup(
        title: _LocalizedText.fromRow(row, enKey: 'title_en', tlKey: 'title_tl'),
        entries: entries,
      );

  _DirectoryGroup copyWith({List<_DirectoryEntry>? entries}) {
    return _DirectoryGroup(title: title, entries: entries ?? this.entries);
  }
}

class _AboutUsData {
  const _AboutUsData({
    required this.uiTexts,
    required this.sections,
    required this.ignis,
    required this.partner,
    required this.emergency,
    required this.directoryInfo,
    required this.directoryGroups,
  });

  final Map<String, _LocalizedText> uiTexts;
  final List<_SectionRecord> sections;
  final _IgnisRecord ignis;
  final _PartnerRecord partner;
  final _EmergencyRecord emergency;
  final _DirectoryInfo directoryInfo;
  final List<_DirectoryGroup> directoryGroups;

  String searchTextFor(String sectionKey) {
    switch (sectionKey) {
      case 'ignis_safe':
        return [
          ignis.heading.en,
          ignis.heading.tl,
          ignis.description.en,
          ignis.description.tl,
          ignis.goal.en,
          ignis.goal.tl,
          ignis.logoDescription.en,
          ignis.logoDescription.tl,
          ignis.together.en,
          ignis.together.tl,
          ignis.focusHeading.en,
          ignis.focusHeading.tl,
          ignis.focusBody.en,
          ignis.focusBody.tl,
          ignis.essence.en,
          ignis.essence.tl,
          ignis.teamHeading.en,
          ignis.teamHeading.tl,
          ignis.teamIntro.en,
          ignis.teamIntro.tl,
          ...ignis.chips.expand((c) => [c.label.en, c.label.tl]),
          ...ignis.meanings.expand((m) => [m.term.en, m.term.tl, m.body.en, m.body.tl]),
          ...ignis.team.expand((m) => [
                m.fullName,
                m.displayFirst,
                m.displayLast,
                m.role.en,
                m.role.tl,
                m.email ?? '',
                m.bio.en,
                m.bio.tl,
              ]),
        ].join(' ');
      case 'bfp_dasmarinas':
        return [
          partner.heading.en,
          partner.heading.tl,
          partner.description.en,
          partner.description.tl,
          partner.stationHeading.en,
          partner.stationHeading.tl,
          partner.emergencyLabel.en,
          partner.emergencyLabel.tl,
          ...partner.contacts.expand((c) => [c.displayValue, c.dialValue]),
          partner.fireMarshalName,
          partner.fireMarshalTitle.en,
          partner.fireMarshalTitle.tl,
          partner.vision.en,
          partner.vision.tl,
          partner.mission.en,
          partner.mission.tl,
        ].join(' ');
      case 'emergency_contacts':
        return [
          emergency.heading.en,
          emergency.heading.tl,
          emergency.intro.en,
          emergency.intro.tl,
          emergency.safetyNote.en,
          emergency.safetyNote.tl,
          ...emergency.numbers.expand((n) => [
                n.label.en,
                n.label.tl,
                n.displayValue,
                n.dialValue,
              ]),
        ].join(' ');
      case 'cavite_directory':
        return [
          directoryInfo.heading.en,
          directoryInfo.heading.tl,
          directoryInfo.intro.en,
          directoryInfo.intro.tl,
          ...directoryGroups.expand((g) => [
                g.title.en,
                g.title.tl,
                ...g.entries.expand((e) => [
                      e.name.en,
                      e.name.tl,
                      e.email,
                      ...e.phones.map((p) => p.displayValue),
                    ]),
              ]),
        ].join(' ');
      default:
        return '';
    }
  }
}

IconData _iconFromKey(String key) {
  switch (key) {
    case 'local_fire_department':
      return Icons.local_fire_department_rounded;
    case 'local_fire_department_outlined':
      return Icons.local_fire_department_outlined;
    case 'phone_in_talk':
      return Icons.phone_in_talk_rounded;
    case 'apartment':
      return Icons.apartment_rounded;
    case 'view_in_ar':
      return Icons.view_in_ar_rounded;
    case 'touch_app':
      return Icons.touch_app_rounded;
    case 'verified':
      return Icons.verified_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'local_phone':
      return Icons.local_phone_rounded;
    case 'smartphone':
      return Icons.smartphone_rounded;
    default:
      return Icons.info_rounded;
  }
}

BoxDecoration _cardDecoration({
  double radius = 20,
  double blur = 18,
  double offsetY = 8,
  double opacity = 0.10,
}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: Offset(0, offsetY),
      ),
    ],
    border: Border.all(color: const Color(0xFFF0F0F0)),
  );
}
