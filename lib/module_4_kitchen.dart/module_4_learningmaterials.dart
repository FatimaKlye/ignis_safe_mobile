import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'post_assess_instruction.dart';

const int _moduleNo = 4;
const String _learningMaterialsBucket = 'Learning Materials';
const String _module4KitchenModelAsset = 'assets/models/kitchennglb.glb';
const String _module4Page3VideoAsset = 'assets/kitchen_fire.mp4';

class AppColors {
  static const Color brandRed = Color(0xFFF59E0B);
  static const Color brandRedDark = Color(0xFFD97706);
  static const Color brandRedDeep = Color(0xFF92400E);
  static const Color brandRedLight = Color(0xFFFBBF24);
  static const Color brandRedSoft = Color(0xFFFFFBEB);
  static const Color background = Color(0xFFFFFBF2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFF7ED);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnRed = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFFDE68A);
  static const Color divider = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);
  static const Color primaryButton = brandRed;
  static const Color primaryButtonPressed = brandRedDark;
  static const Color secondaryButton = brandRedSoft;
  static const Color shadow = Color(0x1A000000);
}

class LearningMaterialKitchenPage extends StatefulWidget {
  const LearningMaterialKitchenPage({super.key});

  @override
  State<LearningMaterialKitchenPage> createState() =>
      _LearningMaterialKitchenPageState();
}

class _LearningMaterialKitchenPageState extends State<LearningMaterialKitchenPage> {
  static const accent = AppColors.brandRed;
  static const accent2 = AppColors.brandRedDark;

  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  int _pageIndex = 0;
  double _progress = 0.0;
  bool _canNext = false;
  bool _isSwitchingPage = false;
  bool _lastPageCompleted = false;
  bool _isLoading = true;
  bool _introShown = false;
  bool _unreadPromptVisible = false;
  String? _loadError;

  final List<Set<int>> _readSections = [<int>{}, <int>{}, <int>{}];
  _LearningMaterialData? _data;

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadLearningMaterials();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLearningMaterials() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final client = Supabase.instance.client;

      final materialRow = await client
          .from('learning_materials')
          .select('id,module_no,title,title_tl,subtitle,subtitle_tl,hero_asset')
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .maybeSingle();

      if (materialRow == null) {
        throw StateError('No active learning material found for Module $_moduleNo.');
      }

      final materialId = materialRow['id'] as String;

      final pageRows = await client
          .from('learning_material_pages')
          .select('id,module_no,page_no,page_key,title_en,title_tl')
          .eq('learning_material_id', materialId)
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('page_no', ascending: true);

      final blockRows = await client
          .from('learning_material_blocks')
          .select('id,page_id,module_no,page_no,block_no,block_key,block_type,text_en,text_tl,metadata,source_title,source_organization,source_url')
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('page_no', ascending: true)
          .order('block_no', ascending: true);

      final textRows = await client
          .from('learning_material_texts')
          .select('text_key,text_en,text_tl')
          .eq('learning_material_id', materialId)
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('text_order', ascending: true);

      final mediaRows = await client
          .from('learning_material_media_assets')
          .select('asset_key,asset_path,public_url,asset_type,alt_en,alt_tl')
          .eq('learning_material_id', materialId)
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (!mounted) return;
      setState(() {
        _data = _LearningMaterialData.fromRows(
          materialRow: Map<String, dynamic>.from(materialRow),
          pageRows: List<Map<String, dynamic>>.from(
            (pageRows as List).map((row) => Map<String, dynamic>.from(row as Map)),
          ),
          blockRows: List<Map<String, dynamic>>.from(
            (blockRows as List).map((row) => Map<String, dynamic>.from(row as Map)),
          ),
          textRows: List<Map<String, dynamic>>.from(
            (textRows as List).map((row) => Map<String, dynamic>.from(row as Map)),
          ),
          mediaRows: List<Map<String, dynamic>>.from(
            (mediaRows as List).map((row) => Map<String, dynamic>.from(row as Map)),
          ),
        );
        _isLoading = false;
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

  String _uiText(String key, {Map<String, String> values = const {}}) {
    var text = _data?.texts[key]?.value(_isTl) ?? key;
    values.forEach((placeholder, value) {
      text = text.replaceAll('{$placeholder}', value);
    });
    return text;
  }

  String _pageTitle(int pageNo) => _data?.pagesByNo[pageNo]?.value(_isTl) ?? '';
  _LearningBlockData? _block(String key) => _data?.blocksByKey[key];

  String _blockTitle(String key) => _block(key)?.value(_isTl) ?? '';
  String _mediaPath(String? keyOrPath) {
    final raw = keyOrPath?.trim() ?? '';
    if (raw.isEmpty) return '';
    final asset = _data?.mediaByKey[raw];
    if (asset != null) return asset.resolvedPath;
    return raw;
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _isSwitchingPage) return;

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

  void _resetForNewPage() {
    setState(() {
      _isSwitchingPage = true;
      _progress = 0.0;
      _canNext = false;
      _lastPageCompleted = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
      setState(() => _isSwitchingPage = false);
      _onScroll();
    });
  }

  int _requiredSectionCountForPage(int pageIndex) {
    switch (pageIndex) {
      case 0:
      case 1:
      case 2:
        return 4;
      default:
        return 0;
    }
  }

  bool _hasReadAllRequiredSections(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _readSections.length) return false;
    return _readSections[pageIndex].length >= _requiredSectionCountForPage(pageIndex);
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

  void _showUnreadSectionsPopup() {
    if (_unreadPromptVisible) return;
    _unreadPromptVisible = true;

    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.brandRed,
        title: _uiText('dialog_unread_title'),
        body: _uiText('dialog_unread_body'),
        buttonLabel: _uiText('dialog_unread_button'),
        onPressed: () => Navigator.pop(context),
      ),
    ).then((_) => _unreadPromptVisible = false);
  }

  void _showIntroPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.auto_stories_rounded,
        iconColor: accent,
        title: _uiText('dialog_intro_title'),
        body: _uiText('dialog_intro_body'),
        buttonLabel: _uiText('dialog_intro_button'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showPageCompletePopup(int pageIndex, VoidCallback onContinue) {
    final titleKey = pageIndex == 0
        ? 'dialog_page_1_complete_title'
        : 'dialog_page_2_complete_title';
    final bodyKey = pageIndex == 0
        ? 'dialog_page_1_complete_body'
        : 'dialog_page_2_complete_body';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: _uiText(titleKey),
        body: _uiText(bodyKey),
        buttonLabel: _uiText('dialog_continue_button'),
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
        title: _uiText('dialog_final_title'),
        body: _uiText('dialog_final_body'),
        buttonLabel: _uiText('dialog_final_button'),
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAssessmentIntroPage2()),
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
        buttonLabel: _uiText('dialog_ok_button'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showDoThisNowPopup() {
    _showInfoPopup(
      title: _uiText('popup_pan_fire_title'),
      icon: Icons.local_fire_department_rounded,
      color: AppColors.error,
      message: _uiText('popup_pan_fire_steps'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_loadError != null || _data == null) return _buildErrorState();

    final isLast = _pageIndex == 2;
    final nextEnabled = _hasReadAllRequiredSections(_pageIndex);

    return Scaffold(
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
                    sectionTitle: _uiText('header_section_title'),
                    moduleLabel: _uiText('header_module_label'),
                    moduleTitle: _data!.title.value(_isTl),
                    currentPage: _pageIndex + 1,
                    totalPages: 3,
                    progress: _progress,
                    pageLabel: _uiText('header_page_label'),
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
                      _pageWrap(_page1OverviewAndTypes()),
                      _pageWrap(_page2CausesAndPrevention()),
                      _pageWrap(_page3EmergencyResponse()),
                    ],
                  ),
                ),
                _BottomNavBar(
                  pageIndex: _pageIndex,
                  isLast: isLast,
                  nextEnabled: nextEnabled,
                  backLabel: _uiText('nav_back'),
                  nextLabel: isLast
                      ? _uiText('nav_start_post_test')
                      : _uiText('nav_next'),
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

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _LMGradientBackdrop(),
          SafeArea(
            child: Center(
              child: _LoadingContentCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LMGradientBackdrop(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 34),
                      const SizedBox(height: 10),
                      const Text(
                        'Error loading learning materials',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError ?? 'No content found.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _loadLearningMaterials,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: AppColors.brandRed.withOpacity(0.08), blurRadius: 28, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _page1OverviewAndTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.restaurant_rounded,
          accent1: accent,
          accent2: accent2,
          pageTag: _uiText('page_1_tag'),
          title: _pageTitle(1),
          subtitle: _block('p1_banner')?.metaText('subtitle', _isTl) ?? '',
        ),
        const SizedBox(height: 16),
        _referenceSource('p1_reference'),
        const SizedBox(height: 14),
        _heroCard('p1_hero'),
        const SizedBox(height: 14),
        _lesson(
          blockKey: 'p1_section_1',
          sectionIndex: 0,
          pageIndex: 0,
          icon: Icons.info_outline_rounded,
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p1_section_2',
          sectionIndex: 1,
          pageIndex: 0,
          icon: Icons.local_fire_department_rounded,
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p1_section_3',
          sectionIndex: 2,
          pageIndex: 0,
          icon: Icons.warning_rounded,
          accentColor: AppColors.error,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p1_section_4',
          sectionIndex: 3,
          pageIndex: 0,
          icon: Icons.touch_app_rounded,
          accentColor: accent2,
        ),
        const SizedBox(height: 16),
        _readingBadge(0),
      ],
    );
  }

  Widget _page2CausesAndPrevention() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.shield_rounded,
          accent1: accent2,
          accent2: accent,
          pageTag: _uiText('page_2_tag'),
          title: _pageTitle(2),
          subtitle: _block('p2_banner')?.metaText('subtitle', _isTl) ?? '',
        ),
        const SizedBox(height: 16),
        _referenceSource('p2_reference'),
        const SizedBox(height: 14),
        _lesson(
          blockKey: 'p2_section_1',
          sectionIndex: 0,
          pageIndex: 1,
          icon: Icons.kitchen_rounded,
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p2_section_2',
          sectionIndex: 1,
          pageIndex: 1,
          icon: Icons.cleaning_services_rounded,
          accentColor: accent2,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p2_section_3',
          sectionIndex: 2,
          pageIndex: 1,
          icon: Icons.power_settings_new_rounded,
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p2_section_4',
          sectionIndex: 3,
          pageIndex: 1,
          icon: Icons.block_rounded,
          accentColor: AppColors.error,
        ),
        const SizedBox(height: 16),
        _readingBadge(1),
      ],
    );
  }

  Widget _page3EmergencyResponse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.emergency_rounded,
          accent1: AppColors.error,
          accent2: accent,
          pageTag: _uiText('page_3_tag'),
          title: _pageTitle(3),
          subtitle: _block('p3_banner')?.metaText('subtitle', _isTl) ?? '',
        ),
        const SizedBox(height: 16),
        _referenceSource('p3_reference'),
        const SizedBox(height: 14),
        _page3VideoSourceCard(),
        const SizedBox(height: 12),
        _page3VideoCard(),
        const SizedBox(height: 14),
        _lesson(
          blockKey: 'p3_section_1',
          sectionIndex: 0,
          pageIndex: 2,
          icon: Icons.checklist_rounded,
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p3_section_2',
          sectionIndex: 1,
          pageIndex: 2,
          icon: Icons.water_drop_rounded,
          accentColor: AppColors.error,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p3_section_3',
          sectionIndex: 2,
          pageIndex: 2,
          icon: Icons.directions_run_rounded,
          accentColor: accent2,
        ),
        const SizedBox(height: 12),
        _lesson(
          blockKey: 'p3_section_4',
          sectionIndex: 3,
          pageIndex: 2,
          icon: Icons.view_in_ar_rounded,
          accentColor: accent,
        ),
        const SizedBox(height: 16),
        _readingBadge(2),
      ],
    );
  }

  Widget _referenceSource(String blockKey) {
    final block = _block(blockKey);
    if (block == null) return const SizedBox.shrink();
    return _ReferenceSourceCard(
      label: block.value(_isTl),
      title: block.sourceTitle,
      organization: block.sourceOrganization,
      sourceUrl: block.sourceUrl,
      icon: Icons.verified_rounded,
      compact: true,
    );
  }

  Widget _page3VideoCard() {
    return _LearningMaterialVideoCard(
      videoAssetPath: _module4Page3VideoAsset,
      title: _isTl ? 'Video na Gabay' : 'Video Guide',
      description: _isTl
          ? 'Panoorin ang maikling video bilang karagdagang gabay bago tapusin ang bahaging ito.'
          : 'Watch the short video as an additional guide before completing this section.',
      helperText: _isTl
          ? 'I-tap ang video para i-play o i-pause.'
          : 'Tap the video to play or pause.',
    );
  }

  Widget _page3VideoSourceCard() {
    return const _KitchenVideoSourceCard(
      platform: 'YouTube',
      title: 'San José Fire Department – Fire Safety in the Kitchen',
      purpose:
          'Supports the kitchen fire safety lesson by showing basic fire prevention reminders and safe response actions during a kitchen fire.',
    );
  }

  Widget _heroCard(String blockKey) {
    final block = _block(blockKey);
    if (block == null) return const SizedBox.shrink();

    return _KitchenFire3DCardHolder(
      assetPath: _module4KitchenModelAsset,
      title: block.value(_isTl),
      subtitle: block.metaText('subtitle', _isTl),
      chipLabel: _uiText('hero_chip_label'),
    );
  }

  Widget _lesson({
    required String blockKey,
    required int sectionIndex,
    required int pageIndex,
    required IconData icon,
    required Color accentColor,
  }) {
    final block = _block(blockKey);
    if (block == null) return const SizedBox.shrink();

    return _ExpandableLesson(
      sectionIndex: sectionIndex,
      pageIndex: pageIndex,
      readSections: _readSections,
      onRead: (i) => setState(() => _readSections[pageIndex].add(i)),
      icon: icon,
      accentColor: accentColor,
      title: block.value(_isTl),
      readLabel: _uiText('section_read_badge'),
      child: _lessonContent(block),
    );
  }

  Widget _lessonContent(_LearningBlockData block) {
    final kind = block.metaString('content_kind');

    if (kind == 'bullets') {
      return _Bullets(items: block.metaList('bullets', _isTl));
    }

    if (kind == 'image_row') {
      final imageKey = block.metaString('image_asset_key');
      return LayoutBuilder(
        builder: (context, constraints) {
          final useColumn = !constraints.maxWidth.isFinite || constraints.maxWidth < 220;
          final imageBox = _ImageBox(
            asset: _mediaPath(imageKey),
            c1: accent,
            c2: accent2,
            fallbackIcon: Icons.restaurant_rounded,
          );
          final secondaryText = _BodyText(block.metaText('body_secondary', _isTl));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(block.metaText('body', _isTl)),
              const SizedBox(height: 12),
              if (useColumn) ...[
                Align(alignment: Alignment.center, child: imageBox),
                const SizedBox(height: 10),
                secondaryText,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageBox,
                    const SizedBox(width: 14),
                    Expanded(child: secondaryText),
                  ],
                ),
            ],
          );
        },
      );
    }

    if (kind == 'body_action') {
      final actionKey = block.metaString('action_key');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText(block.metaText('body', _isTl)),
          const SizedBox(height: 10),
          _ActionPill(
            icon: actionKey == 'pan_fire_steps'
                ? Icons.local_fire_department_rounded
                : Icons.play_circle_rounded,
            label: block.metaText('action_label', _isTl),
            onTap: actionKey == 'pan_fire_steps' ? _showDoThisNowPopup : null,
          ),
        ],
      );
    }

    return _BodyText(block.metaText('body', _isTl));
  }

  Widget _readingBadge(int pageIndex) {
    return _ReadingProgressBadge(
      readCount: _readSections[pageIndex].length,
      totalCount: _requiredSectionCountForPage(pageIndex),
      allSectionsReadLabel: _uiText('reading_all_sections_read'),
      sectionsReadTemplate: _uiText(
        'reading_sections_read_template',
        values: {
          'read': _readSections[pageIndex].length.toString(),
          'total': _requiredSectionCountForPage(pageIndex).toString(),
        },
      ),
      helperLabel: _uiText('reading_helper_label'),
    );
  }
}

class _LocalizedText {
  final String en;
  final String tl;

  const _LocalizedText({required this.en, required this.tl});

  String value(bool isTl) {
    final selected = isTl && tl.trim().isNotEmpty ? tl : en;
    return selected.trim();
  }
}

class _LearningMaterialData {
  final String id;
  final _LocalizedText title;
  final String heroAsset;
  final Map<int, _LearningPageData> pagesByNo;
  final Map<String, _LearningBlockData> blocksByKey;
  final Map<String, _LocalizedText> texts;
  final Map<String, _LearningMediaAssetData> mediaByKey;

  const _LearningMaterialData({
    required this.id,
    required this.title,
    required this.heroAsset,
    required this.pagesByNo,
    required this.blocksByKey,
    required this.texts,
    required this.mediaByKey,
  });

  factory _LearningMaterialData.fromRows({
    required Map<String, dynamic> materialRow,
    required List<Map<String, dynamic>> pageRows,
    required List<Map<String, dynamic>> blockRows,
    required List<Map<String, dynamic>> textRows,
    required List<Map<String, dynamic>> mediaRows,
  }) {
    return _LearningMaterialData(
      id: materialRow['id']?.toString() ?? '',
      title: _LocalizedText(
        en: materialRow['title']?.toString() ?? '',
        tl: materialRow['title_tl']?.toString() ?? '',
      ),
      heroAsset: materialRow['hero_asset']?.toString() ?? '',
      pagesByNo: {
        for (final row in pageRows)
          (row['page_no'] as num).toInt(): _LearningPageData.fromRow(row),
      },
      blocksByKey: {
        for (final row in blockRows)
          row['block_key'].toString(): _LearningBlockData.fromRow(row),
      },
      texts: {
        for (final row in textRows)
          row['text_key'].toString(): _LocalizedText(
            en: row['text_en']?.toString() ?? '',
            tl: row['text_tl']?.toString() ?? '',
          ),
      },
      mediaByKey: {
        for (final row in mediaRows)
          row['asset_key'].toString(): _LearningMediaAssetData.fromRow(row),
      },
    );
  }
}

class _LearningPageData extends _LocalizedText {
  final int pageNo;
  final String pageKey;

  const _LearningPageData({
    required this.pageNo,
    required this.pageKey,
    required super.en,
    required super.tl,
  });

  factory _LearningPageData.fromRow(Map<String, dynamic> row) {
    return _LearningPageData(
      pageNo: (row['page_no'] as num).toInt(),
      pageKey: row['page_key']?.toString() ?? '',
      en: row['title_en']?.toString() ?? '',
      tl: row['title_tl']?.toString() ?? '',
    );
  }
}

class _LearningBlockData extends _LocalizedText {
  final int pageNo;
  final int blockNo;
  final String blockKey;
  final String blockType;
  final Map<String, dynamic> metadata;
  final String sourceTitle;
  final String sourceOrganization;
  final String sourceUrl;

  const _LearningBlockData({
    required this.pageNo,
    required this.blockNo,
    required this.blockKey,
    required this.blockType,
    required super.en,
    required super.tl,
    required this.metadata,
    required this.sourceTitle,
    required this.sourceOrganization,
    required this.sourceUrl,
  });

  factory _LearningBlockData.fromRow(Map<String, dynamic> row) {
    final rawMetadata = row['metadata'];
    return _LearningBlockData(
      pageNo: (row['page_no'] as num).toInt(),
      blockNo: (row['block_no'] as num).toInt(),
      blockKey: row['block_key']?.toString() ?? '',
      blockType: row['block_type']?.toString() ?? '',
      en: row['text_en']?.toString() ?? '',
      tl: row['text_tl']?.toString() ?? '',
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : <String, dynamic>{},
      sourceTitle: row['source_title']?.toString() ?? '',
      sourceOrganization: row['source_organization']?.toString() ?? '',
      sourceUrl: row['source_url']?.toString() ?? '',
    );
  }

  String metaString(String key) => metadata[key]?.toString().trim() ?? '';

  String metaText(String key, bool isTl) {
    final tlKey = '${key}_tl';
    final enKey = '${key}_en';
    final tlValue = metadata[tlKey]?.toString().trim() ?? '';
    final enValue = metadata[enKey]?.toString().trim() ?? '';
    if (isTl && tlValue.isNotEmpty) return tlValue;
    return enValue;
  }

  List<String> metaList(String key, bool isTl) {
    final selectedKey = isTl ? '${key}_tl' : '${key}_en';
    final fallbackKey = '${key}_en';
    final selected = metadata[selectedKey];
    final fallback = metadata[fallbackKey];

    if (selected is List && selected.isNotEmpty) {
      return selected.map((item) => item.toString()).toList();
    }
    if (fallback is List) {
      return fallback.map((item) => item.toString()).toList();
    }
    return const <String>[];
  }
}

class _LearningMediaAssetData {
  final String assetKey;
  final String assetPath;
  final String publicUrl;

  const _LearningMediaAssetData({
    required this.assetKey,
    required this.assetPath,
    required this.publicUrl,
  });

  String get resolvedPath => publicUrl.trim().isNotEmpty ? publicUrl.trim() : assetPath.trim();

  factory _LearningMediaAssetData.fromRow(Map<String, dynamic> row) {
    return _LearningMediaAssetData(
      assetKey: row['asset_key']?.toString() ?? '',
      assetPath: row['asset_path']?.toString() ?? '',
      publicUrl: row['public_url']?.toString() ?? '',
    );
  }
}

class _LoadingContentCard extends StatelessWidget {
  const _LoadingContentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(22),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.brandRed),
          SizedBox(height: 14),
          Text(
            'Loading learning materials...',
            textAlign: TextAlign.center,
            style: TextStyle(
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

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ', style: TextStyle(fontWeight: FontWeight.w900)),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF4B5563)))),
          ],
        ),
      )).toList(),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brandRedSoft.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.brandRed),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int pageIndex;
  final bool isLast;
  final bool nextEnabled;
  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNavBar({
    required this.pageIndex,
    required this.isLast,
    required this.nextEnabled,
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext ctx) {
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
                        backLabel,
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
    );
  }
}

class _ReadingProgressBadge extends StatelessWidget {
  final int readCount;
  final int totalCount;
  final String allSectionsReadLabel;
  final String sectionsReadTemplate;
  final String helperLabel;

  const _ReadingProgressBadge({
    required this.readCount,
    required this.totalCount,
    required this.allSectionsReadLabel,
    required this.sectionsReadTemplate,
    required this.helperLabel,
  });

  @override
  Widget build(BuildContext ctx) {
    final done = readCount >= totalCount;
    final color = done ? AppColors.success : AppColors.brandRed;
    final label = done ? allSectionsReadLabel : sectionsReadTemplate;

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
            flex: 3,
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
              flex: 1,
              fit: FlexFit.loose,
              child: Text(
                helperLabel,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
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

class _ExpandableLesson extends StatefulWidget {
  final int sectionIndex;
  final int pageIndex;
  final List<Set<int>> readSections;
  final ValueChanged<int> onRead;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String readLabel;
  final Widget child;

  const _ExpandableLesson({
    required this.sectionIndex,
    required this.pageIndex,
    required this.readSections,
    required this.onRead,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.readLabel,
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
                    Flexible(
                      fit: FlexFit.loose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          widget.readLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
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
        color: AppColors.brandRedSoft.withOpacity(0.62),
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
                  "$title • $organization",
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


class _KitchenVideoSourceCard extends StatelessWidget {
  final String platform;
  final String title;
  final String purpose;

  const _KitchenVideoSourceCard({
    required this.platform,
    required this.title,
    required this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_display_rounded,
              color: AppColors.brandRed,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source: $platform',
                  maxLines: 1,
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
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  purpose,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _KitchenFire3DCardHolder extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  final String chipLabel;

  const _KitchenFire3DCardHolder({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.chipLabel,
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
          colors: [Color(0xFFFFFBF2), Color(0xFFFFF1D6)],
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
                    chipLabel,
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
          _PageOneKitchenFire3DPreview(assetPath: assetPath, chipLabel: chipLabel),
        ],
      ),
    );
  }
}

class _PageOneKitchenFire3DPreview extends StatelessWidget {
  final String assetPath;
  final String chipLabel;

  const _PageOneKitchenFire3DPreview({
    required this.assetPath,
    required this.chipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth * 1.82)
            .clamp(580.0, 780.0)
            .toDouble();
        final modelPath = _resolveKitchenModelPath(assetPath);
        final isTl = Localizations.localeOf(context).languageCode
            .toLowerCase()
            .startsWith('tl');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTl ? '3D Model Preview' : '3D Model Preview',
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
              chipLabel,
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
                  color: const Color(0xFFFFF1D6),
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
                              Colors.white.withOpacity(0.54),
                              AppColors.brandRedSoft.withOpacity(0.62),
                              AppColors.brandRed.withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -42,
                      top: -44,
                      child: _KitchenFireSoftGlowBlob(
                        size: 150,
                        color: AppColors.brandRed.withOpacity(0.11),
                      ),
                    ),
                    Positioned(
                      right: -46,
                      bottom: -52,
                      child: _KitchenFireSoftGlowBlob(
                        size: 170,
                        color: AppColors.warning.withOpacity(0.15),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _KitchenFireGridPainter(
                          color: AppColors.brandRed.withOpacity(0.045),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _KitchenFireViewerBadge(
                        icon: Icons.view_in_ar_rounded,
                        label: '3D Preview',
                        color: AppColors.brandRed,
                      ),
                    ),
                    Positioned.fill(
                      top: 24,
                      bottom: 8,
                      child: _AnimatedKitchenFireModelViewer(modelPath: modelPath),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Stack(
                          children: [
                            Positioned(
                              top: previewHeight * 0.12,
                              left: 16,
                              child: const _KitchenFireModelLabel('Kitchen\nArea'),
                            ),
                            Positioned(
                              top: previewHeight * 0.18,
                              right: 16,
                              child: const _KitchenFireModelLabel('Cooking\nZone'),
                            ),
                            Positioned(
                              top: previewHeight * 0.42,
                              left: 12,
                              child: const _KitchenFireModelLabel('Heat\nSource'),
                            ),
                            Positioned(
                              top: previewHeight * 0.50,
                              right: 12,
                              child: const _KitchenFireModelLabel('Fire\nRisk'),
                            ),
                            Positioned(
                              bottom: previewHeight * 0.18,
                              left: 14,
                              child: const _KitchenFireModelLabel('Safe\nDistance'),
                            ),
                            Positioned(
                              bottom: previewHeight * 0.10,
                              right: 14,
                              child: const _KitchenFireModelLabel('Kitchen\nAssets'),
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
                      isTl
                          ? 'I-drag para i-rotate. I-pinch para i-zoom.'
                          : 'Drag to rotate. Pinch to zoom.',
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

  String _resolveKitchenModelPath(String rawPath) {
    final path = rawPath.trim();
    if (path.isNotEmpty && path.toLowerCase().endsWith('.glb')) {
      return path;
    }
    return _module4KitchenModelAsset;
  }
}

class _AnimatedKitchenFireModelViewer extends StatefulWidget {
  final String modelPath;

  const _AnimatedKitchenFireModelViewer({required this.modelPath});

  @override
  State<_AnimatedKitchenFireModelViewer> createState() =>
      _AnimatedKitchenFireModelViewerState();
}

class _AnimatedKitchenFireModelViewerState
    extends State<_AnimatedKitchenFireModelViewer>
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
            alt: 'Kitchen fire 3D model preview',
            backgroundColor: Colors.transparent,
            cameraControls: true,
            autoRotate: true,
            autoRotateDelay: 0,
            rotationPerSecond: '22deg',
            disableZoom: false,
            cameraOrbit: '35deg 68deg 4.8m',
            fieldOfView: '28deg',
            minCameraOrbit: 'auto auto 3.2m',
            maxCameraOrbit: 'auto auto 7.2m',
            shadowIntensity: 0.55,
            exposure: 1.05,
          ),
        );
      },
    );
  }
}

class _KitchenFireModelLabel extends StatelessWidget {
  final String label;

  const _KitchenFireModelLabel(this.label);

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

class _KitchenFireViewerBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _KitchenFireViewerBadge({
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

class _KitchenFireSoftGlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _KitchenFireSoftGlowBlob({
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

class _KitchenFireGridPainter extends CustomPainter {
  final Color color;

  const _KitchenFireGridPainter({required this.color});

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
  bool shouldRepaint(covariant _KitchenFireGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}


class _LearningMaterialVideoCard extends StatelessWidget {
  final String videoAssetPath;
  final String title;
  final String description;
  final String helperText;

  const _LearningMaterialVideoCard({
    required this.videoAssetPath,
    required this.title,
    required this.description,
    required this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brandRed, AppColors.brandRedDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandRed.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _InlineAssetVideoPlayer(source: videoAssetPath),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandRedSoft.withOpacity(0.70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brandRed.withOpacity(0.13)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.brandRed,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    helperText,
                    style: const TextStyle(
                      color: AppColors.brandRedDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
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
      final source = widget.source.trim();
      final isNetwork = source.startsWith('http://') || source.startsWith('https://');
      final controller = isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(source))
          : VideoPlayerController.asset(source);

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
      return const _VideoPreviewFallback(isLoading: true);
    }

    final controller = _controller;
    if (_hasError || controller == null || !controller.value.isInitialized) {
      return const _VideoPreviewFallback(hasError: true);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: AppColors.brandRedSoft.withOpacity(0.50),
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
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.44),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
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

class _VideoPreviewFallback extends StatelessWidget {
  final bool isLoading;
  final bool hasError;

  const _VideoPreviewFallback({
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode
        .toLowerCase()
        .startsWith('tl');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandRed.withOpacity(0.12),
            AppColors.warning.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.14)),
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
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.smart_display_rounded,
                color: AppColors.brandRed,
                size: 38,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                hasError
                    ? (isTl ? 'Hindi ma-load ang video.' : 'Video could not be loaded.')
                    : (isTl ? 'Naglo-load ang video...' : 'Loading video...'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  height: 1.3,
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
  final IconData fallbackIcon;

  const _ImageBox({
    required this.asset,
    required this.c1,
    required this.c2,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1.withOpacity(0.12), c2.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: c1.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: _MaterialImage(
        assetPath: asset,
        fit: BoxFit.contain,
        fallbackIcon: fallbackIcon,
        fallbackColor: c1,
      ),
    );
  }
}

class _MaterialImage extends StatelessWidget {
  final String assetPath;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  const _MaterialImage({
    required this.assetPath,
    required this.fit,
    required this.fallbackIcon,
    this.fallbackColor,
  });

  bool get _isNetworkPath =>
      assetPath.startsWith('http://') || assetPath.startsWith('https://');

  bool get _isLocalAsset => assetPath.startsWith('assets/');

  String get _storagePath {
    final trimmed = assetPath.trim();
    if (trimmed.startsWith('/')) return trimmed.substring(1);
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (assetPath.trim().isEmpty) return _fallback();

    if (_isNetworkPath) {
      return Image.network(
        assetPath,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (_isLocalAsset) {
      return Image.asset(
        assetPath,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    final storageUrl = Supabase.instance.client.storage
        .from(_learningMaterialsBucket)
        .getPublicUrl(_storagePath);

    return Image.network(
      storageUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
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
        child: Icon(
          fallbackIcon,
          color: fallbackColor ?? AppColors.brandRed,
          size: 34,
        ),
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
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
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
        height: 1.55,
        color: Color(0xFF4B5563),
      ),
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
      child: SingleChildScrollView(
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

class _LearningAssessmentHeader extends StatelessWidget {
  final String sectionTitle;
  final String moduleLabel;
  final String moduleTitle;
  final int currentPage;
  final int totalPages;
  final double progress;
  final String pageLabel;
  final VoidCallback onClose;

  const _LearningAssessmentHeader({
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
                  color: AppColors.textOnRed.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textOnRed.withValues(alpha: 0.24),
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
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandRedLight,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandRed.withValues(alpha: 0.24),
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
                    Flexible(
                      child: Text(
                        moduleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textOnRed,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                moduleTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textOnRed.withValues(alpha: 0.88),
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
            backgroundColor: AppColors.textOnRed.withValues(alpha: 0.22),
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
                color: AppColors.textOnRed.withValues(alpha: 0.76),
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
                        : AppColors.textOnRed.withValues(alpha: 0.34),
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

