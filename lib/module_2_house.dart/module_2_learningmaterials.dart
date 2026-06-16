import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'post_assess_instruction.dart';

// =============================================================================
// MODULE 2 HOUSE FIRE COLORS
// =============================================================================
const Color kHouseOrange = Color(0xFFF97316);
const Color kHouseAmber = Color(0xFFF59E0B);
const Color kHouseOrangeSoft = Color(0xFFFFF7ED);
const Color kDarkText = Color(0xFF1F2937);
const Color kSoftBg = Color(0xFFF8FAFC);

class AppColors {
  // Module 2 House Fire palette
  static const Color brandRed = kHouseOrange;
  static const Color brandRedDark = Color(0xFFEA580C);
  static const Color brandRedDeep = kHouseAmber;
  static const Color brandRedLight = kHouseAmber;
  static const Color brandRedSoft = kHouseOrangeSoft;

  // Background Colors
  static const Color background = kSoftBg;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = kHouseOrangeSoft;

  // Text Colors
  static const Color textPrimary = kDarkText;
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnRed = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFF1D8C5);
  static const Color divider = Color(0xFFFDEAD7);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = kHouseAmber;
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);

  // Buttons
  static const Color primaryButton = kHouseOrange;
  static const Color primaryButtonPressed = Color(0xFFEA580C);
  static const Color secondaryButton = kHouseOrangeSoft;

  // Shadows
  static const Color shadow = Color(0x1A000000);
}

class _LmTextRow {
  final String en;
  final String? tl;

  const _LmTextRow({required this.en, this.tl});

  String value(bool isTl) {
    if (isTl && tl != null && tl!.trim().isNotEmpty) return tl!;
    return en;
  }
}

class _LmSourceRow extends _LmTextRow {
  final String? sourceTitle;
  final String? sourceOrganization;
  final String? sourceUrl;

  const _LmSourceRow({
    required super.en,
    super.tl,
    this.sourceTitle,
    this.sourceOrganization,
    this.sourceUrl,
  });
}

class _LmPageRow {
  final int pageNo;
  final String titleEn;
  final String titleTl;

  const _LmPageRow({
    required this.pageNo,
    required this.titleEn,
    required this.titleTl,
  });

  String title(bool isTl) => isTl && titleTl.trim().isNotEmpty ? titleTl : titleEn;
}

class _LmMediaRow {
  final String assetPath;
  final String? publicUrl;

  const _LmMediaRow({required this.assetPath, this.publicUrl});

  String get displayPath {
    if (publicUrl != null && publicUrl!.trim().isNotEmpty) return publicUrl!.trim();
    return assetPath.trim();
  }
}

typedef _LmTextResolver = String Function(
  String key, {
  Map<String, String>? args,
});

class _LmCopyScope extends InheritedWidget {
  final _LmTextResolver text;

  const _LmCopyScope({
    required this.text,
    required super.child,
  });

  static _LmCopyScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LmCopyScope>();
  }

  @override
  bool updateShouldNotify(_LmCopyScope oldWidget) => text != oldWidget.text;
}

String _lm(BuildContext context, String key, {Map<String, String>? args}) {
  final scope = _LmCopyScope.maybeOf(context);
  if (scope == null) return key;
  return scope.text(key, args: args);
}

bool _isNetworkPath(String path) {
  final lower = path.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

const String _learningMaterialsBucket = 'Learning Materials';

String _resolveLearningMaterialStoragePath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty || _isNetworkPath(trimmed)) return trimmed;
  if (trimmed.startsWith('assets/')) return trimmed;
  return Supabase.instance.client.storage
      .from(_learningMaterialsBucket)
      .getPublicUrl(trimmed);
}

const List<String> _requiredLearningMaterialKeys = <String>[
  'header_section_title',
  'module_label',
  'header_page_label',
  'loading_learning_materials',
  'error_learning_materials_title',
  'error_retry_button',
  'dialog_close_tooltip',
  'dialog_keep_reading_title',
  'dialog_keep_reading_body',
  'dialog_keep_reading_button',
  'dialog_intro_title',
  'dialog_intro_body',
  'dialog_intro_button',
  'dialog_page1_complete_title',
  'dialog_page1_complete_body',
  'dialog_page2_complete_title',
  'dialog_page2_complete_body',
  'dialog_continue_button',
  'dialog_final_title',
  'dialog_final_body',
  'dialog_final_button',
  'dialog_info_ok',
  'popup_door_rule_title',
  'popup_door_rule_body',
  'popup_stop_drop_roll_title',
  'popup_stop_drop_roll_body',
  'nav_start_post_test',
  'nav_next',
  'nav_back',
  'progress_all_sections_read',
  'progress_sections_read',
  'progress_scroll_tap_sections',
  'video_preview_unavailable',
  'video_preview_holder',
  'house_fire_3d_chip',
  'house_fire_3d_missing_asset',
  'house_fire_3d_viewer_badge',
  'house_fire_3d_rotate_instruction',
  'house_fire_3d_alt_text',
  'widget_video_3d_preview_title',
  'page_1_tag',
  'page_1_subtitle',
  'page_1_intro_title',
  'page_1_intro_text',
  'page_1_preview_title',
  'page_1_preview_subtitle',
  'source_p1_shared',
  'p1_s1_title',
  'p1_s1_subtitle',
  'p1_s1_headline',
  'p1_s1_body',
  'p1_s1_callout_title',
  'p1_s1_callout_line_1',
  'p1_s2_title',
  'p1_s2_subtitle',
  'p1_s2_bullet_1',
  'p1_s2_bullet_2',
  'p1_s2_bullet_3',
  'p1_s2_tip_title',
  'p1_s2_tip_message',
  'p1_s3_title',
  'p1_s3_subtitle',
  'p1_s3_chip_1',
  'p1_s3_chip_2',
  'p1_s3_chip_3',
  'p1_s3_chip_4',
  'p1_action_title',
  'p1_action_body',
  'p1_action_button',
  'page_2_tag',
  'page_2_subtitle',
  'page_2_section_title',
  'page_2_section_subtitle',
  'source_escape_steps',
  'p2_step1_number',
  'p2_step1_title',
  'p2_step1_subtitle',
  'p2_step1_preview_title',
  'p2_step1_preview_description',
  'p2_step2_number',
  'p2_step2_title',
  'p2_step2_subtitle',
  'p2_step2_preview_title',
  'p2_step2_preview_description',
  'p2_step3_number',
  'p2_step3_title',
  'p2_step3_subtitle',
  'p2_step3_preview_title',
  'p2_step3_preview_description',
  'p2_step4_number',
  'p2_step4_title',
  'p2_step4_subtitle',
  'p2_step4_preview_title',
  'p2_step4_preview_description',
  'source_video_holder',
  'p2_reminders_title',
  'p2_reminders_subtitle',
  'p2_reminder_bullet_1',
  'p2_reminder_bullet_2',
  'p2_reminder_bullet_3',
  'p2_reminder_bullet_4',
  'p2_reminder_bullet_5',
  'p2_reminder_action_label',
  'page_3_tag',
  'page_3_subtitle',
  'source_p3_shared',
  'p3_s1_title',
  'p3_s1_subtitle',
  'p3_s1_body',
  'p3_s1_callout_title',
  'p3_s1_callout_line_1',
  'p3_s2_title',
  'p3_s2_subtitle',
  'p3_s2_bullet_1',
  'p3_s2_bullet_2',
  'p3_s2_bullet_3',
  'p3_s2_bullet_4',
  'p3_s3_title',
  'p3_s3_subtitle',
  'p3_s3_bullet_1',
  'p3_s3_bullet_2',
  'p3_s3_bullet_3',
  'p3_s3_tip_title',
  'p3_s3_tip_message',
  'p3_s4_title',
  'p3_s4_subtitle',
  'source_smoke_alarms',
  'p3_s4_bullet_1',
  'p3_s4_bullet_2',
  'p3_s4_bullet_3',
  'p3_s4_bullet_4',
  'p3_quick_check_title',
  'p3_quick_check_message',
];

const List<String> _requiredSourceKeys = <String>[
  'source_p1_shared',
  'source_escape_steps',
  'source_p3_shared',
  'source_smoke_alarms',
];

const List<String> _requiredMediaAssetKeys = <String>[
  'module2_house_fire_model_glb',
  'module2_escape_step_1_video',
  'module2_escape_step_2_video',
  'module2_escape_step_3_video',
  'module2_escape_step_4_video',
];

// =============================================================================
// MAIN PAGE
// =============================================================================
class LearningMaterialHousePage extends StatefulWidget {
  const LearningMaterialHousePage({super.key});

  @override
  State<LearningMaterialHousePage> createState() =>
      _LearningMaterialHousePageState();
}

class _LearningMaterialHousePageState extends State<LearningMaterialHousePage> {
  static const accent = AppColors.brandRed;
  static const accent2 = AppColors.brandRedDark;

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  final Map<String, _LmTextRow> _copy = <String, _LmTextRow>{};
  final Map<String, _LmSourceRow> _sources = <String, _LmSourceRow>{};
  final Map<int, _LmPageRow> _pages = <int, _LmPageRow>{};
  final Map<String, _LmMediaRow> _media = <String, _LmMediaRow>{};

  String _materialTitleEn = '';
  String _materialTitleTl = '';
  String? _heroAssetPath;
  bool _isLoading = true;
  String? _loadError;

  int _pageIndex = 0;
  double _progress = 0.0;
  bool _canNext = false;
  bool _isSwitchingPage = false;
  bool _lastPageCompleted = false;

  // Page 0: 3 expandable sections
  // Page 1: 4 escape steps + 1 important reminder section
  // Page 2: 4 after-escape / preparedness sections
  final List<Set<int>> _readSections = [<int>{}, <int>{}, <int>{}];

  bool _introShown = false;
  bool _unreadPromptVisible = false;

  bool get _isTl =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('tl');

  String _localized(String en, String? tl) {
    if (_isTl && tl != null && tl.trim().isNotEmpty) return tl;
    return en;
  }

  String _txt(String key, {Map<String, String>? args}) {
    var value = _copy[key]?.value(_isTl) ?? key;
    if (args != null && args.isNotEmpty) {
      for (final entry in args.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  String _pageTitle(int pageNo) {
    final page = _pages[pageNo];
    if (page == null) return 'page_$pageNo';
    return page.title(_isTl);
  }

  String _sourceTitle(String key) => _sources[key]?.sourceTitle ?? key;

  String _sourceUrl(String key) => _sources[key]?.sourceUrl ?? '';

  String? _assetPath(String key) {
    final media = _media[key];
    if (media == null || media.displayPath.isEmpty) return null;
    return media.displayPath;
  }

  String? get _previewAssetPath {
    final mediaPath = _assetPath('module2_house_fire_preview_image');
    if (mediaPath != null) return mediaPath;
    if (_heroAssetPath != null && _heroAssetPath!.trim().isNotEmpty) {
      return _heroAssetPath!.trim();
    }
    return null;
  }

  String get _moduleTitle => _localized(_materialTitleEn, _materialTitleTl);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadLearningMaterials();
  }

  Future<void> _loadLearningMaterials() async {
    try {
      final client = Supabase.instance.client;

      final material = await client
          .from('learning_materials')
          .select('id,module_no,title,title_tl,subtitle,subtitle_tl,hero_asset')
          .eq('module_no', 2)
          .eq('is_active', true)
          .maybeSingle();

      if (material == null) {
        throw StateError('Missing active learning_materials row for module_no = 2.');
      }

      final materialId = material['id'] as String;
      final pages = await client
          .from('learning_material_pages')
          .select('id,module_no,page_no,page_key,title_en,title_tl')
          .eq('learning_material_id', materialId)
          .eq('module_no', 2)
          .eq('is_active', true)
          .order('page_no');

      final blocks = await client
          .from('learning_material_blocks')
          .select('id,page_id,module_no,page_no,block_no,block_key,block_type,text_en,text_tl,metadata,source_title,source_organization,source_url')
          .eq('module_no', 2)
          .eq('is_active', true)
          .order('page_no')
          .order('block_no');

      final texts = await client
          .from('learning_material_texts')
          .select('text_order,text_key,text_en,text_tl')
          .eq('learning_material_id', materialId)
          .eq('module_no', 2)
          .eq('usage_context', 'mobile_learning_material')
          .eq('is_active', true)
          .order('text_order');

      final mediaRows = await client
          .from('learning_material_media_assets')
          .select('asset_key,asset_path,public_url,asset_type,display_order')
          .eq('learning_material_id', materialId)
          .eq('module_no', 2)
          .eq('is_active', true)
          .order('display_order');

      final loadedCopy = <String, _LmTextRow>{};
      final loadedSources = <String, _LmSourceRow>{};
      final loadedPages = <int, _LmPageRow>{};
      final loadedMedia = <String, _LmMediaRow>{};

      for (final row in (texts as List<dynamic>)) {
        final map = Map<String, dynamic>.from(row as Map);
        final key = (map['text_key'] as String?)?.trim();
        if (key == null || key.isEmpty) continue;
        loadedCopy[key] = _LmTextRow(
          en: (map['text_en'] as String?) ?? '',
          tl: map['text_tl'] as String?,
        );
      }

      for (final row in (pages as List<dynamic>)) {
        final map = Map<String, dynamic>.from(row as Map);
        final pageNo = map['page_no'] as int?;
        if (pageNo == null) continue;
        loadedPages[pageNo] = _LmPageRow(
          pageNo: pageNo,
          titleEn: (map['title_en'] as String?) ?? '',
          titleTl: (map['title_tl'] as String?) ?? '',
        );
      }

      for (final row in (blocks as List<dynamic>)) {
        final map = Map<String, dynamic>.from(row as Map);
        final key = (map['block_key'] as String?)?.trim();
        if (key == null || key.isEmpty) continue;
        final source = _LmSourceRow(
          en: (map['text_en'] as String?) ?? '',
          tl: map['text_tl'] as String?,
          sourceTitle: map['source_title'] as String?,
          sourceOrganization: map['source_organization'] as String?,
          sourceUrl: map['source_url'] as String?,
        );
        loadedCopy[key] = source;
        if ((source.sourceTitle ?? '').trim().isNotEmpty ||
            (source.sourceUrl ?? '').trim().isNotEmpty) {
          loadedSources[key] = source;
        }
      }

      for (final row in (mediaRows as List<dynamic>)) {
        final map = Map<String, dynamic>.from(row as Map);
        final key = (map['asset_key'] as String?)?.trim();
        final path = (map['asset_path'] as String?)?.trim();
        final publicUrl = (map['public_url'] as String?)?.trim();
        if (key == null || key.isEmpty || path == null || path.isEmpty) continue;
        loadedMedia[key] = _LmMediaRow(
          assetPath: publicUrl != null && publicUrl.isNotEmpty
              ? path
              : _resolveLearningMaterialStoragePath(path),
          publicUrl: publicUrl,
        );
      }

      _assertRequiredContent(loadedCopy, loadedSources, loadedPages, loadedMedia);

      if (!mounted) return;
      setState(() {
        _materialTitleEn = (material['title'] as String?) ?? '';
        _materialTitleTl = (material['title_tl'] as String?) ?? '';
        final heroAsset = (material['hero_asset'] as String?)?.trim();
        _heroAssetPath = heroAsset == null || heroAsset.isEmpty
            ? null
            : _resolveLearningMaterialStoragePath(heroAsset);
        _copy
          ..clear()
          ..addAll(loadedCopy);
        _sources
          ..clear()
          ..addAll(loadedSources);
        _pages
          ..clear()
          ..addAll(loadedPages);
        _media
          ..clear()
          ..addAll(loadedMedia);
        _isLoading = false;
        _loadError = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onScroll();
        if (!_introShown) {
          _introShown = true;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _showIntroPopup();
          });
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  void _assertRequiredContent(
    Map<String, _LmTextRow> copy,
    Map<String, _LmSourceRow> sources,
    Map<int, _LmPageRow> pages,
    Map<String, _LmMediaRow> media,
  ) {
    final missing = <String>[];
    for (final key in _requiredLearningMaterialKeys) {
      final value = copy[key];
      if (value == null || value.en.trim().isEmpty) missing.add(key);
    }
    for (final pageNo in <int>[1, 2, 3]) {
      final page = pages[pageNo];
      if (page == null || page.titleEn.trim().isEmpty || page.titleTl.trim().isEmpty) {
        missing.add('learning_material_pages.page_no_$pageNo');
      }
    }
    for (final key in _requiredSourceKeys) {
      final source = sources[key];
      if (source == null ||
          (source.sourceTitle ?? '').trim().isEmpty ||
          (source.sourceUrl ?? '').trim().isEmpty) {
        missing.add('$key.source');
      }
    }
    for (final key in _requiredMediaAssetKeys) {
      final asset = media[key];
      if (asset == null || asset.displayPath.trim().isEmpty) {
        missing.add('learning_material_media_assets.$key');
      }
    }
    if (missing.isNotEmpty) {
      throw StateError('Missing Module 2 database content: ${missing.join(', ')}');
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_isSwitchingPage) return;

    final max = _scrollCtrl.position.maxScrollExtent;
    final off = _scrollCtrl.offset;

    if (max <= 0) {
      if (_progress != 1.0 || !_canNext) {
        setState(() {
          _progress = 1.0;
          _canNext = _pageIndex != 2;
        });
      }
      return;
    }

    final p = (off / max).clamp(0.0, 1.0).toDouble();
    final nearBottom = off >= (max - 8);

    if (_progress != p || _canNext != nearBottom) {
      setState(() {
        _progress = p;
        _canNext = nearBottom;
      });
    }

    if (_pageIndex == 2 && nearBottom) {
      _lastPageCompleted = true;
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _resetForNewPage() {
    setState(() {
      _isSwitchingPage = true;
      _progress = 0.0;
      _canNext = false;
      _lastPageCompleted = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
      setState(() => _isSwitchingPage = false);
      _onScroll();
    });
  }

  void _goBack() {
    if (_pageIndex == 0) {
      Navigator.pop(context);
      return;
    }
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  int _requiredSectionCountForPage(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 3;
      case 1:
        return 5;
      case 2:
        return 4;
      default:
        return 0;
    }
  }

  bool _hasReadAllRequiredSections(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _readSections.length) return false;
    return _readSections[pageIndex].length >=
        _requiredSectionCountForPage(pageIndex);
  }

  void _markSectionRead(int pageIndex, int sectionIndex) {
    if (pageIndex < 0 || pageIndex >= _readSections.length) return;
    if (_readSections[pageIndex].contains(sectionIndex)) return;
    setState(() {
      _readSections[pageIndex].add(sectionIndex);
    });
  }

  void _goNext() {
    if (!_hasReadAllRequiredSections(_pageIndex)) {
      _showUnreadSectionsPopup();
      return;
    }

    if (_pageIndex < 2) {
      _showPageCompletePopup(_pageIndex, () {
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    } else {
      setState(() => _lastPageCompleted = true);
      _showFinalCompletePopup();
    }
  }

  // ---------------------------------------------------------------------------
  // POPUPS
  // ---------------------------------------------------------------------------

  void _showUnreadSectionsPopup() {
    if (_unreadPromptVisible) return;

    _unreadPromptVisible = true;

    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.brandRed,
        title: _txt('dialog_keep_reading_title'),
        body: _txt('dialog_keep_reading_body'),
        buttonLabel: _txt('dialog_keep_reading_button'),
        onPressed: () => Navigator.pop(context),
      ),
    ).then((_) {
      _unreadPromptVisible = false;
    });
  }

  void _showIntroPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.home_work_rounded,
        iconColor: accent,
        title: _txt('dialog_intro_title'),
        body: _txt('dialog_intro_body'),
        buttonLabel: _txt('dialog_intro_button'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showPageCompletePopup(int pageIndex, VoidCallback onContinue) {
    final title = pageIndex == 0
        ? _txt('dialog_page1_complete_title')
        : _txt('dialog_page2_complete_title');
    final body = pageIndex == 0
        ? _txt('dialog_page1_complete_body')
        : _txt('dialog_page2_complete_body');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: title,
        body: body,
        buttonLabel: _txt('dialog_continue_button'),
        onPressed: () {
          Navigator.pop(context);
          onContinue();
        },
      ),
    );
  }

  void _showFinalCompletePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.emoji_events_rounded,
        iconColor: AppColors.brandRed,
        title: _txt('dialog_final_title'),
        body: _txt('dialog_final_body'),
        buttonLabel: _txt('dialog_final_button'),
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAssessmentIntroPage()),
          );
        },
      ),
    );
  }

  void _showInfoPopup({
    required String title,
    required String message,
    IconData icon = Icons.info_rounded,
    Color color = accent,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            height: 1.55,
            color: Color(0xFF374151),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _txt('dialog_info_ok'),
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _showDoorCheckPopup() {
    _showInfoPopup(
      title: _txt('popup_door_rule_title'),
      icon: Icons.door_front_door_rounded,
      color: AppColors.brandRedDark,
      message: _txt('popup_door_rule_body'),
    );
  }

  void _showStopDropRollPopup() {
    _showInfoPopup(
      title: _txt('popup_stop_drop_roll_title'),
      icon: Icons.accessibility_new_rounded,
      color: AppColors.error,
      message: _txt('popup_stop_drop_roll_body'),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Stack(
          children: [
            _LMGradientBackdrop(),
            SafeArea(child: Center(child: _LoadingCard())),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _LMGradientBackdrop(),
            SafeArea(
              child: Center(
                child: _ErrorCard(
                  title: _txt('error_learning_materials_title'),
                  message: _loadError!,
                  retryLabel: _txt('error_retry_button'),
                  onRetry: () {
                    setState(() {
                      _isLoading = true;
                      _loadError = null;
                    });
                    _loadLearningMaterials();
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isLast = _pageIndex == 2;
    final nextEnabled = _hasReadAllRequiredSections(_pageIndex);

    return _LmCopyScope(
      text: _txt,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _LMGradientBackdrop(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    child: _LearningAssessmentHeader(
                      sectionTitle: _txt('header_section_title'),
                      moduleLabel: _txt('module_label'),
                      pageLabel: _txt('header_page_label'),
                      moduleTitle: _moduleTitle,
                      currentPage: _pageIndex + 1,
                      totalPages: 3,
                      progress: _progress,
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) {
                        setState(() => _pageIndex = i);
                        _resetForNewPage();
                      },
                      children: [
                        _pageWrap(_page1HouseFireOverview()),
                        _pageWrap(_page2EscapeSteps()),
                        _pageWrap(_page3AfterEscapeAndPrepare()),
                      ],
                    ),
                  ),
                  _BottomNavBar(
                    pageIndex: _pageIndex,
                    isLast: isLast,
                    nextEnabled: nextEnabled,
                    onBack: _goBack,
                    onNext: _goNext,
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageWrap(Widget child) {
    return SingleChildScrollView(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.brandRed.withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 1: HOUSE FIRE OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _page1HouseFireOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.home_work_rounded,
          accent1: accent,
          accent2: accent2,
          pageTag: _txt('page_1_tag'),
          title: _pageTitle(1),
          subtitle: _txt('page_1_subtitle'),
        ),
        const SizedBox(height: 16),
        _LessonIntroStrip(
          icon: Icons.local_fire_department_rounded,
          title: _txt('page_1_intro_title'),
          text: _txt('page_1_intro_text'),
        ),
        const SizedBox(height: 16),
        _HouseFire3DPhotoCard(
          modelAssetPath: _assetPath('module2_house_fire_model_glb'),
          title: _txt('page_1_preview_title'),
          subtitle: _txt('page_1_preview_subtitle'),
        ),
        const SizedBox(height: 16),
        _ReferenceSourceCard(
          label: _txt('source_p1_shared'),
          title: _sourceTitle('source_p1_shared'),
          url: _sourceUrl('source_p1_shared'),
          icon: Icons.verified_rounded,
          color: AppColors.info,
        ),
        const SizedBox(height: 16),
        _ExpandableLesson(
          icon: Icons.whatshot_rounded,
          title: _txt('p1_s1_title'),
          subtitle: _txt('p1_s1_subtitle'),
          isRead: _readSections[0].contains(0),
          onOpened: () => _markSectionRead(0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniHeadline(_txt('p1_s1_headline')),
              _BodyText(_txt('p1_s1_body')),
              const SizedBox(height: 12),
              _Callout(
                icon: Icons.timer_rounded,
                color: AppColors.brandRedDark,
                title: _txt('p1_s1_callout_title'),
                lines: [_txt('p1_s1_callout_line_1')],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          icon: Icons.air_rounded,
          title: _txt('p1_s2_title'),
          subtitle: _txt('p1_s2_subtitle'),
          isRead: _readSections[0].contains(1),
          onOpened: () => _markSectionRead(0, 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullets(
                items: [
                  _txt('p1_s2_bullet_1'),
                  _txt('p1_s2_bullet_2'),
                  _txt('p1_s2_bullet_3'),
                ],
              ),
              const SizedBox(height: 12),
              _SafetyTipCard(
                title: _txt('p1_s2_tip_title'),
                message: _txt('p1_s2_tip_message'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          icon: Icons.warning_amber_rounded,
          title: _txt('p1_s3_title'),
          subtitle: _txt('p1_s3_subtitle'),
          isRead: _readSections[0].contains(2),
          onOpened: () => _markSectionRead(0, 2),
          child: Column(
            children: [
              _ChipLine(
                icon: Icons.smoke_free_rounded,
                color: AppColors.textSecondary,
                text: _txt('p1_s3_chip_1'),
              ),
              const SizedBox(height: 8),
              _ChipLine(
                icon: Icons.campaign_rounded,
                color: AppColors.brandRedDark,
                text: _txt('p1_s3_chip_2'),
              ),
              const SizedBox(height: 8),
              _ChipLine(
                icon: Icons.local_fire_department_rounded,
                color: AppColors.error,
                text: _txt('p1_s3_chip_3'),
              ),
              const SizedBox(height: 8),
              _ChipLine(
                icon: Icons.device_thermostat_rounded,
                color: AppColors.warning,
                text: _txt('p1_s3_chip_4'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionWideCard(
          icon: Icons.door_front_door_rounded,
          title: _txt('p1_action_title'),
          body: _txt('p1_action_body'),
          buttonLabel: _txt('p1_action_button'),
          onTap: _showDoorCheckPopup,
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount: _readSections[0].length,
          totalCount: _requiredSectionCountForPage(0),
          context: context,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 2: ESCAPE STEPS
  // ---------------------------------------------------------------------------
  Widget _page2EscapeSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.directions_run_rounded,
          accent1: accent2,
          accent2: accent,
          pageTag: _txt('page_2_tag'),
          title: _pageTitle(2),
          subtitle: _txt('page_2_subtitle'),
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          icon: Icons.route_rounded,
          title: _txt('page_2_section_title'),
          subtitle: _txt('page_2_section_subtitle'),
        ),
        const SizedBox(height: 10),
        _ReferenceSourceCard(
          label: _txt('source_escape_steps'),
          title: _sourceTitle('source_escape_steps'),
          url: _sourceUrl('source_escape_steps'),
          icon: Icons.verified_user_rounded,
          color: AppColors.info,
        ),
        const SizedBox(height: 12),
        _EscapeStepExpandable(
          number: _txt('p2_step1_number'),
          icon: Icons.notifications_active_rounded,
          title: _txt('p2_step1_title'),
          subtitle: _txt('p2_step1_subtitle'),
          isRead: _readSections[1].contains(0),
          onOpened: () => _markSectionRead(1, 0),
          child: _StepPreviewVideoCard(
            title: _txt('p2_step1_preview_title'),
            description: _txt('p2_step1_preview_description'),
            icon: Icons.notifications_active_rounded,
            videoAssetPath: _assetPath('module2_escape_step_1_video'),
          ),
        ),
        const SizedBox(height: 12),
        _EscapeStepExpandable(
          number: _txt('p2_step2_number'),
          icon: Icons.door_front_door_rounded,
          title: _txt('p2_step2_title'),
          subtitle: _txt('p2_step2_subtitle'),
          isRead: _readSections[1].contains(1),
          onOpened: () => _markSectionRead(1, 1),
          child: _StepPreviewVideoCard(
            title: _txt('p2_step2_preview_title'),
            description: _txt('p2_step2_preview_description'),
            icon: Icons.back_hand_rounded,
            videoAssetPath: _assetPath('module2_escape_step_2_video'),
          ),
        ),
        const SizedBox(height: 12),
        _EscapeStepExpandable(
          number: _txt('p2_step3_number'),
          icon: Icons.air_rounded,
          title: _txt('p2_step3_title'),
          subtitle: _txt('p2_step3_subtitle'),
          isRead: _readSections[1].contains(2),
          onOpened: () => _markSectionRead(1, 2),
          child: _StepPreviewVideoCard(
            title: _txt('p2_step3_preview_title'),
            description: _txt('p2_step3_preview_description'),
            icon: Icons.accessibility_new_rounded,
            videoAssetPath: _assetPath('module2_escape_step_3_video'),
          ),
        ),
        const SizedBox(height: 12),
        _EscapeStepExpandable(
          number: _txt('p2_step4_number'),
          icon: Icons.logout_rounded,
          title: _txt('p2_step4_title'),
          subtitle: _txt('p2_step4_subtitle'),
          isRead: _readSections[1].contains(3),
          onOpened: () => _markSectionRead(1, 3),
          child: _StepPreviewVideoCard(
            title: _txt('p2_step4_preview_title'),
            description: _txt('p2_step4_preview_description'),
            icon: Icons.family_restroom_rounded,
            videoAssetPath: _assetPath('module2_escape_step_4_video'),
          ),
        ),
        const SizedBox(height: 14),
        _ExpandableLesson(
          icon: Icons.rule_rounded,
          title: _txt('p2_reminders_title'),
          subtitle: _txt('p2_reminders_subtitle'),
          isRead: _readSections[1].contains(4),
          onOpened: () => _markSectionRead(1, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullets(
                items: [
                  _txt('p2_reminder_bullet_1'),
                  _txt('p2_reminder_bullet_2'),
                  _txt('p2_reminder_bullet_3'),
                  _txt('p2_reminder_bullet_4'),
                  _txt('p2_reminder_bullet_5'),
                ],
              ),
              const SizedBox(height: 12),
              _ActionPill(
                icon: Icons.accessibility_new_rounded,
                label: _txt('p2_reminder_action_label'),
                onTap: _showStopDropRollPopup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount: _readSections[1].length,
          totalCount: _requiredSectionCountForPage(1),
          context: context,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 3: AFTER ESCAPE AND PREPARATION
  // ---------------------------------------------------------------------------
  Widget _page3AfterEscapeAndPrepare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.health_and_safety_rounded,
          accent1: AppColors.warning,
          accent2: accent,
          pageTag: _txt('page_3_tag'),
          title: _pageTitle(3),
          subtitle: _txt('page_3_subtitle'),
        ),
        const SizedBox(height: 16),
        _ReferenceSourceCard(
          label: _txt('source_p3_shared'),
          title: _sourceTitle('source_p3_shared'),
          url: _sourceUrl('source_p3_shared'),
          icon: Icons.verified_rounded,
          color: AppColors.error,
        ),
        const SizedBox(height: 14),
        _ExpandableLesson(
          icon: Icons.groups_rounded,
          title: _txt('p3_s1_title'),
          subtitle: _txt('p3_s1_subtitle'),
          isRead: _readSections[2].contains(0),
          onOpened: () => _markSectionRead(2, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(_txt('p3_s1_body')),
              const SizedBox(height: 12),
              _Callout(
                icon: Icons.location_on_rounded,
                color: AppColors.brandRed,
                title: _txt('p3_s1_callout_title'),
                lines: [_txt('p3_s1_callout_line_1')],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          icon: Icons.phone_in_talk_rounded,
          title: _txt('p3_s2_title'),
          subtitle: _txt('p3_s2_subtitle'),
          isRead: _readSections[2].contains(1),
          onOpened: () => _markSectionRead(2, 1),
          child: _Bullets(
            items: [
              _txt('p3_s2_bullet_1'),
              _txt('p3_s2_bullet_2'),
              _txt('p3_s2_bullet_3'),
              _txt('p3_s2_bullet_4'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          icon: Icons.support_agent_rounded,
          title: _txt('p3_s3_title'),
          subtitle: _txt('p3_s3_subtitle'),
          isRead: _readSections[2].contains(2),
          onOpened: () => _markSectionRead(2, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullets(
                items: [
                  _txt('p3_s3_bullet_1'),
                  _txt('p3_s3_bullet_2'),
                  _txt('p3_s3_bullet_3'),
                ],
              ),
              const SizedBox(height: 12),
              _SafetyTipCard(
                title: _txt('p3_s3_tip_title'),
                message: _txt('p3_s3_tip_message'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          icon: Icons.fact_check_rounded,
          title: _txt('p3_s4_title'),
          subtitle: _txt('p3_s4_subtitle'),
          isRead: _readSections[2].contains(3),
          onOpened: () => _markSectionRead(2, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReferenceSourceCard(
                label: _txt('source_smoke_alarms'),
                title: _sourceTitle('source_smoke_alarms'),
                url: _sourceUrl('source_smoke_alarms'),
                icon: Icons.sensors_rounded,
                color: AppColors.info,
              ),
              const SizedBox(height: 12),
              _Bullets(
                items: [
                  _txt('p3_s4_bullet_1'),
                  _txt('p3_s4_bullet_2'),
                  _txt('p3_s4_bullet_3'),
                  _txt('p3_s4_bullet_4'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DidYouKnowCard(
          title: _txt('p3_quick_check_title'),
          message: _txt('p3_quick_check_message'),
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount: _readSections[2].length,
          totalCount: _requiredSectionCountForPage(2),
          context: context,
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
              ),
              child: Text(retryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM NAVIGATION
// =============================================================================
class _BottomNavBar extends StatelessWidget {
  final int pageIndex;
  final bool isLast;
  final bool nextEnabled;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final BuildContext context;

  const _BottomNavBar({
    required this.pageIndex,
    required this.isLast,
    required this.nextEnabled,
    required this.onBack,
    required this.onNext,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final nextLabel = isLast
        ? _lm(ctx, 'nav_start_post_test')
        : _lm(ctx, 'nav_next');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            flex: 4,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brandRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onBack,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: AppColors.brandRed,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _lm(ctx, 'nav_back'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.brandRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 7,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      nextEnabled ? AppColors.brandRed : AppColors.brandRedSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: nextEnabled ? 4 : 0,
                  shadowColor: AppColors.brandRed.withOpacity(0.35),
                ),
                onPressed: onNext,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLast
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: nextEnabled
                          ? Colors.white
                          : AppColors.brandRed.withOpacity(0.4),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        nextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: nextEnabled
                              ? Colors.white
                              : AppColors.brandRed.withOpacity(0.4),
                        ),
                      ),
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

// =============================================================================
// READING PROGRESS BADGE
// =============================================================================
class _ReadingProgressBadge extends StatelessWidget {
  final int readCount;
  final int totalCount;
  final BuildContext context;

  const _ReadingProgressBadge({
    required this.readCount,
    required this.totalCount,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final done = readCount >= totalCount;
    final color = done ? AppColors.success : AppColors.brandRed;
    final label = done
        ? _lm(ctx, 'progress_all_sections_read')
        : _lm(
            ctx,
            'progress_sections_read',
            args: {'read': '$readCount', 'total': '$totalCount'},
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.menu_book_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          if (!done)
            Flexible(
              child: Text(
                _lm(ctx, 'progress_scroll_tap_sections'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(color: color.withOpacity(0.6), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAGE BANNER
// =============================================================================
class _PageBanner extends StatelessWidget {
  final IconData icon;
  final Color accent1;
  final Color accent2;
  final String pageTag;
  final String title;
  final String subtitle;

  const _PageBanner({
    required this.icon,
    required this.accent1,
    required this.accent2,
    required this.pageTag,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent1.withOpacity(0.08), accent2.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent1.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent1, accent2],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accent1.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageTag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: accent1,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.3,
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

// =============================================================================
// EXPANDABLE LESSON SECTION
// =============================================================================
class _ExpandableLesson extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isRead;
  final VoidCallback onOpened;

  const _ExpandableLesson({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isRead,
    required this.onOpened,
  });

  @override
  State<_ExpandableLesson> createState() => _ExpandableLessonState();
}

class _ExpandableLessonState extends State<_ExpandableLesson>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (!_expanded) return;
    widget.onOpened();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.isRead
            ? AppColors.brandRedSoft.withOpacity(0.58)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isRead
              ? AppColors.brandRed.withOpacity(0.28)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.brandRed, AppColors.brandRedDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandRed.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      height: 1.22,
                                    ),
                                  ),
                                ),
                                if (widget.isRead)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 12.8,
                                height: 1.35,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandRed,
                        size: 26,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: widget.child,
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ESCAPE STEP EXPANDABLE / VIDEO STYLE CARDS
// =============================================================================
class _EscapeStepExpandable extends StatefulWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isRead;
  final VoidCallback onOpened;

  const _EscapeStepExpandable({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isRead,
    required this.onOpened,
  });

  @override
  State<_EscapeStepExpandable> createState() => _EscapeStepExpandableState();
}

class _EscapeStepExpandableState extends State<_EscapeStepExpandable> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) widget.onOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isRead ? AppColors.brandRedSoft.withOpacity(0.64) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isRead
              ? AppColors.brandRed.withOpacity(0.25)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.brandRed, AppColors.brandRedDark],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: Text(
                            widget.number,
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
                            Row(
                              children: [
                                Icon(widget.icon, size: 17, color: AppColors.brandRed),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (widget.isRead)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.32,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.play_circle_fill_rounded,
                        color: AppColors.brandRed,
                        size: 28,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: widget.child,
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepPreviewVideoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? videoAssetPath;

  const _StepPreviewVideoCard({
    required this.title,
    required this.description,
    required this.icon,
    this.videoAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: videoAssetPath == null
                ? _VideoPlaceholder(icon: icon)
                : _InlineAssetVideoPlayer(source: videoAssetPath!),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAssetVideoPlayer extends StatefulWidget {
  final String source;

  const _InlineAssetVideoPlayer({required this.source});

  @override
  State<_InlineAssetVideoPlayer> createState() => _InlineAssetVideoPlayerState();
}

class _InlineAssetVideoPlayerState extends State<_InlineAssetVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final isNetwork = _isNetworkPath(widget.source);
      final controller = isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
          : VideoPlayerController.asset(widget.source);
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const _VideoPlaceholder(isLoading: true);
    }

    if (_hasError || _controller == null) {
      return const _VideoPlaceholder(hasError: true);
    }

    final controller = _controller!;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
              child: Center(
                child: AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final IconData icon;

  const _VideoPlaceholder({
    this.isLoading = false,
    this.hasError = false,
    this.icon = Icons.smart_display_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandRed.withOpacity(0.14),
            AppColors.warning.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(
                hasError ? Icons.error_outline_rounded : icon,
                color: AppColors.brandRed,
                size: 38,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                hasError
                    ? _lm(context, 'video_preview_unavailable')
                    : _lm(context, 'video_preview_holder'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SOURCE / REFERENCE UI
// =============================================================================
class _VideoSourceCard extends StatelessWidget {
  final String title;
  final String url;

  const _VideoSourceCard({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return _ReferenceSourceCard(
      label: title,
      title: _lm(context, 'widget_video_3d_preview_title'),
      url: url,
      icon: Icons.smart_display_rounded,
      color: AppColors.brandRed,
    );
  }
}

class _ReferenceSourceCard extends StatelessWidget {
  final String label;
  final String title;
  final String url;
  final IconData icon;
  final Color color;

  const _ReferenceSourceCard({
    required this.label,
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
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

// =============================================================================
// 3D MODEL PREVIEW CARD HOLDER
// =============================================================================
class _HouseFire3DPhotoCard extends StatelessWidget {
  final String? modelAssetPath;
  final String title;
  final String subtitle;

  const _HouseFire3DPhotoCard({
    required this.modelAssetPath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF7), Color(0xFFFFF1E7)],
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
            child: const Icon(
              Icons.view_in_ar_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.12,
              fontFamily: 'Poppins',
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
                const Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: AppColors.brandRed,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _lm(context, 'house_fire_3d_chip'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.brandRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _PageOneHouseFire3DPreview(modelAssetPath: modelAssetPath),
        ],
      ),
    );
  }
}

class _PageOneHouseFire3DPreview extends StatelessWidget {
  final String? modelAssetPath;

  const _PageOneHouseFire3DPreview({required this.modelAssetPath});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth * 1.75)
            .clamp(560.0, 720.0)
            .toDouble();
        final modelPath = _resolveHouseFireModelPath(modelAssetPath);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _lm(context, 'widget_video_3d_preview_title'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.2,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _lm(context, 'house_fire_3d_chip'),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                height: previewHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.brandRed.withOpacity(0.10)),
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
                              AppColors.brandRedSoft.withOpacity(0.58),
                              AppColors.brandRed.withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -42,
                      top: -44,
                      child: _HouseFireSoftGlowBlob(
                        size: 150,
                        color: AppColors.brandRed.withOpacity(0.11),
                      ),
                    ),
                    Positioned(
                      right: -46,
                      bottom: -52,
                      child: _HouseFireSoftGlowBlob(
                        size: 170,
                        color: AppColors.warning.withOpacity(0.15),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HouseFireGridPainter(
                          color: AppColors.brandRed.withOpacity(0.045),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _HouseFireViewerBadge(
                        icon: Icons.view_in_ar_rounded,
                        label: _lm(context, 'house_fire_3d_viewer_badge'),
                        color: AppColors.brandRed,
                      ),
                    ),
                    Positioned.fill(
                      top: 24,
                      bottom: 8,
                      child: modelPath == null
                          ? _MissingHouseFireModelCard()
                          : _AnimatedHouseFireModelViewer(modelPath: modelPath),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Stack(
                          children: [
                            Positioned(
                              top: previewHeight * 0.12,
                              left: 16,
                              child: const _HouseFireModelLabel(''),
                            ),
                            Positioned(
                              top: previewHeight * 0.17,
                              right: 16,
                              child: const _HouseFireModelLabel(''),
                            ),
                            Positioned(
                              top: previewHeight * 0.40,
                              left: 12,
                              child: const _HouseFireModelLabel(''),
                            ),
                            Positioned(
                              top: previewHeight * 0.48,
                              right: 12,
                              child: const _HouseFireModelLabel(''),
                            ),
                            Positioned(
                              bottom: previewHeight * 0.18,
                              left: 14,
                              child: const _HouseFireModelLabel(''),
                            ),
                            Positioned(
                              bottom: previewHeight * 0.10,
                              right: 14,
                              child: const _HouseFireModelLabel(''),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  const Icon(
                    Icons.touch_app_rounded,
                    color: AppColors.brandRed,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lm(context, 'house_fire_3d_rotate_instruction'),
                      style: const TextStyle(
                        color: AppColors.brandRedDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String? _resolveHouseFireModelPath(String? rawPath) {
    final path = rawPath?.trim();
    if (path != null &&
        path.isNotEmpty &&
        path.toLowerCase().endsWith('.glb')) {
      return path;
    }
    return null;
  }
}

class _MissingHouseFireModelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _lm(context, 'house_fire_3d_missing_asset'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AnimatedHouseFireModelViewer extends StatefulWidget {
  final String modelPath;

  const _AnimatedHouseFireModelViewer({required this.modelPath});

  @override
  State<_AnimatedHouseFireModelViewer> createState() =>
      _AnimatedHouseFireModelViewerState();
}

class _AnimatedHouseFireModelViewerState extends State<_AnimatedHouseFireModelViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final floatOffset = -4.0 + (_controller.value * 8.0);

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: ModelViewer(
            key: ValueKey(widget.modelPath),
            src: widget.modelPath,
            alt: _lm(context, 'house_fire_3d_alt_text'),
            backgroundColor: Colors.transparent,
            cameraControls: true,
            autoRotate: true,
            autoRotateDelay: 0,
            rotationPerSecond: '24deg',
            disableZoom: false,
            interactionPrompt: InteractionPrompt.auto,
            cameraOrbit: '35deg 68deg 4.6m',
            fieldOfView: '28deg',
            minCameraOrbit: 'auto auto 3.2m',
            maxCameraOrbit: 'auto auto 7m',
            shadowIntensity: 0.55,
            exposure: 1.05,
            loading: Loading.eager,
            reveal: Reveal.auto,
          ),
        );
      },
    );
  }
}

class _HouseFireModelLabel extends StatelessWidget {
  final String label;

  const _HouseFireModelLabel(this.label);

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

class _HouseFireViewerBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HouseFireViewerBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.84),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseFireSoftGlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _HouseFireSoftGlowBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HouseFireGridPainter extends CustomPainter {
  final Color color;

  const _HouseFireGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 18.0;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }

    for (double x = 0; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HouseFireGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// =============================================================================
// CONTENT CARDS
// =============================================================================
class _DidYouKnowCard extends StatelessWidget {
  final String title;
  final String message;

  const _DidYouKnowCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 25),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
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

class _SafetyTipCard extends StatelessWidget {
  final String title;
  final String message;

  const _SafetyTipCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_rounded,
              color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.brandRedSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.brandRed, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyledDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.buttonLabel,
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
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.black54,
                    onPressed: () => Navigator.pop(context),
                    tooltip: _lm(context, 'dialog_close_tooltip'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
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
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  buttonLabel,
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
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String asset;
  final Color c1;
  final Color c2;

  const _ImageBox({required this.asset, required this.c1, required this.c2});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1.withOpacity(0.12), c2.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.home_work_rounded, color: c1, size: 42),
      ),
    );
  }
}

class _MiniHeadline extends StatelessWidget {
  final String text;

  const _MiniHeadline(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppColors.brandRed,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        color: AppColors.textSecondary,
        height: 1.52,
      ),
    );
  }
}

class _LessonIntroStrip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _LessonIntroStrip({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandRed, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
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

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  const _Callout({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l,
                      style: const TextStyle(height: 1.4, color: AppColors.textSecondary),
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

class _ChipLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ChipLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandRed,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionWideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionWideCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.brandRed, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
              label: Text(
                buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;

  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
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

// =============================================================================
// HEADER
// =============================================================================
class _LearningAssessmentHeader extends StatelessWidget {
  final String sectionTitle;
  final String moduleLabel;
  final String pageLabel;
  final String moduleTitle;
  final int currentPage;
  final int totalPages;
  final double progress;
  final VoidCallback onClose;

  const _LearningAssessmentHeader({
    required this.sectionTitle,
    required this.moduleLabel,
    required this.pageLabel,
    required this.moduleTitle,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

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
                decoration: BoxDecoration(
                  color: AppColors.textOnRed.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textOnRed.withOpacity(0.24),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textOnRed,
                  size: 21,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: Text(
            sectionTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnRed,
              fontFamily: 'Poppins',
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandRedLight,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandRed.withOpacity(0.24),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home_rounded,
                    color: AppColors.textOnRed,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    moduleLabel,
                    style: const TextStyle(
                      color: AppColors.textOnRed,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                moduleTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textOnRed.withOpacity(0.88),
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeProgress,
            minHeight: 8,
            backgroundColor: AppColors.textOnRed.withOpacity(0.22),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.textOnRed,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '$pageLabel $currentPage/$totalPages',
              style: TextStyle(
                color: AppColors.textOnRed.withOpacity(0.76),
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              children: List.generate(totalPages, (index) {
                final active = index == currentPage - 1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: active ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.textOnRed
                        : AppColors.textOnRed.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// GRADIENT BACKDROP
// =============================================================================
class _LMGradientBackdrop extends StatelessWidget {
  const _LMGradientBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandRedDeep,
                AppColors.brandRedDark,
                AppColors.brandRed,
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
          ),
        ),
        const Positioned(
          top: 50,
          right: -36,
          child: _LMDecorCircle(size: 138, opacity: 0.17),
        ),
        const Positioned(
          top: 178,
          left: -42,
          child: _LMDecorCircle(size: 124, opacity: 0.13),
        ),
      ],
    );
  }
}

class _LMDecorCircle extends StatelessWidget {
  const _LMDecorCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.textOnRed.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

