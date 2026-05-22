import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_assess_instruction.dart';


// =============================================================================
// APP COLORS
// =============================================================================
class AppColors {
  // Module 3 Electrical Fire blue palette
  static const Color brandRed = Color(0xFF2563EB);
  static const Color brandRedDark = Color(0xFF1D4ED8);
  static const Color brandRedDeep = Color(0xFF1E3A8A);
  static const Color brandRedLight = Color(0xFF60A5FA);
  static const Color brandRedSoft = Color(0xFFEFF6FF);

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEFF6FF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnRed = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFBFDBFE);
  static const Color divider = Color(0xFFDBEAFE);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);

  // Buttons
  static const Color primaryButton = Color(0xFF2563EB);
  static const Color primaryButtonPressed = Color(0xFF1D4ED8);
  static const Color secondaryButton = Color(0xFFEFF6FF);

  // Shadows
  static const Color shadow = Color(0x1A000000);
}



const int _moduleNo = 3;
const String _learningMaterialsBucket = 'Learning Materials';
_LearningMaterialContent? _module3LoadedContentCache;

class _LocalizedText {
  final String en;
  final String? tl;

  const _LocalizedText({required this.en, this.tl});

  String value(BuildContext context) {
    final useTagalog = Localizations.localeOf(context).languageCode == 'tl';
    final tagalog = tl?.trim() ?? '';
    if (useTagalog && tagalog.isNotEmpty) return tagalog;
    return en;
  }
}

class _LearningSource {
  final String key;
  final String organization;
  final String sourceUrl;

  const _LearningSource({
    required this.key,
    required this.organization,
    required this.sourceUrl,
  });

  factory _LearningSource.fromMap(Map<String, dynamic> row) {
    return _LearningSource(
      key: (row['block_key'] ?? '').toString(),
      organization: (row['source_organization'] ?? '').toString(),
      sourceUrl: (row['source_url'] ?? '').toString(),
    );
  }

  static const empty = _LearningSource(
    key: '',
    organization: '',
    sourceUrl: '',
  );
}

class _LearningMediaAsset {
  final String key;
  final String assetPath;
  final String publicUrl;

  const _LearningMediaAsset({
    required this.key,
    required this.assetPath,
    required this.publicUrl,
  });

  factory _LearningMediaAsset.fromMap(Map<String, dynamic> row) {
    return _LearningMediaAsset(
      key: (row['asset_key'] ?? '').toString(),
      assetPath: (row['asset_path'] ?? '').toString(),
      publicUrl: (row['public_url'] ?? '').toString(),
    );
  }

  String resolvedPath() {
    final directUrl = publicUrl.trim();
    if (directUrl.isNotEmpty) return directUrl;

    final path = assetPath.trim();
    if (path.isEmpty) return '';
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('assets/')) {
      return path;
    }

    final storagePath = path.startsWith('/') ? path.substring(1) : path;
    return Supabase.instance.client.storage
        .from(_learningMaterialsBucket)
        .getPublicUrl(storagePath);
  }
}

class _LearningMaterialContent {
  final Map<String, _LocalizedText> texts;
  final Map<String, _LearningSource> sources;
  final Map<String, _LearningMediaAsset> mediaAssets;

  const _LearningMaterialContent({
    required this.texts,
    required this.sources,
    required this.mediaAssets,
  });

  String text(BuildContext context, String key) {
    return texts[key]?.value(context) ?? '';
  }

  _LearningSource source(String key) {
    return sources[key] ?? _LearningSource.empty;
  }

  String mediaPath(String key) {
    return mediaAssets[key]?.resolvedPath() ?? '';
  }
}

class _LearningMaterialScope extends InheritedWidget {
  final _LearningMaterialContent content;

  const _LearningMaterialScope({
    required this.content,
    required super.child,
  });

  @override
  bool updateShouldNotify(_LearningMaterialScope oldWidget) {
    return oldWidget.content != content;
  }
}

String _lmText(BuildContext context, String key) {
  return context
          .dependOnInheritedWidgetOfExactType<_LearningMaterialScope>()
          ?.content
          .text(context, key) ??
      _module3LoadedContentCache?.text(context, key) ??
      '';
}

_LearningSource _lmSource(BuildContext context, String key) {
  return context
          .dependOnInheritedWidgetOfExactType<_LearningMaterialScope>()
          ?.content
          .source(key) ??
      _module3LoadedContentCache?.source(key) ??
      _LearningSource.empty;
}

String _lmMediaPath(BuildContext context, String key) {
  return context
          .dependOnInheritedWidgetOfExactType<_LearningMaterialScope>()
          ?.content
          .mediaPath(key) ??
      _module3LoadedContentCache?.mediaPath(key) ??
      '';
}

Future<_LearningMaterialContent> _loadModule3LearningMaterialContent() async {
  final client = Supabase.instance.client;

  final material = await client
      .from('learning_materials')
      .select('id')
      .eq('module_no', _moduleNo)
      .eq('is_active', true)
      .maybeSingle();

  if (material == null) {
    throw StateError('No active Learning Materials record found for Module 3.');
  }

  final learningMaterialId = material['id'] as String;

  final textRows = await client
      .from('learning_material_texts')
      .select('text_key, text_en, text_tl')
      .eq('learning_material_id', learningMaterialId)
      .eq('module_no', _moduleNo)
      .eq('usage_context', 'mobile_learning_material')
      .eq('is_active', true)
      .order('text_order', ascending: true);

  final sourceRows = await client
      .from('learning_material_blocks')
      .select('block_key, source_organization, source_url')
      .eq('module_no', _moduleNo)
      .eq('block_type', 'source')
      .eq('is_active', true)
      .order('block_no', ascending: true);

  final mediaRows = await client
      .from('learning_material_media_assets')
      .select('asset_key, asset_path, public_url')
      .eq('learning_material_id', learningMaterialId)
      .eq('module_no', _moduleNo)
      .eq('is_active', true)
      .order('display_order', ascending: true);

  return _LearningMaterialContent(
    texts: {
      for (final row in List<Map<String, dynamic>>.from(textRows))
        (row['text_key'] ?? '').toString(): _LocalizedText(
          en: (row['text_en'] ?? '').toString(),
          tl: row['text_tl']?.toString(),
        ),
    },
    sources: {
      for (final row in List<Map<String, dynamic>>.from(sourceRows))
        (row['block_key'] ?? '').toString(): _LearningSource.fromMap(row),
    },
    mediaAssets: {
      for (final row in List<Map<String, dynamic>>.from(mediaRows))
        (row['asset_key'] ?? '').toString(): _LearningMediaAsset.fromMap(row),
    },
  );
}


// =============================================================================
// MAIN PAGE
// =============================================================================
class LearningMaterialElectricalPage extends StatefulWidget {
  const LearningMaterialElectricalPage({super.key});

  @override
  State<LearningMaterialElectricalPage> createState() =>
      _LearningMaterialElectricalPageState();
}

class _LearningMaterialElectricalPageState
    extends State<LearningMaterialElectricalPage> {
  static const accent = AppColors.brandRed;
  static const accent2 = AppColors.brandRedDark;

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;
  double _progress = 0.0;
  bool _canNext = false;
  bool _isSwitchingPage = false;
  bool _lastPageCompleted = false;

  // Page 0: 4 expandable sections
  // Page 1: 3 expandable sections
  // Page 2: 4 expandable sections
  final List<Set<int>> _readSections = [<int>{}, <int>{}, <int>{}];

  bool _introShown = false;
  bool _unreadPromptVisible = false;
  bool _isContentLoading = true;
  String? _contentError;
  _LearningMaterialContent? _content;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadContent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
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


  Future<void> _loadContent() async {
    try {
      final content = await _loadModule3LearningMaterialContent();
      if (!mounted) return;
      _module3LoadedContentCache = content;
      setState(() {
        _content = content;
        _contentError = null;
        _isContentLoading = false;
      });
      if (!_introShown) {
        _introShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _showIntroPopup();
          });
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _contentError = error.toString();
        _isContentLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (identical(_module3LoadedContentCache, _content)) {
      _module3LoadedContentCache = null;
    }
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
        return 4;
      case 1:
        return 3;
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
        title: _lmText(context, 'm3_lm_001_keep_reading'),
        body: _lmText(context, 'm3_lm_002_please_open_and_read_all_required_sections'),
        buttonLabel: _lmText(context, 'm3_lm_003_got_it'),
        onPressed: () {
          Navigator.pop(context);
          _unreadPromptVisible = false;
        },
      ),
    ).then((_) => _unreadPromptVisible = false);
  }

  void _showIntroPopup() {
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: Icons.bolt_rounded,
        iconColor: AppColors.brandRed,
        title: _lmText(context, 'm3_lm_004_module_3_electrical_fire'),
        body: _lmText(context, 'm3_lm_005_read_each_card_carefully_open_every_sectio'),
        buttonLabel: _lmText(context, 'm3_lm_006_start_learning'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showPageCompletePopup(int pageIndex, VoidCallback onContinue) {
    final titles = [
      _lmText(context, 'm3_lm_007_section_complete'),
      _lmText(context, 'm3_lm_008_great_progress'),
    ];

    final bodies = [
      _lmText(context, 'm3_lm_009_you_now_know_what_electrical_fires_are_and'),
      _lmText(context, 'm3_lm_010_you_reviewed_the_common_causes_warning_sig'),
      _lmText(context, 'm3_lm_011_you_completed_the_emergency_response_guide'),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: titles[pageIndex % titles.length],
        body: bodies[pageIndex % bodies.length],
        buttonLabel: _lmText(context, 'm3_lm_012_continue'),
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
        title: _lmText(context, 'm3_lm_013_all_done'),
        body: _lmText(context, 'm3_lm_014_great_job_you_have_completed_the_module_3'),
        buttonLabel: _lmText(context, 'm3_lm_015_start_post_assessment'),
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PostAssessmentIntroPage(),
            ),
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
      builder: (_) => _StyledDialog(
        icon: icon,
        iconColor: color,
        title: title,
        body: message,
        buttonLabel: _lmText(context, 'm3_lm_016_close'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showScenePreviewPopup() {
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: Icons.electrical_services_rounded,
        iconColor: AppColors.brandRed,
        title: _lmText(context, 'm3_lm_017_scene_3_electrical_fire_guide'),
        body: _lmText(context, 'm3_lm_018_this_preview_shows_what_to_remember_before'),
        buttonLabel: _lmText(context, 'm3_lm_019_understood'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isLast = _pageIndex == 2;
    final nextEnabled = _hasReadAllRequiredSections(_pageIndex);

    if (_isContentLoading) {
      return _ContentStateScaffold(
        message: 'Loading learning materials...',
        showRetry: false,
        onRetry: _loadContent,
      );
    }

    if (_contentError != null || _content == null) {
      return _ContentStateScaffold(
        message: 'Unable to load learning materials.',
        detail: _contentError,
        showRetry: true,
        onRetry: () {
          setState(() {
            _isContentLoading = true;
            _contentError = null;
          });
          _loadContent();
        },
      );
    }

    return _LearningMaterialScope(
      content: _content!,
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
                    sectionTitle: _lmText(context, 'm3_lm_020_learning_materials'),
                    moduleLabel: _lmText(context, 'm3_lm_021_module_3'),
                    moduleTitle: _lmText(context, 'm3_lm_022_electrical_fire_causes_safe_actions_and_pr'),
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
                      _pageWrap(_page1ElectricalBasics()),
                      _pageWrap(_page2CausesAndPrevention()),
                      _pageWrap(_page3EmergencyResponse()),
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
                color: AppColors.brandRed.withOpacity(0.08),
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
  // PAGE 1: ELECTRICAL FIRE BASICS
  // ---------------------------------------------------------------------------
  Widget _page1ElectricalBasics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.bolt_rounded,
          accent1: accent,
          accent2: accent2,
          pageTag: _lmText(context, 'm3_lm_023_page_1_of_3'),
          title: _lmText(context, 'm3_lm_024_electrical_fire_basics'),
          subtitle: _lmText(context, 'm3_lm_025_understand_what_makes_this_fire_different'),
        ),
        const SizedBox(height: 16),
        _ElectricalPreviewCard(
          assetPath: _lmMediaPath(context, 'm3_media_electrical_preview_image'),
          title: _lmText(context, 'm3_lm_026_3d_electrical_fire_preview'),
          subtitle: _lmText(context, 'm3_lm_027_preview_the_electrical_fire_safety_actions'),
          onTap: _showScenePreviewPopup,
        ),
        const SizedBox(height: 16),
        _LessonIntroStrip(
          icon: Icons.touch_app_rounded,
          text: _lmText(context, 'm3_lm_028_tap_each_card_below_a_section_is_counted_a'),
        ),
        const SizedBox(height: 18),
        _SectionHeader(_lmText(context, 'm3_lm_029_start_with_the_key_concepts')),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 0,
          sectionIndex: 0,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(0, section),
          icon: Icons.help_outline_rounded,
          accentColor: AppColors.brandRed,
          title: _lmText(context, 'm3_lm_030_what_is_an_electrical_fire'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(_lmText(context, 'm3_lm_031_an_electrical_fire_is_caused_by_electrical')),
              const SizedBox(height: 12),
              _ReferenceSourceCard(
                label: _lmText(context, 'm3_lm_032_reference_source'),
                title: _lmText(context, 'm3_lm_033_electrical_safety_and_home_fire_prevention'),
                organization: _lmSource(context, 'm3_source_nfpa_electrical_safety').organization,
                sourceUrl: _lmSource(context, 'm3_source_nfpa_electrical_safety').sourceUrl,
                icon: Icons.verified_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 0,
          sectionIndex: 1,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(0, section),
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.error,
          title: _lmText(context, 'm3_lm_034_why_electrical_fires_are_dangerous'),
          child: _Callout(
            icon: Icons.priority_high_rounded,
            color: AppColors.error,
            title: _lmText(context, 'm3_lm_035_high_risk'),
            lines: [
              _lmText(context, 'm3_lm_036_they_can_spread_inside_walls_or_ceilings_b'),
              _lmText(context, 'm3_lm_037_they_can_reignite_if_the_power_source_rema'),
              _lmText(context, 'm3_lm_038_water_can_conduct_electricity_and_create_s'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 0,
          sectionIndex: 2,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(0, section),
          icon: Icons.local_fire_department_rounded,
          accentColor: AppColors.warning,
          title: _lmText(context, 'm3_lm_039_fire_class_and_correct_extinguisher'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChipLine(
                icon: Icons.class_rounded,
                color: AppColors.brandRedDeep,
                text: _lmText(context, 'm3_lm_040_electrical_fires_are_commonly_treated_as_c'),
              ),
              const SizedBox(height: 12),
              _BodyText(_lmText(context, 'm3_lm_041_use_a_class_c_or_multipurpose_abc_extingui')),
              const SizedBox(height: 12),
              _ReferenceSourceCard(
                label: _lmText(context, 'm3_lm_042_reference_source'),
                title: _lmText(context, 'm3_lm_043_fire_extinguisher_types'),
                organization: _lmSource(context, 'm3_source_nfpa_extinguisher_types').organization,
                sourceUrl: _lmSource(context, 'm3_source_nfpa_extinguisher_types').sourceUrl,
                icon: Icons.fire_extinguisher_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 0,
          sectionIndex: 3,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(0, section),
          icon: Icons.category_rounded,
          accentColor: AppColors.brandRedDark,
          title: _lmText(context, 'm3_lm_044_common_types_of_electrical_fire'),
          child: _ResponsiveTileGrid(
            children: [
              _InfoTile(
                color: AppColors.brandRed,
                icon: Icons.flash_on_rounded,
                title: _lmText(context, 'm3_lm_045_short_circuit'),
                desc: _lmText(context, 'm3_lm_046_live_wires_touch_or_insulation_fails_creat'),
              ),
              _InfoTile(
                color: AppColors.brandRedDark,
                icon: Icons.power_rounded,
                title: _lmText(context, 'm3_lm_047_overload'),
                desc: _lmText(context, 'm3_lm_048_too_many_devices_draw_power_from_one_outle'),
              ),
              _InfoTile(
                color: AppColors.warning,
                icon: Icons.electrical_services_rounded,
                title: _lmText(context, 'm3_lm_049_faulty_appliance'),
                desc: _lmText(context, 'm3_lm_050_internal_wiring_or_components_fail_inside'),
              ),
              _InfoTile(
                color: const Color(0xFFEA580C),
                icon: Icons.cable_rounded,
                title: _lmText(context, 'm3_lm_051_loose_wiring'),
                desc: _lmText(context, 'm3_lm_052_loose_connections_create_resistance_heat_a'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount: _readSections[0].length,
          totalCount: 4,
          context: context,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 2: CAUSES AND PREVENTION
  // ---------------------------------------------------------------------------
  Widget _page2CausesAndPrevention() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.fact_check_rounded,
          accent1: AppColors.brandRedDark,
          accent2: AppColors.brandRed,
          pageTag: _lmText(context, 'm3_lm_053_page_2_of_3'),
          title: _lmText(context, 'm3_lm_054_causes_and_prevention'),
          subtitle: _lmText(context, 'm3_lm_055_spot_unsafe_habits_before_they_become_emer'),
        ),
        const SizedBox(height: 16),
        _ReferenceSourceCard(
          label: _lmText(context, 'm3_lm_056_shared_source_for_this_page'),
          title: _lmText(context, 'm3_lm_057_home_electrical_safety_practices'),
          organization: _lmSource(context, 'm3_source_esfi_home_electrical_safety').organization,
          sourceUrl: _lmSource(context, 'm3_source_esfi_home_electrical_safety').sourceUrl,
          icon: Icons.verified_user_rounded,
        ),
        const SizedBox(height: 16),
        _LessonIntroStrip(
          icon: Icons.rule_rounded,
          text: _lmText(context, 'm3_lm_058_the_source_appears_once_here_because_the_s'),
        ),
        const SizedBox(height: 18),
        _SectionHeader(_lmText(context, 'm3_lm_059_tap_each_prevention_section')),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 1,
          sectionIndex: 0,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(1, section),
          icon: Icons.report_problem_rounded,
          accentColor: AppColors.error,
          title: _lmText(context, 'm3_lm_060_common_causes'),
          child: _BulletList(items: [
            _lmText(context, 'm3_lm_061_overloaded_outlets_adaptors_or_extension_c'),
            _lmText(context, 'm3_lm_062_old_cracked_pinched_or_damaged_wiring'),
            _lmText(context, 'm3_lm_063_substandard_chargers_appliances_and_electr'),
            _lmText(context, 'm3_lm_064_poor_electrical_installation_or_unauthoriz'),
            _lmText(context, 'm3_lm_065_leaving_appliances_plugged_in_or_unattende'),
          ]),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 1,
          sectionIndex: 1,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(1, section),
          icon: Icons.visibility_rounded,
          accentColor: AppColors.warning,
          title: _lmText(context, 'm3_lm_066_warning_signs_to_check'),
          child: _ResponsiveTileGrid(
            children: [
              _InfoTile(
                color: AppColors.warning,
                icon: Icons.thermostat_rounded,
                title: _lmText(context, 'm3_lm_067_heat'),
                desc: _lmText(context, 'm3_lm_068_warm_outlets_plugs_or_cords'),
              ),
              _InfoTile(
                color: AppColors.error,
                icon: Icons.smoke_free_rounded,
                title: _lmText(context, 'm3_lm_069_burning_smell'),
                desc: _lmText(context, 'm3_lm_070_odor_from_sockets_or_devices'),
              ),
              _InfoTile(
                color: AppColors.brandRedDark,
                icon: Icons.lightbulb_outline_rounded,
                title: _lmText(context, 'm3_lm_071_flicker'),
                desc: _lmText(context, 'm3_lm_072_flickering_lights_or_frequent_tripping'),
              ),
              _InfoTile(
                color: const Color(0xFF7C3AED),
                icon: Icons.power_off_rounded,
                title: _lmText(context, 'm3_lm_073_sparks'),
                desc: _lmText(context, 'm3_lm_074_sparks_when_plugging_devices'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 1,
          sectionIndex: 2,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(1, section),
          icon: Icons.shield_rounded,
          accentColor: AppColors.success,
          title: _lmText(context, 'm3_lm_075_prevention_checklist'),
          child: Column(
            children: [
              _CheckTile(text: _lmText(context, 'm3_lm_076_do_not_overload_outlets_or_extension_cords')),
              _CheckTile(text: _lmText(context, 'm3_lm_077_replace_damaged_cords_immediately')),
              _CheckTile(text: _lmText(context, 'm3_lm_078_avoid_running_cords_under_rugs_carpets_or')),
              _CheckTile(text: _lmText(context, 'm3_lm_079_use_certified_chargers_plugs_and_electrica')),
              _CheckTile(text: _lmText(context, 'm3_lm_080_unplug_appliances_when_they_are_not_being')),
              _CheckTile(text: _lmText(context, 'm3_lm_081_ask_a_licensed_electrician_to_inspect_faul')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DidYouKnowCard(
          icon: Icons.lightbulb_rounded,
          title: _lmText(context, 'm3_lm_082_quick_reminder'),
          body: _lmText(context, 'm3_lm_083_most_prevention_steps_are_simple_habits_re'),
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount: _readSections[1].length,
          totalCount: 3,
          context: context,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE 3: EMERGENCY RESPONSE
  // ---------------------------------------------------------------------------
  Widget _page3EmergencyResponse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.emergency_rounded,
          accent1: AppColors.brandRedDeep,
          accent2: AppColors.brandRed,
          pageTag: _lmText(context, 'm3_lm_084_page_3_of_3'),
          title: _lmText(context, 'm3_lm_085_emergency_response'),
          subtitle: _lmText(context, 'm3_lm_086_learn_the_safe_order_of_actions_during_an'),
        ),
        const SizedBox(height: 16),
        _ScenarioPreviewCard(
          title: _lmText(context, 'm3_lm_087_scene_3_preview_holder'),
          subtitle: _lmText(context, 'm3_lm_088_context_only_3d_video_area_for_the_learnin'),
          onTap: _showScenePreviewPopup,
        ),
        const SizedBox(height: 16),
        _ReferenceSourceCard(
          label: _lmText(context, 'm3_lm_089_emergency_response_source'),
          title: _lmText(context, 'm3_lm_090_electrical_fire_safety_guidance'),
          organization: _lmSource(context, 'm3_source_usfa_electrical_fire').organization,
          sourceUrl: _lmSource(context, 'm3_source_usfa_electrical_fire').sourceUrl,
          icon: Icons.local_fire_department_rounded,
        ),
        const SizedBox(height: 18),
        _SectionHeader(_lmText(context, 'm3_lm_091_what_to_do_during_an_electrical_fire')),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 2,
          sectionIndex: 0,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(2, section),
          icon: Icons.visibility_rounded,
          accentColor: AppColors.brandRed,
          title: _lmText(context, 'm3_lm_092_step_1_assess_from_a_safe_distance'),
          child: _EmergencyStepCard(
            stepLabel: '01',
            icon: Icons.visibility_rounded,
            color: AppColors.brandRed,
            title: _lmText(context, 'm3_lm_093_stay_back_first'),
            lines: [
              _lmText(context, 'm3_lm_094_do_not_touch_burning_equipment_wires_panel'),
              _lmText(context, 'm3_lm_095_look_for_smoke_sparks_heat_and_a_safe_exit'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 2,
          sectionIndex: 1,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(2, section),
          icon: Icons.power_settings_new_rounded,
          accentColor: AppColors.warning,
          title: _lmText(context, 'm3_lm_096_step_2_disconnect_power_only_if_safe'),
          child: _EmergencyStepCard(
            stepLabel: '02',
            icon: Icons.power_settings_new_rounded,
            color: AppColors.warning,
            title: _lmText(context, 'm3_lm_097_power_source_matters'),
            lines: [
              _lmText(context, 'm3_lm_098_turn_off_the_breaker_or_unplug_the_device'),
              _lmText(context, 'm3_lm_099_never_reach_through_fire_smoke_wet_floors'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 2,
          sectionIndex: 2,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(2, section),
          icon: Icons.fire_extinguisher_rounded,
          accentColor: AppColors.brandRedDark,
          title: _lmText(context, 'm3_lm_100_step_3_use_the_correct_extinguisher'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmergencyStepCard(
                stepLabel: '03',
                icon: Icons.fire_extinguisher_rounded,
                color: AppColors.brandRedDark,
                title: _lmText(context, 'm3_lm_101_class_c_or_abc_only'),
                lines: [
                  _lmText(context, 'm3_lm_102_use_a_class_c_or_abc_extinguisher_if_the_f'),
                  _lmText(context, 'm3_lm_103_never_use_water_on_energized_electrical_eq'),
                ],
              ),
              const SizedBox(height: 12),
              _Callout(
                icon: Icons.block_rounded,
                color: AppColors.error,
                title: _lmText(context, 'm3_lm_104_do_not_use_water'),
                lines: [
                  _lmText(context, 'm3_lm_105_water_may_conduct_electricity_and_increase'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          pageIndex: 2,
          sectionIndex: 3,
          readSections: _readSections,
          onRead: (section) => _markSectionRead(2, section),
          icon: Icons.exit_to_app_rounded,
          accentColor: AppColors.success,
          title: _lmText(context, 'm3_lm_106_step_4_evacuate_and_call_for_help'),
          child: _EmergencyStepCard(
            stepLabel: '04',
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.success,
            title: _lmText(context, 'm3_lm_107_life_safety_first'),
            lines: [
              _lmText(context, 'm3_lm_108_evacuate_immediately_if_the_fire_grows_smo'),
              _lmText(context, 'm3_lm_109_close_doors_behind_you_when_safe_stay_outs'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionPill(
                icon: Icons.security_rounded,
                label: _lmText(context, 'm3_lm_110_safety_rule'),
                onTap: () => _showInfoPopup(
                  title: _lmText(context, 'm3_lm_111_safety_rule'),
                  icon: Icons.security_rounded,
                  color: AppColors.brandRed,
                  message: _lmText(context, 'm3_lm_112_only_fight_a_small_fire_if_you_are_trained'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionPill(
                icon: Icons.quiz_rounded,
                label: _lmText(context, 'm3_lm_113_quick_check'),
                onTap: () => _showInfoPopup(
                  title: _lmText(context, 'm3_lm_114_quick_check'),
                  icon: Icons.quiz_rounded,
                  color: AppColors.warning,
                  message: _lmText(context, 'm3_lm_115_question_should_you_pour_water_on_an_energ'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount: _readSections[2].length,
          totalCount: 4,
          context: context,
        ),
      ],
    );
  }
}


class _ContentStateScaffold extends StatelessWidget {
  final String message;
  final String? detail;
  final bool showRetry;
  final VoidCallback onRetry;

  const _ContentStateScaffold({
    required this.message,
    this.detail,
    required this.showRetry,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LMGradientBackdrop(),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(22),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showRetry)
                      const CircularProgressIndicator(color: AppColors.brandRed)
                    else
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 34,
                      ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (detail != null && detail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        detail!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (showRetry) ...[
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
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
// BOTTOM NAV BAR
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
        ? _lmText(context, 'm3_lm_116_start_post_assessment')
        : _lmText(context, 'm3_lm_117_next');

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
      child: SafeArea(
        top: false,
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
                          _lmText(context, 'm3_lm_118_back'),
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
                    backgroundColor: nextEnabled
                        ? AppColors.brandRed
                        : AppColors.brandRedSoft,
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
        ? _lmText(context, 'm3_lm_119_all_sections_read')
        : _lmText(context, 'm3_lm_120_sections_read')
            .replaceAll(r'$readCount', '$readCount')
            .replaceAll(r'$totalCount', '$totalCount');

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
                _lmText(context, 'm3_lm_121_scroll_tap_sections'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  final int sectionIndex;
  final int pageIndex;
  final List<Set<int>> readSections;
  final ValueChanged<int> onRead;
  final IconData icon;
  final Color accentColor;
  final String title;
  final Widget child;

  const _ExpandableLesson({
    required this.sectionIndex,
    required this.pageIndex,
    required this.readSections,
    required this.onRead,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.child,
  });

  @override
  State<_ExpandableLesson> createState() => _ExpandableLessonState();
}

class _ExpandableLessonState extends State<_ExpandableLesson>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  bool get _isRead =>
      widget.readSections[widget.pageIndex].contains(widget.sectionIndex);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animCtrl.forward();
        widget.onRead(widget.sectionIndex);
      } else {
        _animCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRead
              ? AppColors.success.withOpacity(0.3)
              : color.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _isRead
                          ? AppColors.success.withOpacity(0.1)
                          : color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isRead ? Icons.check_rounded : widget.icon,
                      color: _isRead ? AppColors.success : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: _isRead
                            ? AppColors.success
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (_isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _lmText(context, 'm3_lm_122_read'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  widget.child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VISUAL / PREVIEW CARDS
// =============================================================================
class _ElectricalPreviewCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ElectricalPreviewCard({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 68;
        final compact = availableWidth < 340;
        final visualWidth = compact
            ? (availableWidth * 0.68).clamp(118.0, 166.0).toDouble()
            : (availableWidth * 0.36).clamp(112.0, 148.0).toDouble();

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 14 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF7F7), Color(0xFFFFE8EA)],
              ),
              border: Border.all(
                color: AppColors.brandRed.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandRed.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: compact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ElectricalInfoBlock(
                        title: title,
                        subtitle: subtitle,
                        compact: true,
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: visualWidth,
                          child: _ElectricalVisualStack(assetPath: assetPath),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _ElectricalInfoBlock(
                          title: title,
                          subtitle: subtitle,
                          compact: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: visualWidth,
                        child: _ElectricalVisualStack(assetPath: assetPath),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ScenarioPreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScenarioPreviewCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.brandRedSoft,
          border: Border.all(color: AppColors.brandRed.withOpacity(0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.brandRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: AppColors.brandRed,
                    size: 22,
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
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandRedDeep,
                      AppColors.brandRedDark,
                      AppColors.brandRed,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandRed.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -28,
                      right: -20,
                      child: _SoftCircle(size: 110, opacity: 0.16),
                    ),
                    Positioned(
                      bottom: -34,
                      left: -26,
                      child: _SoftCircle(size: 120, opacity: 0.12),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.28)),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _lmText(context, 'm3_lm_123_3d_video_preview_holder'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

class _ElectricalInfoBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const _ElectricalInfoBlock({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 44 : 48,
          height: compact ? 44 : 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandRed, AppColors.brandRedDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandRed.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.view_in_ar_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 15.5 : 16.5,
            height: 1.15,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: compact ? 4 : 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _ElectricalInPageChip(),
      ],
    );
  }
}

class _ElectricalInPageChip extends StatelessWidget {
  _ElectricalInPageChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.brandRed.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_rounded, color: AppColors.brandRed, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _lmText(context, 'm3_lm_chip_tap_to_view_in_3d'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.brandRed,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElectricalVisualStack extends StatelessWidget {
  final String assetPath;

  const _ElectricalVisualStack({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 2,
            left: 14,
            right: 0,
            bottom: 14,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 16,
            left: 0,
            right: 20,
            bottom: 6,
            child: Transform.rotate(
              angle: 0.08,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.brandRed.withOpacity(0.12),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 20,
            left: 16,
            right: 8,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _ResolvedLearningImage(
                  imagePath: assetPath,
                  fallbackLabel: _lmText(
                    context,
                    'm3_lm_image_fallback_electrical_preview_asset',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedLearningImage extends StatelessWidget {
  final String imagePath;
  final String fallbackLabel;

  const _ResolvedLearningImage({
    required this.imagePath,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _ImageFallback(label: fallbackLabel),
      );
    }

    if (path.isNotEmpty) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _ImageFallback(label: fallbackLabel),
      );
    }

    return _ImageFallback(label: fallbackLabel);
  }
}

class _ImageFallback extends StatelessWidget {
  final String label;

  const _ImageFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxHeight < 106;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.brandRedSoft.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brandRed.withOpacity(0.16),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.electrical_services_rounded,
                  color: AppColors.brandRed,
                  size: small ? 26 : 34,
                ),
                if (!small) ...[
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.brandRed,
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// CONTENT WIDGETS
// =============================================================================
class _ReferenceSourceCard extends StatelessWidget {
  final String label;
  final String title;
  final String organization;
  final String sourceUrl;
  final IconData icon;
  final bool compact;

  const _ReferenceSourceCard({
    required this.label,
    required this.title,
    required this.organization,
    required this.sourceUrl,
    this.icon = Icons.verified_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final verticalPadding = compact ? 9.0 : 11.0;
    final iconSize = compact ? 30.0 : 34.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brandRed, size: compact ? 17 : 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$title • $organization',
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sourceUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
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

class _DidYouKnowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _DidYouKnowCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.brandRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.brandRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
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
        height: 1.55,
        color: Color(0xFF4B5563),
      ),
    );
  }
}

class _LessonIntroStrip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LessonIntroStrip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.45,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l,
                            style: const TextStyle(
                              height: 1.45,
                              color: Color(0xFF374151),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
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
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
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
  final VoidCallback? onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brandRedSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.brandRed),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
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

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

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
                        color: Color(0xFF374151),
                        fontSize: 13,
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

class _ResponsiveTileGrid extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveTileGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 430;
        if (!twoColumns) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String desc;

  const _InfoTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    height: 1.4,
                    color: Color(0xFF4B5563),
                    fontSize: 12.5,
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

class _CheckTile extends StatelessWidget {
  final String text;
  const _CheckTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.45,
                color: Color(0xFF374151),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyStepCard extends StatelessWidget {
  final String stepLabel;
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  const _EmergencyStepCard({
    required this.stepLabel,
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                stepLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
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
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              height: 1.45,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
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

// =============================================================================
// STYLED DIALOG
// =============================================================================
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
        child: SingleChildScrollView(
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
                      tooltip: 'Close',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shadowColor: iconColor.withOpacity(0.3),
                  ),
                  onPressed: onPressed,
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
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

// =============================================================================
// HEADER WIDGET
// =============================================================================
class _LearningAssessmentHeader extends StatelessWidget {
  final String sectionTitle;
  final String moduleLabel;
  final String moduleTitle;
  final int currentPage;
  final int totalPages;
  final double progress;
  final VoidCallback onClose;

  const _LearningAssessmentHeader({
    required this.sectionTitle,
    required this.moduleLabel,
    required this.moduleTitle,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final pageLabel = _lmText(context, 'm3_lm_ui_page_label');

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
                    Icons.menu_book_rounded,
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
// BACKGROUND
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
          child: _SoftCircle(size: 138, opacity: 0.17),
        ),
        const Positioned(
          top: 178,
          left: -42,
          child: _SoftCircle(size: 124, opacity: 0.13),
        ),
      ],
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.opacity});
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

