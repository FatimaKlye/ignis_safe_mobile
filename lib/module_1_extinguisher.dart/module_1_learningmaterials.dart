import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_assess_instruction.dart';
import 'module_progression_service.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

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
      return Icons.fire_extinguisher_rounded;
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

class _LocalizedText {
  final String en;
  final String? tl;
  const _LocalizedText({required this.en, required this.tl});
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
    return _SourceData(label: label.isEmpty ? material.copy(context, 'source_reference_label') : label, title: sourceTitle!, organization: sourceOrganization!, url: sourceUrl!);
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
  final String moduleId;
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
  final Map<String, _LocalizedText> texts;
  const _MaterialData({required this.id, required this.moduleId, required this.moduleNo, required this.titleEn, required this.titleTl, required this.subtitleEn, required this.subtitleTl, required this.heroAsset, required this.content, required this.pages, required this.media, required this.guides, required this.texts});

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

  String copy(BuildContext context, String key, {String fallback = ''}) {
    final item = texts[key];
    if (item == null) return fallback;
    final value = localize(context, item.en, item.tl).trim();
    return value.isEmpty ? fallback : value;
  }

  String copyFormat(BuildContext context, String key, Map<String, String> values, {String fallback = ''}) {
    var value = copy(context, key, fallback: fallback);
    values.forEach((token, replacement) => value = value.replaceAll('{$token}', replacement));
    return value;
  }

  Map<String, dynamic> get dialogs => _map(content['dialogs']);
  Map<String, dynamic> get classPage => _map(content['class_guide_page']);

  String mediaSource(String? assetKeyOrPath) {
    if (assetKeyOrPath == null || assetKeyOrPath.trim().isEmpty) return '';
    final raw = (media[assetKeyOrPath]?.effectivePath ?? assetKeyOrPath).trim();
    final uri = Uri.tryParse(raw);
    if (raw.startsWith('assets/') || (uri != null && uri.hasScheme)) return raw;
    return Supabase.instance.client.storage
        .from(_Repository.storageBucket)
        .getPublicUrl(raw)
        .replaceAll(' ', '%20');
  }

  String mediaUrl(String? assetKeyOrPath) => mediaSource(assetKeyOrPath);
}

class _Repository {
  static const int moduleNo = 1;
  static const String storageBucket = 'Learning Materials';

  static Future<Map<String, _LocalizedText>> loadUiTexts() async {
    final rows = await Supabase.instance.client
        .from('learning_material_texts')
        .select('text_key, text_en, text_tl, text_order, usage_context')
        .eq('module_no', moduleNo)
        .eq('usage_context', 'mobile_learning_material_ui')
        .eq('is_active', true)
        .order('text_order', ascending: true);

    final texts = <String, _LocalizedText>{};
    for (final item in rows as List<dynamic>) {
      final row = Map<String, dynamic>.from(item as Map);
      final key = row['text_key']?.toString() ?? '';
      final en = row['text_en']?.toString() ?? '';
      if (key.isEmpty || en.isEmpty) continue;
      texts[key] = _LocalizedText(en: en, tl: row['text_tl']?.toString());
    }
    return texts;
  }

  static Future<_MaterialData> load() async {
    final client = Supabase.instance.client;
    final materialRaw = await client
        .from('learning_materials')
        .select('id, module_id, module_no, title, title_tl, subtitle, subtitle_tl, hero_asset, content')
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
    final pageIds = (pageRows as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final blockRows = pageIds.isEmpty
        ? <dynamic>[]
        : await client
            .from('learning_material_blocks')
            .select('id, page_id, page_no, block_no, block_key, block_type, text_en, text_tl, source_title, source_organization, source_url, metadata')
            .eq('module_no', moduleNo)
            .inFilter('page_id', pageIds)
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
    final textRows = await client
        .from('learning_material_texts')
        .select('text_key, text_en, text_tl, text_order, usage_context')
        .eq('learning_material_id', materialId)
        .eq('module_no', moduleNo)
        .eq('is_active', true)
        .order('text_order', ascending: true);
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
    if (pages.isEmpty) throw StateError('Module 1 has no active learning-material pages.');

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

    final texts = <String, _LocalizedText>{};
    for (final item in textRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(item as Map);
      final key = row['text_key']?.toString() ?? '';
      final en = row['text_en']?.toString() ?? '';
      if (key.isEmpty || en.isEmpty) continue;
      texts[key] = _LocalizedText(en: en, tl: row['text_tl']?.toString());
    }

    final moduleId = material['module_id']?.toString() ?? '';
    if (moduleId.isEmpty) throw StateError('Module 1 learning material has no module_id.');

    return _MaterialData(id: materialId, moduleId: moduleId, moduleNo: _asInt(material['module_no'], moduleNo), titleEn: material['title']?.toString() ?? '', titleTl: material['title_tl']?.toString() ?? '', subtitleEn: material['subtitle']?.toString(), subtitleTl: material['subtitle_tl']?.toString(), heroAsset: material['hero_asset']?.toString(), content: _map(material['content']), pages: pages, media: media, guides: guides, texts: texts);
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
  List<Set<int>> _readSections = <Set<int>>[];

  _MaterialData? _data;
  Map<String, _LocalizedText> _bootstrapTexts = <String, _LocalizedText>{};
  bool _loading = true;
  String? _error;
  int _pageIndex = 0;
  double _scrollProgress = 0.0;
  bool _introShown = false;
  bool _savingCompletion = false;
  bool _postTestAlreadyCompleted = false;

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
      _bootstrapTexts = await _Repository.loadUiTexts();
    } catch (_) {
      _bootstrapTexts = <String, _LocalizedText>{};
    }

    try {
      final data = await _Repository.load();
      final progressionState = await ModuleProgressionService().getState(moduleNo: data.moduleNo);
      final allowed = progressionState.hasValidPreTest;
      final postTestCompleted = progressionState.hasValidPostTest;
      if (!mounted) return;

      if (!allowed) {
        setState(() {
          _data = data;
          _bootstrapTexts = data.texts;
          _readSections = List.generate(data.pages.length, (_) => <int>{});
          _loading = false;
          _postTestAlreadyCompleted = postTestCompleted;
          _error = _isTagalog
              ? 'Naka-lock ang Modyul sa Pag-aaral hanggang matapos at ma-save ang Paunang Pagsusulit.'
              : 'The Learning Module is locked until the Pre-Assessment is completed and saved.';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _showLockedAccessAndClose());
        return;
      }

      setState(() {
        _data = data;
        _bootstrapTexts = data.texts;
        _readSections = List.generate(data.pages.length, (_) => <int>{});
        _postTestAlreadyCompleted = postTestCompleted;
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

  Future<bool> _hasConfirmedPreTest(String moduleId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return false;

    final progressRows = await client
        .from('module_progress')
        .select('pre_test_completed_at, pre_test_attempt_id, updated_at')
        .eq('user_id', user.id)
        .eq('module_id', moduleId)
        .order('updated_at', ascending: false)
        .limit(1);

    if ((progressRows as List).isEmpty) return false;
    final progressRow = Map<String, dynamic>.from(progressRows.first as Map);
    final attemptId = progressRow['pre_test_attempt_id']?.toString();
    if (attemptId == null ||
        attemptId.isEmpty ||
        progressRow['pre_test_completed_at'] == null) {
      return false;
    }

    final attemptRow = await client
        .from('assessment_attempts')
        .select('id, submitted_at, status, score')
        .eq('id', attemptId)
        .eq('user_id', user.id)
        .maybeSingle();

    return attemptRow != null &&
        attemptRow['submitted_at'] != null &&
        attemptRow['status'] == 'submitted' &&
        attemptRow['score'] != null;
  }

  Future<void> _showLockedAccessAndClose() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ContentDialog(
        icon: Icons.lock_outline_rounded,
        color: AppColors.brandRed,
        title: _isTagalog
            ? 'Naka-lock ang Modyul sa Pag-aaral'
            : 'Learning Module Locked',
        body: _isTagalog
            ? 'Tapusin muna ang Paunang Pagsusulit. Magbubukas lang ang Modyul sa Pag-aaral kapag tapos na ang Paunang Pagsusulit.'
            : 'Complete the Pre-Assessment first. The Learning Module will open only after the Pre-Assessment is completed.',
        button: _isTagalog ? 'Naiintindihan' : 'I understand',
        onPressed: () => Navigator.pop(dialogContext),
      ),
    );

    // After the dialog closes, return to the previous screen: learning_materials.dart.
    if (mounted) Navigator.pop(context);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final value = max <= 0 ? 1.0 : (_scrollCtrl.offset / max).clamp(0.0, 1.0).toDouble();
    if ((_scrollProgress - value).abs() > 0.01) setState(() => _scrollProgress = value);
  }

  _MaterialData get data => _data!;

  String _bootstrapCopy(String key, {String fallback = ''}) {
    final item = _bootstrapTexts[key];
    if (item == null) return fallback;
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    final value = isTl && (item.tl ?? '').trim().isNotEmpty ? item.tl!.trim() : item.en.trim();
    return value.isEmpty ? fallback : value;
  }

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
        button: data.copy(context, 'dialog_button_got_it'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  bool get _isTagalog => Localizations.localeOf(context).languageCode == 'tl';

  Future<void> _showPostTestAlreadyCompletedDialog() async {
    if (!mounted) return;
    final title = _isTagalog
        ? 'Naka-lock ang Panghuling Pagsusulit'
        : 'Post-Test Locked';
    final body = _isTagalog
        ? 'Isang beses lang puwedeng sagutan ang Panghuling Pagsusulit. Maaari mong balikan ang modyul para mag-review, pero hindi na puwedeng ulitin ang post-test.'
        : 'You can only take the post-test once. You may review the learning module again, but you can no longer retake the post-test.';
    final okLabel = _isTagalog ? 'OK' : 'OK';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.brandRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.brandRed,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandRed,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          okLabel,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _refreshPostTestCompletionState() async {
    try {
      final state = await ModuleProgressionService().getState(moduleNo: data.moduleNo);
      if (!mounted) return;
      setState(() {
        _postTestAlreadyCompleted = state.hasValidPostTest;
      });
    } catch (e) {
      debugPrint('REFRESH POST-TEST COMPLETION STATE ERROR: $e');
    }
  }


  int _requiredSections(int pageIndex) {
    for (final block in data.page(pageIndex + 1).blocks) {
      if (block.type == 'reading_progress') return block.metaInt('required_sections', 0);
    }
    return 0;
  }

  bool _pageRead(int pageIndex) => pageIndex >= 0 && pageIndex < _readSections.length && _readSections[pageIndex].length >= _requiredSections(pageIndex);

  Future<bool> _markLearningMaterialCompleted() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showInfo(
        data.copy(context, 'auth_required_title', fallback: 'Login Required'),
        data.copy(
          context,
          'auth_required_body',
          fallback: 'Please log in again before completing this module.',
        ),
        Icons.lock_outline_rounded,
        AppColors.brandRed,
      );
      return false;
    }

    final client = Supabase.instance.client;
    final hasPreTest = await _hasConfirmedPreTest(data.moduleId);
    if (!hasPreTest) {
      _showInfo(
        _isTagalog
            ? 'Naka-lock ang Modyul sa Pag-aaral'
            : 'Learning Module Locked',
        _isTagalog
            ? 'Tapusin muna ang Paunang Pagsusulit. Hindi maaaring i-save ang completion ng modyul hangga’t walang naka-save na pre-assessment score.'
            : 'Complete the Pre-Assessment first. The module cannot be marked completed without a saved pre-assessment score.',
        Icons.lock_outline_rounded,
        AppColors.brandRed,
      );
      return false;
    }

    final completedAt = DateTime.now().toUtc().toIso8601String();

    final progressRows = await client
        .from('module_progress')
        .select('id, updated_at')
        .eq('user_id', user.id)
        .eq('module_id', data.moduleId)
        .order('updated_at', ascending: false)
        .limit(1);

    final progressRow = (progressRows as List).isEmpty
        ? null
        : Map<String, dynamic>.from(progressRows.first as Map);

    final progressPayload = {
      'learning_material_read_status': true,
      'learning_material_completed_at': completedAt,
      'updated_at': completedAt,
    };

    if (progressRow == null) {
      await client.from('module_progress').insert({
        'user_id': user.id,
        'module_id': data.moduleId,
        ...progressPayload,
      });
    } else {
      await client
          .from('module_progress')
          .update(progressPayload)
          .eq('id', progressRow['id']);
    }

    return true;
  }

  Future<void> _completeLearningMaterialAndOpenPostAssessment() async {
    if (_savingCompletion) return;

    setState(() => _savingCompletion = true);

    try {
      final progression = ModuleProgressionService();
      final state = await progression.getState(moduleNo: data.moduleNo);
      if (!mounted) return;

      if (state.hasValidPostTest) {
        setState(() => _postTestAlreadyCompleted = true);
        Navigator.pop(context);
        await _showPostTestAlreadyCompletedDialog();
        return;
      }

      await progression.markLearningMaterialCompleted(moduleNo: data.moduleNo);
      await progression.ensureCanStartPostTest(moduleNo: data.moduleNo);
      if (!mounted) return;

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostAssessmentIntroPage()),
      ).then((_) {
        if (mounted) _refreshPostTestCompletionState();
      });
    } on ProgressionAccessDenied catch (e) {
      debugPrint('POST-TEST ACCESS DENIED FROM LEARNING MODULE: ${e.message}');
      if (!mounted) return;
      Navigator.pop(context);
      if (e.message == ModuleProgressionService.postTestAlreadyTakenMessage) {
        await _showPostTestAlreadyCompletedDialog();
        return;
      }
      _showInfo(
        _isTagalog ? 'Naka-lock ang Panghuling Pagsusulit' : 'Post-Test Locked',
        _isTagalog
            ? 'Hindi pa puwedeng buksan ang Panghuling Pagsusulit. Siguraduhing kumpleto at naka-save ang Paunang Pagsusulit at Modyul sa Pag-aaral.'
            : e.message,
        Icons.lock_outline_rounded,
        AppColors.brandRed,
      );
    } catch (e) {
      debugPrint('SAVE LEARNING MATERIAL COMPLETION ERROR: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _showInfo(
        data.copy(context, 'completion_save_failed_title', fallback: _isTagalog ? 'Hindi na-save ang completion' : 'Completion not saved'),
        data.copy(
          context,
          'completion_save_failed_body',
          fallback: _isTagalog
              ? 'Hindi na-save ang completion ng modyul. Pakisubukan ulit.'
              : 'The learning module completion could not be saved. Please try again.',
        ),
        Icons.error_outline_rounded,
        AppColors.brandRed,
      );
    } finally {
      if (mounted) {
        setState(() => _savingCompletion = false);
      }
    }
  }

  void _goNext() {
    if (_pageIndex == data.pages.length - 1 && _postTestAlreadyCompleted) {
      _showPostTestAlreadyCompletedDialog();
      return;
    }
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
            _completeLearningMaterialAndOpenPostAssessment();
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
    if (_loading) return const _ScreenShell(child: Center(child: _LoadingContentCard()));
    if (_error != null || _data == null) {
      return _ScreenShell(
        child: Center(
          child: _ErrorCard(
            title: _bootstrapCopy('error_load_title', fallback: 'Learning materials could not load'),
            message: _error ?? _bootstrapCopy('error_no_data', fallback: 'No learning material data.'),
            closeLabel: _bootstrapCopy('error_close', fallback: 'Close'),
            retryLabel: _bootstrapCopy('error_retry', fallback: 'Retry'),
            onRetry: _load,
            onClose: () => Navigator.pop(context),
          ),
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
                    pageLabel: data.copy(context, 'page_label'),
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
                _BottomNav(
                  isLast: _pageIndex == data.pages.length - 1,
                  enabled: _pageRead(_pageIndex),
                  postTestLocked: _pageIndex == data.pages.length - 1 && _postTestAlreadyCompleted,
                  backLabel: data.copy(context, 'nav_back'),
                  nextLabel: data.copy(context, 'nav_next'),
                  startPostTestLabel: data.copy(context, 'nav_start_post_test'),
                  onBack: _goBack,
                  onNext: _goNext,
                ),
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
        return _MediaCard(material: data, block: block, imageUrl: data.mediaUrl(block.metaString('asset_key')), title: block.text(context, data), subtitle: block.metaText(context, data, 'subtitle'), use3DPreview: page.pageNo == 1);
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
        return _ReadBadge(material: data, read: _readSections[page.pageNo - 1].length, total: block.metaInt('required_sections', 0));
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

class _LoadingContentCard extends StatelessWidget {
  const _LoadingContentCard();

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    return Container(
      margin: const EdgeInsets.all(22),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.brandRed),
          const SizedBox(height: 14),
          Text(
            isTl
                ? 'Nilo-load ang mga materyales sa pag-aaral...'
                : 'Loading learning materials...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final String closeLabel;
  final String retryLabel;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.closeLabel,
    required this.retryLabel,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.brandRed, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackButtons = constraints.maxWidth < 260;
              final closeButton = OutlinedButton(
                onPressed: onClose,
                child: Text(closeLabel, textAlign: TextAlign.center, softWrap: true),
              );
              final retryButton = ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRed),
                onPressed: onRetry,
                child: Text(
                  retryLabel,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(color: Colors.white),
                ),
              );

              if (stackButtons) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    closeButton,
                    const SizedBox(height: 10),
                    retryButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: closeButton),
                  const SizedBox(width: 10),
                  Expanded(child: retryButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
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
  final String pageLabel;
  final VoidCallback onClose;

  const _TopHeader({
    required this.sectionTitle,
    required this.moduleLabel,
    required this.moduleTitle,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.pageLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          sectionTitle,
          softWrap: true,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final moduleBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.brandRedLight, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fire_extinguisher_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      moduleLabel,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );

            final moduleTitleText = Text(
              moduleTitle,
              softWrap: true,
              style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12.5, height: 1.28, fontWeight: FontWeight.w700),
            );

            if (constraints.maxWidth < 330) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  moduleBadge,
                  const SizedBox(height: 8),
                  moduleTitleText,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.48), child: moduleBadge),
                const SizedBox(width: 10),
                Expanded(child: moduleTitleText),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.22),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '$pageLabel $currentPage/$totalPages',
                softWrap: true,
                style: TextStyle(color: Colors.white.withOpacity(0.76), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == currentPage - 1 ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: index == currentPage - 1 ? Colors.white : Colors.white.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool isLast;
  final bool enabled;
  final bool postTestLocked;
  final String backLabel;
  final String nextLabel;
  final String startPostTestLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNav({
    required this.isLast,
    required this.enabled,
    required this.postTestLocked,
    required this.backLabel,
    required this.nextLabel,
    required this.startPostTestLabel,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final primaryLabel = isLast ? startPostTestLabel : nextLabel;
    final primaryLooksLocked = postTestLocked || !enabled;

    Widget backButton() => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.brandRed),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onPressed: onBack,
            child: Text(
              backLabel,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.bold),
            ),
          ),
        );

    Widget primaryButton() => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryLooksLocked ? const Color(0xFFE5E7EB) : AppColors.brandRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: onNext,
            child: Text(
              primaryLabel,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(color: primaryLooksLocked ? const Color(0xFF9CA3AF) : Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                backButton(),
                const SizedBox(height: 10),
                primaryButton(),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: backButton()),
                const SizedBox(width: 12),
                Expanded(flex: 7, child: primaryButton()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContentDialog extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;

  const _ContentDialog({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onPressed: onPressed,
                child: Text(
                  button,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  final _MaterialData material;
  final _BlockData block;
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool use3DPreview;
  const _MediaCard({required this.material, required this.block, required this.imageUrl, required this.title, required this.subtitle, this.use3DPreview = false});

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
                  material.copy(context, 'tap_to_view_3d'),
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
          if (use3DPreview)
            _PageOne3DPreview(material: material, block: block, imageUrl: imageUrl)
          else
            _StaticPreviewImage(imageUrl: imageUrl, unavailableLabel: material.copy(context, 'image_unavailable_3d')),
        ],
      ),
    );
  }
}

class _StaticPreviewImage extends StatelessWidget {
  final String imageUrl;
  final String unavailableLabel;
  const _StaticPreviewImage({required this.imageUrl, required this.unavailableLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 176,
        height: 188,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              top: 26,
              left: 2,
              child: _PreviewBackPlate(
                width: 128,
                height: 138,
                opacity: 0.20,
                rotationTurns: -0.055,
              ),
            ),
            const Positioned(
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
                      unavailableLabel,
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
    );
  }
}

class _PageOne3DPreview extends StatelessWidget {
  final _MaterialData material;
  final _BlockData block;
  final String imageUrl;
  const _PageOne3DPreview({required this.material, required this.block, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final modelSrc = material.mediaSource(block.metaString('model_asset_key')).trim();
    final viewerTitle = block.metaText(context, material, 'viewer_title').trim();
    final viewerSubtitle = block.metaText(context, material, 'viewer_subtitle').trim();
    final modelBadge = block.metaText(context, material, 'model_badge').trim();
    final modelAlt = block.metaText(context, material, 'model_alt').trim();
    final interactionHint = block.metaText(context, material, 'interaction_hint').trim();
    final passHeading = block.metaText(context, material, 'pass_heading').trim();
    final steps = block.mapList('pass_steps');
    final cameraOrbit = block.metaString('camera_orbit') ?? '0deg 72deg 1.85m';
    final fieldOfView = block.metaString('field_of_view') ?? '25deg';

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth * 1.75)
            .clamp(560.0, 720.0)
            .toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (viewerTitle.isNotEmpty) ...[
              Text(
                viewerTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (viewerSubtitle.isNotEmpty) ...[
              Text(
                viewerSubtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                height: previewHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.brandRed.withOpacity(0.10),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.50),
                              AppColors.brandRedSoft.withOpacity(0.55),
                              AppColors.brandRed.withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (modelBadge.isNotEmpty)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.84),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.brandRed.withOpacity(0.14)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.view_in_ar_rounded, size: 16, color: AppColors.brandRed),
                              const SizedBox(width: 7),
                              Text(
                                modelBadge,
                                style: const TextStyle(color: AppColors.brandRed, fontSize: 11.5, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned.fill(
                      top: 24,
                      bottom: 8,
                      child: ModelViewer(
                        src: modelSrc.isNotEmpty ? modelSrc : imageUrl,
                        alt: modelAlt,
                        autoRotate: true,
                        cameraControls: true,
                        disableZoom: false,
                        backgroundColor: Colors.transparent,
                        cameraOrbit: cameraOrbit,
                        fieldOfView: fieldOfView,
                        shadowIntensity: 0.55,
                        exposure: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (interactionHint.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.brandRed.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.brandRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        interactionHint,
                        style: const TextStyle(color: Color(0xFF7A1014), fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (passHeading.isNotEmpty || steps.isNotEmpty) ...[
              const SizedBox(height: 20),
              if (passHeading.isNotEmpty)
                Row(
                  children: [
                    Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.brandRed, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        passHeading,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _PassMethodCard(
                  letter: (steps[i]['letter'] ?? '').toString(),
                  title: material.textFrom(context, steps[i], 'title'),
                  desc: material.textFrom(context, steps[i], 'desc'),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _ModelLabel extends StatelessWidget {
  final String label;
  const _ModelLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: AppColors.brandRedDark,
          height: 1.2,
        ),
      ),
    );
  }
}

class _PassMethodCard extends StatelessWidget {
  final String letter;
  final String title;
  final String desc;
  const _PassMethodCard({required this.letter, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandRed, AppColors.brandRedDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFF4B5563),
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

class _PreviewDepthLine extends StatelessWidget {
  final double width;
  const _PreviewDepthLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.46),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FallbackExtinguisherModel extends StatelessWidget {
  const _FallbackExtinguisherModel();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: Container(
              width: 58,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.brandRedDark,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandRedDeep.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 34,
            child: Container(
              width: 34,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8A8A8A), width: 3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 23,
            child: Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.brandRed,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 48,
            child: Container(
              width: 78,
              height: 170,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE64A4F), AppColors.brandRed, AppColors.brandRedDark],
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandRedDark.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 76,
            right: 38,
            child: Container(
              width: 16,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 104,
            child: Container(
              width: 54,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandRedDark.withOpacity(0.12)),
              ),
              child: const Center(
                child: Icon(Icons.fire_extinguisher_rounded, color: AppColors.brandRed, size: 25),
              ),
            ),
          ),
          Positioned(
            top: 214,
            child: Container(
              width: 54,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.brandRedDark,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 12,
            child: Container(
              width: 72,
              height: 38,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF303030), width: 4),
                  right: BorderSide(color: Color(0xFF303030), width: 4),
                ),
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
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isRead ? AppColors.success.withOpacity(0.35) : _hexColor(block.metaString('color_hex'), AppColors.brandRed).withOpacity(0.12))), child: Row(children: [Icon(isRead ? Icons.check_circle_rounded : _roleIcon(block.metaString('icon_role')), color: isRead ? AppColors.success : _hexColor(block.metaString('color_hex'), AppColors.brandRed)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(guide == null ? block.metaText(context, material, 'class_label') : material.localize(context, guide!.nameEn, guide!.nameTl), style: TextStyle(fontWeight: FontWeight.w900, color: isRead ? AppColors.success : const Color(0xFF111827))), const SizedBox(height: 3), Text(block.text(context, material), style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4))])), Text(isRead ? material.copy(context, 'completed_check_label') : material.copy(context, 'tap_label'), textAlign: TextAlign.center, softWrap: true, style: TextStyle(color: isRead ? AppColors.success : AppColors.brandRed, fontWeight: FontWeight.w900))])));
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
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.isRead ? AppColors.success.withOpacity(0.35) : AppColors.brandRed.withOpacity(0.12))), child: Column(children: [InkWell(onTap: () { setState(() => expanded = !expanded); if (expanded) widget.onOpen(); }, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [CircleAvatar(backgroundColor: widget.isRead ? AppColors.success : AppColors.brandRed, child: Text(widget.isRead ? widget.material.copy(context, 'completed_check_label') : (widget.block.metaString('letter') ?? ''), textAlign: TextAlign.center, softWrap: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.block.text(context, widget.material), style: TextStyle(fontWeight: FontWeight.w900, color: widget.isRead ? AppColors.success : const Color(0xFF111827))), Text(widget.block.metaText(context, widget.material, 'desc'), style: const TextStyle(color: Color(0xFF6B7280), height: 1.35))])), Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.brandRed)]))), if (expanded) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Divider(), const SizedBox(height: 12), _VideoCard(title: widget.block.metaText(context, widget.material, 'video_title'), url: widget.material.mediaUrl(widget.block.metaString('asset_key')), failureTitle: widget.material.copy(context, 'video_could_not_load'))]))]));
}

class _VideoCard extends StatefulWidget {
  final String title;
  final String url;
  final String failureTitle;
  const _VideoCard({required this.title, required this.url, required this.failureTitle});
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
    if (failed) return _VideoPlaceholder(title: widget.failureTitle, subtitle: widget.url);
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
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ondemand_video_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            softWrap: true,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData icon;
  final Color color;

  const _Callout({required this.title, required this.lines, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.15))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, softWrap: true, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                const SizedBox(height: 8),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 8, right: 8),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            softWrap: true,
                            style: const TextStyle(height: 1.45, color: Color(0xFF374151)),
                          ),
                        ),
                      ],
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

class _SourceCard extends StatelessWidget {
  final _SourceData source;

  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.brandRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.label, softWrap: true, style: const TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(source.title, softWrap: true, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                if (source.organization.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(source.organization, softWrap: true, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 2),
                Text(source.url, softWrap: true, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.brandRed.withOpacity(0.10))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.brandRed),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  final _MaterialData material;
  final int read;
  final int total;
  const _ReadBadge({required this.material, required this.read, required this.total});
  @override
  Widget build(BuildContext context) {
    final done = read >= total;
    final color = done ? AppColors.success : AppColors.brandRed;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))), child: Row(children: [Icon(done ? Icons.check_circle_rounded : Icons.menu_book_rounded, color: color), const SizedBox(width: 10), Expanded(child: Text(done ? material.copy(context, 'read_badge_complete') : material.copyFormat(context, 'read_badge_progress', {'read': read.toString(), 'total': total.toString()}), style: TextStyle(color: color, fontWeight: FontWeight.w800)))]));
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
                    currentPage: _asInt(header['current_page'], 2),
                    totalPages: _asInt(header['total_pages'], material.pages.length),
                    progress: 1,
                    pageLabel: material.copy(context, 'page_label'),
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final spacing = 16.0;
                              final twoColumns = constraints.maxWidth >= 300;
                              final cardWidth = twoColumns ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final guide in guides)
                                    SizedBox(
                                      width: cardWidth,
                                      child: _GuideCard(material: material, guide: guide),
                                    ),
                                ],
                              );
                            },
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
                            child: Text(material.copy(context, 'class_back_button')),
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
            SizedBox(
              height: 112,
              child: Image.network(
                image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.fire_extinguisher_rounded,
                  color: AppColors.brandRed,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              material.copy(context, 'tap_to_explore'),
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
              icon: Icons.fire_extinguisher_rounded,
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
