import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'localization/app_text.dart';

import 'module_1_extinguisher.dart/pre_assess_instruction.dart' as pre1;
import 'module_2_house.dart/pre_assess_instruction.dart' as pre2;
import 'module_3_electrical.dart/pre_assess_instruction.dart' as pre3;
import 'module_4_kitchen.dart/pre_assess_instruction.dart' as pre4;
import 'module_5_building.dart/pre_assess_instruction.dart' as pre5;

class LearningMaterialsTab extends StatefulWidget {
  const LearningMaterialsTab({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<LearningMaterialsTab> createState() => _LearningMaterialsTabState();
}

class _LearningMaterialsTabState extends State<LearningMaterialsTab> {
  final _client = Supabase.instance.client;

  String searchQuery = '';
  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;
  bool _loading = true;
  String? _error;
  List<LearningMaterial> _modules = [];
  RealtimeChannel? _channel;

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadModules();
    _listenRealtime();
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) _client.removeChannel(c);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
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

  Future<void> _loadModules() async {
    try {
      if (mounted && _modules.isEmpty) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final rows = await _client
          .from('learning_material_mobile_view')
          .select()
          .order('module_no', ascending: true);

      final modules = (rows as List)
          .map((e) => LearningMaterial.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() {
        _modules = modules;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _listenRealtime() {
    _channel = _client
        .channel('learning_materials_mobile_list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_materials',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_pages',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_blocks',
          callback: (_) => _loadModules(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_media_assets',
          callback: (_) => _loadModules(),
        )
        .subscribe();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_tab_index');
    await _client.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openModule(int moduleNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DatabaseLearningMaterialPage(moduleNo: moduleNo),
      ),
    );
  }

  ImageProvider? _buildAvatarProvider() {
    if (_avatarUrl == null || _avatarUrl!.trim().isEmpty) return null;

    if (_avatarUrl!.startsWith('http')) {
      return NetworkImage(_avatarUrl!);
    }

    return AssetImage(_avatarUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final filtered = _modules.where((m) {
      if (q.isEmpty) return true;
      return m.title(_isTl).toLowerCase().contains(q) ||
          m.subtitle(_isTl).toLowerCase().contains(q) ||
          m.moduleLabel(_isTl).toLowerCase().contains(q);
    }).toList();

    final avatarProvider = _buildAvatarProvider();

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
                        tooltip: '',
                        offset: const Offset(0, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onSelected: (value) async {
                          if (value == 'profile') {
                            widget.onRequestTabChange?.call(2);
                            return;
                          }
                          if (value == 'logout') {
                            await _logout();
                            return;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded),
                                const SizedBox(width: 8),
                                Text(context.tr('profile')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded),
                                const SizedBox(width: 8),
                                Text(context.tr('log_out')),
                              ],
                            ),
                          ),
                        ],
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade400,
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
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
                            _firstName.isEmpty && _lastName.isEmpty
                                ? context.tr('hi')
                                : context.tr(
                                    'hi_name',
                                    params: {'name': '$_firstName $_lastName'.trim()},
                                  ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('welcome_to_ignis_safe_short'),
                            style: const TextStyle(
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
                  Center(
                    child: Text(
                      context.tr('learning_materials'),
                      style: const TextStyle(
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
                            onChanged: (value) => setState(() => searchQuery = value),
                            decoration: InputDecoration(
                              hintText: context.tr('search'),
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (searchQuery.trim().isNotEmpty)
                          IconButton(
                            tooltip: _isTl ? 'I-clear' : 'Clear',
                            onPressed: () => setState(() => searchQuery = ''),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(child: _buildList(filtered)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LearningMaterial> items) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB11217)),
      );
    }

    if (_error != null) {
      return _MessageCard(
        icon: Icons.error_outline_rounded,
        title: _isTl
            ? 'Hindi ma-load ang learning materials'
            : 'Cannot load learning materials',
        message: _error!,
        buttonText: _isTl ? 'Subukan muli' : 'Retry',
        color: const Color(0xFFB11217),
        onPressed: _loadModules,
      );
    }

    if (items.isEmpty) {
      return _MessageCard(
        icon: Icons.search_off_rounded,
        title: _isTl ? 'Walang resulta' : 'No results found',
        message: _isTl
            ? 'Walang tumugma sa hinanap mo.'
            : 'No module matched your search.',
        buttonText: _isTl ? 'I-clear' : 'Clear',
        color: const Color(0xFFB11217),
        onPressed: () => setState(() => searchQuery = ''),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadModules,
      color: const Color(0xFFB11217),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: (MediaQuery.of(context).padding.bottom + 24)
              .clamp(24.0, 999.0),
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final m = items[index];
          return _ModuleCard(
            moduleNo: m.moduleNo,
            moduleLabel: m.moduleLabel(_isTl),
            title: m.title(_isTl),
            description: m.subtitle(_isTl),
            image: m.heroImage,
            onPressed: () => _openModule(m.moduleNo),
          );
        },
      ),
    );
  }
}

class DatabaseLearningMaterialPage extends StatefulWidget {
  const DatabaseLearningMaterialPage({super.key, required this.moduleNo});

  final int moduleNo;

  @override
  State<DatabaseLearningMaterialPage> createState() =>
      _DatabaseLearningMaterialPageState();
}

class _DatabaseLearningMaterialPageState
    extends State<DatabaseLearningMaterialPage> {
  final _client = Supabase.instance.client;
  final _scroll = ScrollController();

  LearningMaterial? _material;
  List<FireClassGuide> _fireGuides = [];
  bool _loading = true;
  String? _error;
  int _pageIndex = 0;
  double _progress = 0;
  bool _canNext = false;
  RealtimeChannel? _channel;

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';
  Color get _accent => _moduleAccent(widget.moduleNo);
  Color get _accent2 => _moduleAccent2(widget.moduleNo);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMaterial();
    _listenRealtime();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    final c = _channel;
    if (c != null) _client.removeChannel(c);
    super.dispose();
  }

  Future<void> _loadMaterial() async {
    try {
      if (mounted && _material == null) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final row = await _client
          .from('learning_material_mobile_view')
          .select()
          .eq('module_no', widget.moduleNo)
          .maybeSingle();

      if (row == null) {
        throw Exception('Module ${widget.moduleNo} has no learning material row.');
      }

      final material = LearningMaterial.fromMap(Map<String, dynamic>.from(row));
      List<FireClassGuide> guides = [];

      if (widget.moduleNo == 1) {
        final rows = await _client
            .from('learning_material_fire_class_guides')
            .select()
            .eq('module_no', 1)
            .eq('is_active', true)
            .order('display_order', ascending: true);

        guides = (rows as List)
            .map((e) => FireClassGuide.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _material = material;
        _fireGuides = guides;
        _loading = false;
        _error = null;
        if (_pageIndex >= material.pages.length) {
          _pageIndex = material.pages.isEmpty ? 0 : material.pages.length - 1;
        }
      });
      _resetScroll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _listenRealtime() {
    _channel = _client
        .channel('learning_material_${widget.moduleNo}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_materials',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_pages',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_blocks',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_media_assets',
          callback: (_) => _loadMaterial(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_material_fire_class_guides',
          callback: (_) => _loadMaterial(),
        )
        .subscribe();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final off = _scroll.offset;

    if (max <= 0) {
      if (_progress != 1 || !_canNext) {
        setState(() {
          _progress = 1;
          _canNext = true;
        });
      }
      return;
    }

    final p = (off / max).clamp(0.0, 1.0);
    final nearBottom = off >= max - 8;
    if (_progress != p || _canNext != nearBottom) {
      setState(() {
        _progress = p;
        _canNext = nearBottom;
      });
    }
  }

  void _resetScroll() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _progress = 0;
      _canNext = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _back() {
    if (_pageIndex == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _pageIndex--);
      _resetScroll();
    }
  }

  void _next() {
    final m = _material;
    if (m == null || m.pages.isEmpty) return;
    final last = _pageIndex >= m.pages.length - 1;

    if (!last && !_canNext) return;
    if (!last) {
      setState(() => _pageIndex++);
      _resetScroll();
      return;
    }

    Widget page;
    switch (widget.moduleNo) {
      case 1:
        page = const pre1.PreAssessmentIntroPage();
        break;
      case 2:
        page = const pre2.PreAssessmentIntroPage2();
        break;
      case 3:
        page = const pre3.PreAssessmentIntroPage2();
        break;
      case 4:
        page = const pre4.PreAssessmentIntroPage2();
        break;
      case 5:
        page = const pre5.PreAssessmentIntroPage2();
        break;
      default:
        Navigator.pop(context);
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _t(String en, String tl) =>
      _isTl && tl.trim().isNotEmpty ? tl : en;

  @override
  Widget build(BuildContext context) {
    final m = _material;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(18),
                        child: Center(
                          child: _MessageCard(
                            icon: Icons.error_outline_rounded,
                            title: _t(
                              'Cannot load learning material',
                              'Hindi ma-load ang learning material',
                            ),
                            message: _error!,
                            buttonText: _t('Retry', 'Subukan muli'),
                            color: _accent,
                            onPressed: _loadMaterial,
                          ),
                        ),
                      )
                    : m == null || m.pages.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: Center(
                              child: _MessageCard(
                                icon: Icons.menu_book_outlined,
                                title: _t('No content', 'Walang content'),
                                message: _t(
                                  'No learning material content found.',
                                  'Walang learning material content na nakita.',
                                ),
                                buttonText: _t('Back', 'Balik'),
                                color: _accent,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          )
                        : _buildContent(m),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LearningMaterial m) {
    final page = m.pages[_pageIndex];
    final last = _pageIndex >= m.pages.length - 1;
    final supportingImages = m.mediaAssets
        .where(
          (x) => x.assetType != 'background' &&
              x.assetType != 'hero' &&
              x.assetType != 'fire_class_image',
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _DetailHeader(
            accent: _accent,
            accent2: _accent2,
            moduleLabel: m.moduleLabel(_isTl),
            title: m.title(_isTl),
            pageTitle: page.title(_isTl),
            currentPage: _pageIndex + 1,
            totalPages: m.pages.length,
            progress: _progress,
            onBack: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ContentCard(
                  accent: _accent,
                  accent2: _accent2,
                  title: page.title(_isTl),
                  trailing: Text(
                    '${_pageIndex + 1}/${m.pages.length}',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_pageIndex == 0 && m.heroImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 160),
                            color: _accent.withOpacity(0.06),
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              height: 160,
                              child: _DbImage(asset: m.heroImage!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ...page.blocks.map((b) => _blockWidget(b)),
                    ],
                  ),
                ),
                if (m.moduleNo == 1 &&
                    page.pageNo == 2 &&
                    _fireGuides.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ExpandableSection(
                    accent: _accent,
                    title: _t('Fire Class Guide', 'Gabay sa Klase ng Sunog'),
                    initiallyExpanded: true,
                    child: _FireGuide(
                      guides: _fireGuides,
                      isTl: _isTl,
                      accent: _accent,
                    ),
                  ),
                ],
                if (last && supportingImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ExpandableSection(
                    accent: _accent,
                    title: _t(
                      'Learning material images',
                      'Mga larawan ng materyal',
                    ),
                    initiallyExpanded: true,
                    child: _ImageGallery(
                      title: _t(
                        'Learning material images',
                        'Mga larawan ng materyal',
                      ),
                      images: supportingImages,
                      isTl: _isTl,
                      accent: _accent,
                    ),
                  ),
                ],
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: _BottomActionBar(
              accent: _accent,
              accent2: _accent2,
              canNext: _canNext || last,
              last: last,
              onBack: _back,
              onNext: _next,
              backText: _t('Back', 'Balik'),
              nextText:
                  last ? _t('Start pre test', 'Simulan ang paunang pagsusulit') : _t('Next', 'Sunod'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blockWidget(LearningBlock b) {
    final text = b.text(_isTl).trim();
    if (text.isEmpty) return const SizedBox.shrink();

    if (b.blockType == 'heading') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _accent,
            height: 1.3,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    if (b.blockType == 'label') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: _accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (b.blockType == 'list_or_multiline' || text.contains('\n')) {
      final lines = text
          .split('\n')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
      return _Bullets(items: lines, accent: _accent);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: Color(0xFF1F2937),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class LearningMaterial {
  final int moduleNo;
  final String titleEn;
  final String titleTl;
  final String subtitleEn;
  final String subtitleTl;
  final String heroAsset;
  final List<LearningPage> pages;
  final List<LearningMediaAsset> mediaAssets;

  LearningMaterial({
    required this.moduleNo,
    required this.titleEn,
    required this.titleTl,
    required this.subtitleEn,
    required this.subtitleTl,
    required this.heroAsset,
    required this.pages,
    required this.mediaAssets,
  });

  factory LearningMaterial.fromMap(Map<String, dynamic> m) {
    final pages = _list(m['pages'])
        .map((x) => LearningPage.fromMap(Map<String, dynamic>.from(x)))
        .toList()
      ..sort((a, b) => a.pageNo.compareTo(b.pageNo));
    final media = _list(m['media_assets'])
        .map((x) => LearningMediaAsset.fromMap(Map<String, dynamic>.from(x)))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return LearningMaterial(
      moduleNo: _int(m['module_no']),
      titleEn: _str(m['title']),
      titleTl: _str(m['title_tl']),
      subtitleEn: _str(m['subtitle']),
      subtitleTl: _str(m['subtitle_tl']),
      heroAsset: _str(m['hero_asset']),
      pages: pages,
      mediaAssets: media,
    );
  }

  String moduleLabel(bool isTl) => isTl ? 'MODYUL $moduleNo' : 'MODULE $moduleNo';
  String title(bool isTl) => isTl && titleTl.trim().isNotEmpty ? titleTl : titleEn;
  String subtitle(bool isTl) =>
      isTl && subtitleTl.trim().isNotEmpty ? subtitleTl : subtitleEn;

  LearningMediaAsset? get heroImage {
    for (final img in mediaAssets) {
      if (img.assetType == 'hero') return img;
    }
    if (heroAsset.trim().isEmpty) return null;
    return LearningMediaAsset(
      displayOrder: 0,
      assetKey: 'hero',
      assetPath: heroAsset,
      publicUrl: '',
      assetType: 'hero',
      altEn: titleEn,
      altTl: titleTl,
    );
  }
}

class LearningPage {
  final int pageNo;
  final String titleEn;
  final String titleTl;
  final List<LearningBlock> blocks;

  LearningPage({
    required this.pageNo,
    required this.titleEn,
    required this.titleTl,
    required this.blocks,
  });

  factory LearningPage.fromMap(Map<String, dynamic> m) {
    final blocks = _list(m['blocks'])
        .map((x) => LearningBlock.fromMap(Map<String, dynamic>.from(x)))
        .toList()
      ..sort((a, b) => a.blockNo.compareTo(b.blockNo));
    return LearningPage(
      pageNo: _int(m['page_no']),
      titleEn: _str(m['title_en']),
      titleTl: _str(m['title_tl']),
      blocks: blocks,
    );
  }

  String title(bool isTl) => isTl && titleTl.trim().isNotEmpty ? titleTl : titleEn;
}

class LearningBlock {
  final int blockNo;
  final String blockType;
  final String textEn;
  final String textTl;

  LearningBlock({
    required this.blockNo,
    required this.blockType,
    required this.textEn,
    required this.textTl,
  });

  factory LearningBlock.fromMap(Map<String, dynamic> m) {
    return LearningBlock(
      blockNo: _int(m['block_no']),
      blockType:
          _str(m['block_type']).isEmpty ? 'paragraph' : _str(m['block_type']),
      textEn: _str(m['text_en']),
      textTl: _str(m['text_tl']),
    );
  }

  String text(bool isTl) => isTl && textTl.trim().isNotEmpty ? textTl : textEn;
}

class LearningMediaAsset {
  final int displayOrder;
  final String assetKey;
  final String assetPath;
  final String publicUrl;
  final String assetType;
  final String altEn;
  final String altTl;

  LearningMediaAsset({
    required this.displayOrder,
    required this.assetKey,
    required this.assetPath,
    required this.publicUrl,
    required this.assetType,
    required this.altEn,
    required this.altTl,
  });

  factory LearningMediaAsset.fromMap(Map<String, dynamic> m) {
    return LearningMediaAsset(
      displayOrder: _int(m['display_order']),
      assetKey: _str(m['asset_key']),
      assetPath: _str(m['asset_path']),
      publicUrl: _str(m['public_url']),
      assetType: _str(m['asset_type']),
      altEn: _str(m['alt_en']),
      altTl: _str(m['alt_tl']),
    );
  }

  String alt(bool isTl) => isTl && altTl.trim().isNotEmpty ? altTl : altEn;
}

class FireClassGuide {
  final String classNameEn;
  final String classNameTl;
  final String imageAsset;
  final List<String> examplesEn;
  final List<String> examplesTl;
  final List<String> agentsEn;
  final List<String> agentsTl;

  FireClassGuide({
    required this.classNameEn,
    required this.classNameTl,
    required this.imageAsset,
    required this.examplesEn,
    required this.examplesTl,
    required this.agentsEn,
    required this.agentsTl,
  });

  factory FireClassGuide.fromMap(Map<String, dynamic> m) {
    return FireClassGuide(
      classNameEn: _str(m['class_name_en']),
      classNameTl: _str(m['class_name_tl']),
      imageAsset: _str(m['image_asset']),
      examplesEn: _stringList(m['examples_en']),
      examplesTl: _stringList(m['examples_tl']),
      agentsEn: _stringList(m['agents_en']),
      agentsTl: _stringList(m['agents_tl']),
    );
  }

  String name(bool isTl) => isTl && classNameTl.trim().isNotEmpty ? classNameTl : classNameEn;
  List<String> examples(bool isTl) => isTl && examplesTl.isNotEmpty ? examplesTl : examplesEn;
  List<String> agents(bool isTl) => isTl && agentsTl.isNotEmpty ? agentsTl : agentsEn;
}

class _ProfileHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _ProfileHeader({
    required this.greeting,
    required this.subtitle,
    required this.avatarUrl,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              if (value == 'profile') onProfile();
              if (value == 'logout') onLogout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded),
                    const SizedBox(width: 8),
                    Text(context.tr('profile')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded),
                    const SizedBox(width: 8),
                    Text(context.tr('log_out')),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE5E7EB),
              backgroundImage: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.trim().isEmpty)
                  ? const Icon(Icons.person, color: Color(0xFF6B7280))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hintText;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const _SearchField({
    required this.hintText,
    required this.value,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final int moduleNo;
  final String moduleLabel;
  final String title;
  final String description;
  final LearningMediaAsset? image;
  final VoidCallback onPressed;

  const _ModuleCard({
    required this.moduleNo,
    required this.moduleLabel,
    required this.title,
    required this.description,
    required this.image,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _moduleAccent(moduleNo);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: image == null
                    ? Icon(_moduleIcon(moduleNo), size: 38, color: accent)
                    : _DbImage(asset: image!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            moduleLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_moduleIcon(moduleNo), color: accent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final Color accent;
  final Color accent2;
  final String moduleLabel;
  final String title;
  final String pageTitle;
  final int currentPage;
  final int totalPages;
  final double progress;
  final VoidCallback onBack;

  const _DetailHeader({
    required this.accent,
    required this.accent2,
    required this.moduleLabel,
    required this.title,
    required this.pageTitle,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: accent.withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back_rounded, color: accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accent, accent2]),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        moduleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$currentPage/$totalPages',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pageTitle,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(totalPages, (index) {
              final active = index == currentPage - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active ? accent : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Color accent;
  final Color accent2;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _ContentCard({
    required this.accent,
    required this.accent2,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, accent2]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final Color accent;
  final bool initiallyExpanded;
  final Widget child;

  const _ExpandableSection({
    required this.title,
    required this.accent,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: initiallyExpanded,
          iconColor: accent,
          collapsedIconColor: accent,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Color accent;
  final Color accent2;
  final bool canNext;
  final bool last;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String backText;
  final String nextText;

  const _BottomActionBar({
    required this.accent,
    required this.accent2,
    required this.canNext,
    required this.last,
    required this.onBack,
    required this.onNext,
    required this.backText,
    required this.nextText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onBack,
              child: Text(
                backText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: canNext ? onNext : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        nextText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      last
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DbImage extends StatelessWidget {
  final LearningMediaAsset asset;

  const _DbImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    final url = asset.publicUrl.trim();
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    final local = asset.assetPath.trim();
    if (local.isNotEmpty) {
      return Image.asset(
        local,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() => const Icon(
        Icons.local_fire_department_rounded,
        color: Color(0xFFB11217),
        size: 38,
      );
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  final Color accent;

  const _Bullets({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((raw) {
        final text = raw.replaceFirst(RegExp(r'^[-•]\s*'), '').trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    height: 1.5,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FireGuide extends StatelessWidget {
  final List<FireClassGuide> guides;
  final bool isTl;
  final Color accent;

  const _FireGuide({
    required this.guides,
    required this.isTl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ex = isTl ? 'Halimbawa' : 'Examples';
    final ag = isTl ? 'Pamatay' : 'Agents';

    return Column(
      children: guides
          .map(
            (g) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      g.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.fire_extinguisher,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.name(isTl),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: accent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$ex: ${g.examples(isTl).join(', ')}',
                          style: const TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$ag: ${g.agents(isTl).join(', ')}',
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final String title;
  final List<LearningMediaAsset> images;
  final bool isTl;
  final Color accent;

  const _ImageGallery({
    required this.title,
    required this.images,
    required this.isTl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: images
          .map(
            (img) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      child: _DbImage(asset: img),
                    ),
                  ),
                  if (img.alt(isTl).trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      img.alt(isTl),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final Color color;
  final VoidCallback onPressed;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

Color _moduleAccent(int moduleNo) {
  switch (moduleNo) {
    case 2:
      return const Color(0xFFF97316);
    case 3:
      return const Color(0xFF2563EB);
    case 4:
      return const Color(0xFFF59E0B);
    case 5:
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFFB11217);
  }
}

Color _moduleAccent2(int moduleNo) {
  switch (moduleNo) {
    case 2:
      return const Color(0xFFF59E0B);
    case 3:
      return const Color(0xFF1D4ED8);
    case 4:
      return const Color(0xFFF97316);
    case 5:
      return const Color(0xFFF97316);
    default:
      return const Color(0xFFF97316);
  }
}

IconData _moduleIcon(int moduleNo) {
  switch (moduleNo) {
    case 2:
      return Icons.home_rounded;
    case 3:
      return Icons.electric_bolt_rounded;
    case 4:
      return Icons.restaurant_rounded;
    case 5:
      return Icons.apartment_rounded;
    default:
      return Icons.fire_extinguisher_rounded;
  }
}

List<dynamic> _list(dynamic v) => v is List ? v : const [];
String _str(dynamic v) => (v ?? '').toString();
int _int(dynamic v) =>
    v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
List<String> _stringList(dynamic v) => v is List
    ? v
        .map((x) => (x ?? '').toString())
        .where((x) => x.trim().isNotEmpty)
        .toList()
    : const [];
