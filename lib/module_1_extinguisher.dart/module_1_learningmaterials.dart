import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_assess_instruction.dart';

class AppColors {
  static const Color brandRed = Color(0xFFB11217);
  static const Color brandRedDark = Color(0xFF7A1014);
  static const Color brandRedDeep = Color(0xFF4E070A);
  static const Color brandRedLight = Color(0xFFE64A4F);
  static const Color brandRedSoft = Color(0xFFFFE8EA);
  static const Color background = Color(0xFFFFF7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnRed = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFFB020);
  static const Color info = Color(0xFF2563EB);
}

String _uiText(BuildContext context, String en, String tl) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

int _asInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const <String>[];
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Color _hexColor(String? raw, Color fallback) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  var hex = raw.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final value = int.tryParse(hex, radix: 16);
  return value == null ? fallback : Color(value);
}

Color _roleColor(String? role) {
  switch (role) {
    case 'red_dark':
      return AppColors.brandRedDark;
    case 'danger':
      return const Color(0xFFDC2626);
    case 'success':
      return AppColors.success;
    case 'blue':
      return AppColors.info;
    case 'warning':
      return AppColors.warning;
    default:
      return AppColors.brandRed;
  }
}

IconData _roleIcon(String? role) {
  switch (role) {
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'checklist':
      return Icons.checklist_rounded;
    case 'block':
      return Icons.block_rounded;
    case 'flag':
      return Icons.flag_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'label':
      return Icons.label_important_rounded;
    case 'fire':
      return Icons.local_fire_department_rounded;
    case 'extinguisher':
      return Icons.fire_extinguisher_rounded;
    case 'category':
      return Icons.category_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'verified':
      return Icons.verified_rounded;
    case 'video':
      return Icons.ondemand_video_rounded;
    case 'park':
      return Icons.park_rounded;
    case 'gas':
      return Icons.local_gas_station_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'metal':
      return Icons.precision_manufacturing_rounded;
    case 'kitchen':
      return Icons.restaurant_rounded;
    case 'water':
      return Icons.water_drop_rounded;
    case 'security':
      return Icons.security_rounded;
    case 'view3d':
      return Icons.view_in_ar_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

class _SourceData {
  final String label;
  final String title;
  final String organization;
  final String url;
  const _SourceData({required this.label, required this.title, required this.organization, required this.url});

  factory _SourceData.fromMap(BuildContext context, _MaterialData material, Map<String, dynamic> map) {
    return _SourceData(
      label: material.textFrom(context, map, 'label'),
      title: (map['title'] ?? '').toString(),
      organization: (map['organization'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
    );
  }
}

class _MediaAsset {
  final String key;
  final String path;
  final String? publicUrl;
  final String type;
  const _MediaAsset({required this.key, required this.path, required this.publicUrl, required this.type});
  String get effectivePath => (publicUrl ?? '').trim().isNotEmpty ? publicUrl! : path;
}

class _FireGuide {
  final int order;
  final String key;
  final String nameEn;
  final String? nameTl;
  final String? imageAsset;
  final List<String> examplesEn;
  final List<String> examplesTl;
  final List<String> agentsEn;
  final List<String> agentsTl;
  const _FireGuide({required this.order, required this.key, required this.nameEn, required this.nameTl, required this.imageAsset, required this.examplesEn, required this.examplesTl, required this.agentsEn, required this.agentsTl});
}

class _BlockData {
  final String id;
  final String pageId;
  final int pageNo;
  final int blockNo;
  final String key;
  final String type;
  final String textEn;
  final String? textTl;
  final String? sourceTitle;
  final String? sourceOrganization;
  final String? sourceUrl;
  final Map<String, dynamic> meta;
  const _BlockData({required this.id, required this.pageId, required this.pageNo, required this.blockNo, required this.key, required this.type, required this.textEn, required this.textTl, required this.sourceTitle, required this.sourceOrganization, required this.sourceUrl, required this.meta});

  String text(BuildContext context, _MaterialData material) => material.localize(context, textEn, textTl);
  String metaText(BuildContext context, _MaterialData material, String base) => material.textFrom(context, meta, base);
  List<String> metaList(BuildContext context, _MaterialData material, String base) => material.listFrom(context, meta, base);
  int metaInt(String key, int fallback) => _asInt(meta[key], fallback);
  String? metaString(String key) {
    final value = meta[key]?.toString();
    return value == null || value.trim().isEmpty ? null : value;
  }
  List<Map<String, dynamic>> mapList(String key) {
    final raw = meta[key];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
  _SourceData? source(BuildContext context, _MaterialData material) {
    if ((sourceTitle ?? '').isEmpty || (sourceOrganization ?? '').isEmpty || (sourceUrl ?? '').isEmpty) return null;
    final label = metaText(context, material, 'source_label').trim();
    return _SourceData(label: label.isEmpty ? _uiText(context, 'Reference', 'Sanggunian') : label, title: sourceTitle!, organization: sourceOrganization!, url: sourceUrl!);
  }
}

class _PageData {
  final String id;
  final int pageNo;
  final String key;
  final String titleEn;
  final String titleTl;
  final List<_BlockData> blocks;
  const _PageData({required this.id, required this.pageNo, required this.key, required this.titleEn, required this.titleTl, required this.blocks});
}

class _MaterialData {
  final String id;
  final int moduleNo;
  final String titleEn;
  final String titleTl;
  final String? subtitleEn;
  final String? subtitleTl;
  final String? heroAsset;
  final Map<String, dynamic> content;
  final List<_PageData> pages;
  final Map<String, _MediaAsset> media;
  final Map<String, _FireGuide> guides;
  const _MaterialData({required this.id, required this.moduleNo, required this.titleEn, required this.titleTl, required this.subtitleEn, required this.subtitleTl, required this.heroAsset, required this.content, required this.pages, required this.media, required this.guides});

  _PageData page(int pageNo) => pages.firstWhere((p) => p.pageNo == pageNo);

  String localize(BuildContext context, String? en, String? tl) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    if (isTl && tl != null && tl.trim().isNotEmpty) return tl;
    if (en != null && en.trim().isNotEmpty) return en;
    return tl ?? '';
  }

  String textFrom(BuildContext context, Map<String, dynamic> source, String base) {
    return localize(context, source['${base}_en']?.toString(), source['${base}_tl']?.toString());
  }

  List<String> listFrom(BuildContext context, Map<String, dynamic> source, String base) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    final raw = isTl ? source['${base}_tl'] : source['${base}_en'];
    final fallback = source['${base}_en'];
    return _stringList(raw is List ? raw : fallback);
  }

  Map<String, dynamic> get dialogs => _map(content['dialogs']);
  Map<String, dynamic> get classPage => _map(content['class_guide_page']);

  String mediaUrl(String? assetKeyOrPath) {
    if (assetKeyOrPath == null || assetKeyOrPath.trim().isEmpty) return '';
    final raw = media[assetKeyOrPath]?.effectivePath ?? assetKeyOrPath;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    return Supabase.instance.client.storage
        .from(_Repository.storageBucket)
        .getPublicUrl(raw)
        .replaceAll(' ', '%20');
  }
}

class _Repository {
  static const int moduleNo = 1;
  static const String storageBucket = 'Learning Materials';

  static Future<_MaterialData> load() async {
    final client = Supabase.instance.client;
    final materialRaw = await client
        .from('learning_materials')
        .select('id, module_no, title, title_tl, subtitle, subtitle_tl, hero_asset, content')
        .eq('module_no', moduleNo)
        .eq('is_active', true)
        .maybeSingle();
    if (materialRaw == null) throw StateError('Module 1 learning material not found.');
    final material = Map<String, dynamic>.from(materialRaw);
    final materialId = material['id']?.toString() ?? '';
    if (materialId.isEmpty) throw StateError('Module 1 learning material has no id.');

    final pageRows = await client
        .from('learning_material_pages')
        .select('id, page_no, page_key, title_en, title_tl')
        .eq('learning_material_id', materialId)
        .eq('module_no', moduleNo)
        .eq('is_active', true)
        .order('page_no', ascending: true);
    final blockRows = await client
        .from('learning_material_blocks')
        .select('id, page_id, page_no, block_no, block_key, block_type, text_en, text_tl, source_title, source_organization, source_url, metadata')
        .eq('module_no', moduleNo)
        .eq('is_active', true)
        .order('page_no', ascending: true)
        .order('block_no', ascending: true);
    final mediaRows = await client
        .from('learning_material_media_assets')
        .select('asset_key, asset_path, public_url, asset_type')
        .eq('learning_material_id', materialId)
        .eq('module_no', moduleNo)
        .eq('is_active', true)
        .order('display_order', ascending: true);
    final guideRows = await client
        .from('learning_material_fire_class_guides')
        .select('display_order, class_key, class_name_en, class_name_tl, image_asset, examples_en, examples_tl, agents_en, agents_tl')
        .eq('module_no', moduleNo)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    final blocksByPageId = <String, List<_BlockData>>{};
    for (final item in blockRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(item as Map);
      final pageId = row['page_id']?.toString() ?? '';
      final block = _BlockData(
        id: row['id']?.toString() ?? '',
        pageId: pageId,
        pageNo: _asInt(row['page_no'], 0),
        blockNo: _asInt(row['block_no'], 0),
        key: row['block_key']?.toString() ?? '',
        type: row['block_type']?.toString() ?? '',
        textEn: row['text_en']?.toString() ?? '',
        textTl: row['text_tl']?.toString(),
        sourceTitle: row['source_title']?.toString(),
        sourceOrganization: row['source_organization']?.toString(),
        sourceUrl: row['source_url']?.toString(),
        meta: _map(row['metadata']),
      );
      blocksByPageId.putIfAbsent(pageId, () => <_BlockData>[]).add(block);
    }

    final pages = <_PageData>[];
    for (final item in pageRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(item as Map);
      final id = row['id']?.toString() ?? '';
      pages.add(_PageData(id: id, pageNo: _asInt(row['page_no'], 0), key: row['page_key']?.toString() ?? '', titleEn: row['title_en']?.toString() ?? '', titleTl: row['title_tl']?.toString() ?? '', blocks: blocksByPageId[id] ?? const <_BlockData>[]));
    }
    if (pages.length != 3) throw StateError('Module 1 must have exactly 3 active learning-material pages.');

    final media = <String, _MediaAsset>{};
    for (final item in mediaRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(item as Map);
      final key = row['asset_key']?.toString() ?? '';
      final path = row['asset_path']?.toString() ?? '';
      if (key.isEmpty || path.isEmpty) continue;
      media[key] = _MediaAsset(key: key, path: path, publicUrl: row['public_url']?.toString(), type: row['asset_type']?.toString() ?? 'image');
    }

    final guides = <String, _FireGuide>{};
    for (final item in guideRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(item as Map);
      final key = row['class_key']?.toString() ?? '';
      if (key.isEmpty) continue;
      guides[key] = _FireGuide(order: _asInt(row['display_order'], 0), key: key, nameEn: row['class_name_en']?.toString() ?? '', nameTl: row['class_name_tl']?.toString(), imageAsset: row['image_asset']?.toString(), examplesEn: _stringList(row['examples_en']), examplesTl: _stringList(row['examples_tl']), agentsEn: _stringList(row['agents_en']), agentsTl: _stringList(row['agents_tl']));
    }

    return _MaterialData(id: materialId, moduleNo: _asInt(material['module_no'], moduleNo), titleEn: material['title']?.toString() ?? '', titleTl: material['title_tl']?.toString() ?? '', subtitleEn: material['subtitle']?.toString(), subtitleTl: material['subtitle_tl']?.toString(), heroAsset: material['hero_asset']?.toString(), content: _map(material['content']), pages: pages, media: media, guides: guides);
  }
}

class LearningMaterialExtinguisherPage extends StatefulWidget {
  const LearningMaterialExtinguisherPage({super.key});

  @override
  State<LearningMaterialExtinguisherPage> createState() => _LearningMaterialExtinguisherPageState();
}

class _LearningMaterialExtinguisherPageState extends State<LearningMaterialExtinguisherPage> {
  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Set<int>> _readSections = [<int>{}, <int>{}, <int>{}];

  _MaterialData? _data;
  bool _loading = true;
  String? _error;
  int _pageIndex = 0;
  double _scrollProgress = 0.0;
  bool _introShown = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _Repository.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
      if (!_introShown) {
        _introShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showDialogFromDb('intro', Icons.auto_stories_rounded, AppColors.brandRed, barrierDismissible: false));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final value = max <= 0 ? 1.0 : (_scrollCtrl.offset / max).clamp(0.0, 1.0).toDouble();
    if ((_scrollProgress - value).abs() > 0.01) setState(() => _scrollProgress = value);
  }

  _MaterialData get data => _data!;

  String _dialogText(String key, String field) {
    final dialog = _map(data.dialogs[key]);
    return data.textFrom(context, dialog, field);
  }

  void _showDialogFromDb(String key, IconData icon, Color color, {bool barrierDismissible = true}) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => _ContentDialog(
        icon: icon,
        color: color,
        title: _dialogText(key, 'title'),
        body: _dialogText(key, 'body'),
        button: _dialogText(key, 'button'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showInfo(String title, String body, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (_) => _ContentDialog(
        icon: icon,
        color: color,
        title: title,
        body: body,
        button: _uiText(context, 'Got it', 'Naiintindihan'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  int _requiredSections(int pageIndex) {
    for (final block in data.page(pageIndex + 1).blocks) {
      if (block.type == 'reading_progress') return block.metaInt('required_sections', 0);
    }
    return 0;
  }

  bool _pageRead(int pageIndex) => _readSections[pageIndex].length >= _requiredSections(pageIndex);

  void _goNext() {
    if (!_pageRead(_pageIndex)) {
      _showDialogFromDb('unread_sections', Icons.menu_book_rounded, AppColors.brandRed);
      return;
    }
    if (_pageIndex < data.pages.length - 1) {
      final dialogKey = _pageIndex == 0 ? 'page_1_complete' : 'page_2_complete';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ContentDialog(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: _dialogText(dialogKey, 'title'),
          body: _dialogText(dialogKey, 'body'),
          button: _dialogText(dialogKey, 'button'),
          onPressed: () {
            Navigator.pop(context);
            _pageCtrl.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ContentDialog(
          icon: Icons.emoji_events_rounded,
          color: AppColors.brandRed,
          title: _dialogText('final_complete', 'title'),
          body: _dialogText('final_complete', 'body'),
          button: _dialogText('final_complete', 'button'),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PostAssessmentIntroPage()));
          },
        ),
      );
    }
  }

  void _goBack() {
    if (_pageIndex == 0) {
      Navigator.pop(context);
      return;
    }
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _ScreenShell(child: Center(child: CircularProgressIndicator(color: AppColors.brandRed)));
    if (_error != null || _data == null) {
      return _ScreenShell(
        child: Center(
          child: _ErrorCard(message: _error ?? 'No learning material data.', onRetry: _load, onClose: () => Navigator.pop(context)),
        ),
      );
    }

    final header = _map(data.content['header']);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LMGradientBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: _TopHeader(
                    sectionTitle: data.textFrom(context, header, 'section_title'),
                    moduleLabel: data.textFrom(context, header, 'module_label'),
                    moduleTitle: data.localize(context, data.titleEn, data.titleTl),
                    currentPage: _pageIndex + 1,
                    totalPages: data.pages.length,
                    progress: _scrollProgress,
                    onClose: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                        _scrollProgress = 0.0;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
                      });
                    },
                    children: data.pages.map((page) => _pageWrap(_buildPage(page))).toList(),
                  ),
                ),
                _BottomNav(isLast: _pageIndex == data.pages.length - 1, enabled: _pageRead(_pageIndex), onBack: _goBack, onNext: _goNext),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageWrap(Widget child) {
    return SingleChildScrollView(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: child,
      ),
    );
  }

  Widget _buildPage(_PageData page) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in page.blocks) ...[
          _buildBlock(page, block),
          SizedBox(height: block.type == 'reading_progress' ? 0 : 14),
        ],
      ],
    );
  }

  Widget _buildBlock(_PageData page, _BlockData block) {
    switch (block.type) {
      case 'page_banner':
        return _PageBanner(tag: block.metaText(context, data, 'page_tag'), title: block.text(context, data), subtitle: block.metaText(context, data, 'subtitle'), pageNo: page.pageNo);
      case 'media_card':
        return _MediaCard(imageUrl: data.mediaUrl(block.metaString('asset_key')), title: block.text(context, data), subtitle: block.metaText(context, data, 'subtitle'));
      case 'did_you_know':
        return Column(children: [_InfoTip(text: block.metaText(context, data, 'teaser'), onTap: () => _showInfo(block.metaText(context, data, 'popup_title'), block.text(context, data), Icons.tips_and_updates_rounded, AppColors.brandRed)), if (block.source(context, data) != null) ...[const SizedBox(height: 8), _SourceCard(source: block.source(context, data)!)]]) ;
      case 'expandable_lesson':
        return _ExpandableContent(title: block.text(context, data), icon: _roleIcon(block.metaString('icon_role')), color: _roleColor(block.metaString('accent_role')), isRead: _readSections[page.pageNo - 1].contains(block.metaInt('section_index', 0)), onOpen: () => setState(() => _readSections[page.pageNo - 1].add(block.metaInt('section_index', 0))), child: _parts(block));
      case 'tip':
        return Column(children: [_InfoTip(text: block.text(context, data)), if (block.source(context, data) != null) ...[const SizedBox(height: 8), _SourceCard(source: block.source(context, data)!)]]) ;
      case 'section_header':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_SectionTitle(block.text(context, data)), if (block.source(context, data) != null) ...[const SizedBox(height: 8), _SourceCard(source: block.source(context, data)!)]]) ;
      case 'fire_class_tile':
        return _FireClassTile(block: block, guide: data.guides[block.metaString('class_key')], material: data, isRead: _readSections[page.pageNo - 1].contains(block.metaInt('section_index', 0)), onTap: () => setState(() => _readSections[page.pageNo - 1].add(block.metaInt('section_index', 0))));
      case 'action_pills':
        return _actions(block.meta);
      case 'pass_step':
        return _PassStep(block: block, material: data, isRead: _readSections[page.pageNo - 1].contains(block.metaInt('section_index', 0)), onOpen: () => setState(() => _readSections[page.pageNo - 1].add(block.metaInt('section_index', 0))));
      case 'lesson_intro':
        return Column(children: [_InfoTip(text: block.text(context, data)), if (block.source(context, data) != null) ...[const SizedBox(height: 8), _SourceCard(source: block.source(context, data)!)]]) ;
      case 'callout':
        return _Callout(title: block.text(context, data), lines: block.metaList(context, data, 'lines'), icon: _roleIcon(block.metaString('icon_role')), color: _roleColor(block.metaString('accent_role')));
      case 'reading_progress':
        return _ReadBadge(read: _readSections[page.pageNo - 1].length, total: block.metaInt('required_sections', 0));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _parts(_BlockData block) {
    final children = <Widget>[];
    for (final part in block.mapList('parts')) {
      final widget = _part(part);
      if (widget == null) continue;
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(widget);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget? _part(Map<String, dynamic> part) {
    switch (part['type']?.toString()) {
      case 'body_text':
        return _BodyText(data.textFrom(context, part, 'text'));
      case 'image_body':
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_ImageBox(url: data.mediaUrl(part['asset_key']?.toString()), icon: Icons.fire_extinguisher_rounded), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_MiniTitle(data.textFrom(context, part, 'title')), const SizedBox(height: 6), _BodyText(data.textFrom(context, part, 'text'))]))]);
      case 'mini_headline':
        return _MiniTitle(data.textFrom(context, part, 'text'));
      case 'callout':
        return _Callout(title: data.textFrom(context, part, 'title'), lines: data.listFrom(context, part, 'lines'), icon: _roleIcon(part['icon_role']?.toString()), color: _roleColor(part['accent_role']?.toString()));
      case 'reference':
        return _SourceCard(source: _SourceData.fromMap(context, data, part));
      case 'action_pills':
        return _actions(part);
      case 'chip_line':
        return _ChipLine(icon: _roleIcon(part['icon_role']?.toString()), color: _roleColor(part['accent_role']?.toString()), text: data.textFrom(context, part, 'text'));
      default:
        return null;
    }
  }

  Widget _actions(Map<String, dynamic> source) {
    final pills = source['pills'] is List ? (source['pills'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const <Map<String, dynamic>>[];
    final children = <Widget>[];
    children.add(Row(children: [for (int i = 0; i < pills.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: _ActionPill(icon: _roleIcon(pills[i]['icon_role']?.toString()), label: data.textFrom(context, pills[i], 'label'), onTap: () => _showInfo(data.textFrom(context, pills[i], 'popup_title'), data.textFrom(context, pills[i], 'popup_body'), _roleIcon(pills[i]['icon_role']?.toString()), _roleColor(pills[i]['accent_role']?.toString()))))]]));
    final wide = _map(source['wide_card']);
    if (wide.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_WideAction(icon: _roleIcon(wide['icon_role']?.toString()), title: data.textFrom(context, wide, 'title'), subtitle: data.textFrom(context, wide, 'subtitle'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassesOfFirePage(material: data)))));
    }
    return Column(children: children);
  }
}

class _ScreenShell extends StatelessWidget {
  final Widget child;
  const _ScreenShell({required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background, body: Stack(children: [const _LMGradientBackdrop(), SafeArea(child: child)]));
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  const _ErrorCard({required this.message, required this.onRetry, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.all(24), padding: const EdgeInsets.all(20), decoration: _cardDecoration(), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline_rounded, color: AppColors.brandRed, size: 42), const SizedBox(height: 12), Text(_uiText(context, 'Learning materials could not load', 'Hindi ma-load ang modyul sa pag-aaral'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)), const SizedBox(height: 16), Row(children: [Expanded(child: OutlinedButton(onPressed: onClose, child: Text(_uiText(context, 'Close', 'Isara')))), const SizedBox(width: 10), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRed), onPressed: onRetry, child: Text(_uiText(context, 'Retry', 'Subukan muli'), style: const TextStyle(color: Colors.white))))])])) ;
}

BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8))]);

class _LMGradientBackdrop extends StatelessWidget {
  const _LMGradientBackdrop();
  @override
  Widget build(BuildContext context) => Stack(children: [Container(color: AppColors.background), Container(height: 280, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brandRedDeep, AppColors.brandRedDark, AppColors.brandRed]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)))), Positioned(top: 50, right: -36, child: _Circle(size: 138, opacity: 0.17)), Positioned(top: 178, left: -42, child: _Circle(size: 124, opacity: 0.13))]);
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white.withOpacity(opacity), shape: BoxShape.circle));
}

class _TopHeader extends StatelessWidget {
  final String sectionTitle;
  final String moduleLabel;
  final String moduleTitle;
  final int currentPage;
  final int totalPages;
  final double progress;
  final VoidCallback onClose;
  const _TopHeader({required this.sectionTitle, required this.moduleLabel, required this.moduleTitle, required this.currentPage, required this.totalPages, required this.progress, required this.onClose});
  @override
  Widget build(BuildContext context) {
    final pageLabel = _uiText(context, 'Page', 'Pahina');
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Row(children: [InkWell(onTap: onClose, borderRadius: BorderRadius.circular(999), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white))), const Spacer()]), const SizedBox(height: 14), Text(sectionTitle, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900)), const SizedBox(height: 12), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.brandRedLight, borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.menu_book_rounded, color: Colors.white, size: 15), const SizedBox(width: 6), Text(moduleLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))])), const SizedBox(width: 10), Expanded(child: Text(moduleTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12.5, height: 1.28, fontWeight: FontWeight.w700)))]), const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 8, backgroundColor: Colors.white.withOpacity(0.22), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))), const SizedBox(height: 10), Row(children: [Text('$pageLabel $currentPage/$totalPages', style: TextStyle(color: Colors.white.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w700)), const Spacer(), Wrap(spacing: 6, children: List.generate(totalPages, (index) => AnimatedContainer(duration: const Duration(milliseconds: 180), width: index == currentPage - 1 ? 28 : 10, height: 10, decoration: BoxDecoration(color: index == currentPage - 1 ? Colors.white : Colors.white.withOpacity(0.34), borderRadius: BorderRadius.circular(999)))))] )]);
  }
}

class _BottomNav extends StatelessWidget {
  final bool isLast;
  final bool enabled;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _BottomNav({required this.isLast, required this.enabled, required this.onBack, required this.onNext});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(18, 10, 18, 18), color: AppColors.background, child: Row(children: [Expanded(flex: 4, child: SizedBox(height: 48, child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandRed), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), onPressed: onBack, child: Text(_uiText(context, 'Back', 'Balik'), style: const TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.bold))))), const SizedBox(width: 12), Expanded(flex: 7, child: SizedBox(height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: enabled ? AppColors.brandRed : AppColors.brandRedSoft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), onPressed: onNext, child: Text(isLast ? _uiText(context, 'Start Post-Test', 'Simulan ang Panghuling Pagsusulit') : _uiText(context, 'Next', 'Susunod'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: enabled ? Colors.white : AppColors.brandRed.withOpacity(0.4), fontWeight: FontWeight.bold)))))]));
}

class _ContentDialog extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;
  const _ContentDialog({required this.icon, required this.color, required this.title, required this.body, required this.button, required this.onPressed});
  @override
  Widget build(BuildContext context) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), insetPadding: const EdgeInsets.symmetric(horizontal: 28), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)), const SizedBox(height: 10), Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF374151))), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: onPressed, child: Text(button, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))))])));
}

class _PageBanner extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final int pageNo;
  const _PageBanner({required this.tag, required this.title, required this.subtitle, required this.pageNo});
  @override
  Widget build(BuildContext context) {
    final icon = pageNo == 1 ? Icons.lightbulb_rounded : pageNo == 2 ? Icons.category_rounded : Icons.shield_rounded;
    return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.brandRed.withOpacity(0.06), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.brandRed.withOpacity(0.12))), child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.brandRed, AppColors.brandRedDark]), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.white, size: 26)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.brandRed, letterSpacing: 1)), const SizedBox(height: 3), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827), height: 1.2)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.3))]))]));
  }
}

class _MediaCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  const _MediaCard({required this.imageUrl, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7F7), Color(0xFFFFE8EA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandRed.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandRed, AppColors.brandRedDark],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandRed.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15.5,
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.brandRed.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_rounded, size: 16, color: AppColors.brandRed),
                const SizedBox(width: 8),
                Text(
                  _uiText(context, 'TAP TO VIEW IN 3D', 'I-TAP PARA TINGNAN SA 3D'),
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: 176,
              height: 188,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 26,
                    left: 2,
                    child: _PreviewBackPlate(
                      width: 128,
                      height: 138,
                      opacity: 0.20,
                      rotationTurns: -0.055,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 2,
                    child: _PreviewBackPlate(
                      width: 136,
                      height: 146,
                      opacity: 0.24,
                      rotationTurns: 0.055,
                    ),
                  ),
                  Container(
                    width: 146,
                    height: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandRed.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fire_extinguisher_rounded, color: AppColors.brandRed, size: 46),
                          const SizedBox(height: 10),
                          Text(
                            _uiText(context, '3D image unavailable', 'Hindi ma-load ang 3D image'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.brandRed,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ],
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

class _PreviewBackPlate extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  final double rotationTurns;
  const _PreviewBackPlate({required this.width, required this.height, required this.opacity, required this.rotationTurns});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationTurns * 6.283185307179586,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.08)),
        ),
      ),
    );
  }
}

class _InfoTip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _InfoTip({required this.text, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.brandRed.withOpacity(0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.brandRed.withOpacity(0.12))), child: Row(children: [const Icon(Icons.tips_and_updates_rounded, color: AppColors.brandRed), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(height: 1.45, color: Color(0xFF374151), fontWeight: FontWeight.w600))), if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.brandRed)])) );
}

class _ExpandableContent extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isRead;
  final VoidCallback onOpen;
  final Widget child;
  const _ExpandableContent({required this.title, required this.icon, required this.color, required this.isRead, required this.onOpen, required this.child});
  @override
  State<_ExpandableContent> createState() => _ExpandableContentState();
}

class _ExpandableContentState extends State<_ExpandableContent> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.isRead ? AppColors.success.withOpacity(0.3) : widget.color.withOpacity(0.12)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]), child: Column(children: [InkWell(onTap: () { setState(() => expanded = !expanded); if (!expanded) return; widget.onOpen(); }, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: (widget.isRead ? AppColors.success : widget.color).withOpacity(0.10), borderRadius: BorderRadius.circular(12)), child: Icon(widget.isRead ? Icons.check_rounded : widget.icon, color: widget.isRead ? AppColors.success : widget.color)), const SizedBox(width: 12), Expanded(child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.w900, color: widget.isRead ? AppColors.success : const Color(0xFF111827)))), Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: widget.color)]))), if (expanded) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(children: [const Divider(), const SizedBox(height: 10), widget.child]))]));
}

class _FireClassTile extends StatelessWidget {
  final _BlockData block;
  final _FireGuide? guide;
  final _MaterialData material;
  final bool isRead;
  final VoidCallback onTap;
  const _FireClassTile({required this.block, required this.guide, required this.material, required this.isRead, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isRead ? AppColors.success.withOpacity(0.35) : _hexColor(block.metaString('color_hex'), AppColors.brandRed).withOpacity(0.12))), child: Row(children: [Icon(isRead ? Icons.check_circle_rounded : _roleIcon(block.metaString('icon_role')), color: isRead ? AppColors.success : _hexColor(block.metaString('color_hex'), AppColors.brandRed)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(guide == null ? block.metaText(context, material, 'class_label') : material.localize(context, guide!.nameEn, guide!.nameTl), style: TextStyle(fontWeight: FontWeight.w900, color: isRead ? AppColors.success : const Color(0xFF111827))), const SizedBox(height: 3), Text(block.text(context, material), style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4))])), Text(isRead ? '✓' : _uiText(context, 'Tap', 'I-tap'), style: TextStyle(color: isRead ? AppColors.success : AppColors.brandRed, fontWeight: FontWeight.w900))])));
}

class _PassStep extends StatefulWidget {
  final _BlockData block;
  final _MaterialData material;
  final bool isRead;
  final VoidCallback onOpen;
  const _PassStep({required this.block, required this.material, required this.isRead, required this.onOpen});
  @override
  State<_PassStep> createState() => _PassStepState();
}

class _PassStepState extends State<_PassStep> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.isRead ? AppColors.success.withOpacity(0.35) : AppColors.brandRed.withOpacity(0.12))), child: Column(children: [InkWell(onTap: () { setState(() => expanded = !expanded); if (expanded) widget.onOpen(); }, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [CircleAvatar(backgroundColor: widget.isRead ? AppColors.success : AppColors.brandRed, child: Text(widget.isRead ? '✓' : (widget.block.metaString('letter') ?? ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.block.text(context, widget.material), style: TextStyle(fontWeight: FontWeight.w900, color: widget.isRead ? AppColors.success : const Color(0xFF111827))), Text(widget.block.metaText(context, widget.material, 'desc'), style: const TextStyle(color: Color(0xFF6B7280), height: 1.35))])), Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.brandRed)]))), if (expanded) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Divider(), const SizedBox(height: 12), _VideoCard(title: widget.block.metaText(context, widget.material, 'video_title'), url: widget.material.mediaUrl(widget.block.metaString('asset_key')))]))]));
}

class _VideoCard extends StatefulWidget {
  final String title;
  final String url;
  const _VideoCard({required this.title, required this.url});
  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? controller;
  Future<void>? initFuture;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) {
      failed = true;
      return;
    }
    controller = VideoPlayerController.network(widget.url);
    initFuture = controller!.initialize().then((_) { controller!.setLooping(false); if (mounted) setState(() {}); }).catchError((_) { if (mounted) setState(() => failed = true); });
  }
  @override
  void dispose() { controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (failed) return _VideoPlaceholder(title: _uiText(context, 'Video could not load', 'Hindi ma-load ang video'), subtitle: widget.url);
    final c = controller;
    final f = initFuture;
    if (c == null || f == null) return _VideoPlaceholder(title: widget.title, subtitle: widget.url);
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.brandRed.withOpacity(0.12))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.ondemand_video_rounded, color: AppColors.brandRed), const SizedBox(width: 8), Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900)))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: FutureBuilder<void>(future: f, builder: (context, snapshot) { if (snapshot.connectionState != ConnectionState.done || !c.value.isInitialized) return const ColoredBox(color: Color(0xFF111827), child: Center(child: CircularProgressIndicator(color: Colors.white))); return GestureDetector(onTap: () async { c.value.isPlaying ? await c.pause() : await c.play(); if (mounted) setState(() {}); }, child: Stack(fit: StackFit.expand, children: [Container(color: const Color(0xFF111827)), Center(child: AspectRatio(aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio, child: VideoPlayer(c))), if (!c.value.isPlaying) const Center(child: CircleAvatar(radius: 30, backgroundColor: Colors.black54, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38))), Positioned(left: 0, right: 0, bottom: 0, child: VideoProgressIndicator(c, allowScrubbing: true, padding: EdgeInsets.zero))])); })))]) );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  const _VideoPlaceholder({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(height: 180, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.ondemand_video_rounded, color: Colors.white, size: 36), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11))]));
}

class _Callout extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData icon;
  final Color color;
  const _Callout({required this.title, required this.lines, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.15))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color)), const SizedBox(height: 8), for (final line in lines) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.w900)), Expanded(child: Text(line, style: const TextStyle(height: 1.45, color: Color(0xFF374151))))]))]))]));
}

class _SourceCard extends StatelessWidget {
  final _SourceData source;
  const _SourceCard({required this.source});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.brandRedSoft.withOpacity(0.62), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.brandRed.withOpacity(0.16))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.verified_rounded, color: AppColors.brandRed), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(source.label, style: const TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('${source.title} • ${source.organization}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(source.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5))]))]));
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.brandRed, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827))))]);
}

class _MiniTitle extends StatelessWidget {
  final String text;
  const _MiniTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF111827)));
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13.5, height: 1.55, color: Color(0xFF4B5563)));
}

class _ImageBox extends StatelessWidget {
  final String url;
  final IconData icon;
  const _ImageBox({required this.url, required this.icon});
  @override
  Widget build(BuildContext context) => Container(width: 110, height: 110, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.brandRed.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(icon, size: 40, color: AppColors.brandRed)));
}

class _ChipLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ChipLine({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.18))), child: Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5)))]));
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionPill({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.brandRed.withOpacity(0.10))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: AppColors.brandRed), const SizedBox(width: 6), Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 12.5)))])));
}

class _WideAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WideAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF4F4), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.brandRed.withOpacity(0.10))), child: Row(children: [Icon(icon, color: AppColors.brandRed), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), height: 1.4, fontSize: 12))])), const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brandRed)])));
}

class _ReadBadge extends StatelessWidget {
  final int read;
  final int total;
  const _ReadBadge({required this.read, required this.total});
  @override
  Widget build(BuildContext context) {
    final done = read >= total;
    final color = done ? AppColors.success : AppColors.brandRed;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))), child: Row(children: [Icon(done ? Icons.check_circle_rounded : Icons.menu_book_rounded, color: color), const SizedBox(width: 10), Expanded(child: Text(done ? _uiText(context, 'All sections read ✓', 'Lahat ng seksyon ay nabasa ✓') : _uiText(context, 'Sections read: $read / $total', 'Mga seksyong nabasa: $read / $total'), style: TextStyle(color: color, fontWeight: FontWeight.w800)))]));
  }
}


class ClassesOfFirePage extends StatelessWidget {
  final _MaterialData material;
  const ClassesOfFirePage({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    final cfg = material.classPage;
    final header = _map(cfg['header']);
    final guides = material.guides.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LMGradientBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: _TopHeader(
                    sectionTitle: material.textFrom(context, header, 'section_title'),
                    moduleLabel: material.textFrom(context, header, 'module_label'),
                    moduleTitle: material.textFrom(context, header, 'module_title'),
                    currentPage: 2,
                    totalPages: 3,
                    progress: 1,
                    onClose: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              material.textFrom(context, cfg, 'title'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandRed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            material.textFrom(context, cfg, 'description'),
                            style: const TextStyle(height: 1.55, color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 22),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: guides.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (_, i) => _GuideCard(material: material, guide: guides[i]),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            material.textFrom(context, cfg, 'training_title'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            material.textFrom(context, cfg, 'training_body'),
                            style: const TextStyle(height: 1.55, color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 25),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(_uiText(context, '« BACK', '« BALIK')),
                          ),
                        ],
                      ),
                    ),
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

class _GuideCard extends StatelessWidget {
  final _MaterialData material;
  final _FireGuide guide;
  const _GuideCard({required this.material, required this.guide});

  @override
  Widget build(BuildContext context) {
    final name = material.localize(context, guide.nameEn, guide.nameTl);
    final image = material.mediaUrl(guide.imageAsset);
    return InkWell(
      onTap: () => _showGuideSheet(context, material, guide),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandRed),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Image.network(
                image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.brandRed,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _uiText(context, 'Tap to explore', 'I-tap upang tingnan'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showGuideSheet(BuildContext context, _MaterialData material, _FireGuide guide) {
  final detailsRoot = _map(material.content['fire_class_details']);
  final details = _map(detailsRoot[guide.key]);
  final isTl = Localizations.localeOf(context).languageCode == 'tl';
  final examples = isTl && guide.examplesTl.isNotEmpty ? guide.examplesTl : guide.examplesEn;
  final agents = isTl && guide.agentsTl.isNotEmpty ? guide.agentsTl : guide.agentsEn;
  final accent = _hexColor(details['accent_hex']?.toString(), AppColors.brandRed);
  final sources = details['sources'] is List
      ? (details['sources'] as List)
          .whereType<Map>()
          .map((e) => _SourceData.fromMap(context, material, Map<String, dynamic>.from(e)))
          .toList()
      : const <_SourceData>[];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Icon(_roleIcon(details['icon_role']?.toString()), color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    material.textFrom(context, details, 'title'),
                    style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              material.textFrom(context, details, 'description'),
              style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _Callout(
              title: material.textFrom(context, details, 'section1_title'),
              lines: examples,
              icon: Icons.local_fire_department_rounded,
              color: accent,
            ),
            const SizedBox(height: 12),
            _Callout(
              title: material.textFrom(context, details, 'section2_title'),
              lines: agents,
              icon: Icons.fire_extinguisher_rounded,
              color: accent,
            ),
            const SizedBox(height: 12),
            if (material.textFrom(context, details, 'note').trim().isNotEmpty)
              _InfoTip(text: material.textFrom(context, details, 'note')),
            const SizedBox(height: 12),
            for (final source in sources) ...[
              _SourceCard(source: source),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}
