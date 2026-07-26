import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:video_player/video_player.dart';
import '../widgets/reliable_video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'module_progression_service.dart';
import 'post_assess_instruction.dart';

// ============================================================================
// APP COLORS — Module 5 Purple/Violet Palette (DO NOT CHANGE)
// ============================================================================
class AppColors {
  static const Color purple50  = Color(0xFFF5F3FF);
  static const Color purple100 = Color(0xFFEDE9FE);
  static const Color purple200 = Color(0xFFDDD6FE);
  static const Color purple300 = Color(0xFFC4B5FD);
  static const Color purple400 = Color(0xFFA78BFA);
  static const Color purple500 = Color(0xFF8B5CF6);
  static const Color purple600 = Color(0xFF7C3AED);
  static const Color purple700 = Color(0xFF6D28D9);
  static const Color purple800 = Color(0xFF5B21B6);
  static const Color purple900 = Color(0xFF4C1D95);
  static const Color purple950 = Color(0xFF2E1065);

  static const LinearGradient module5Gradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFF4C1D95)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color brandRed      = Color(0xFF7C3AED);
  static const Color brandRedDark  = Color(0xFF5B21B6);
  static const Color brandRedDeep  = Color(0xFF2E1065);
  static const Color brandRedLight = Color(0xFFA78BFA);
  static const Color brandRedSoft  = Color(0xFFEDE9FE);

  static const Color background  = Color(0xFFF5F3FF);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEDE9FE);

  static const Color textPrimary   = Color(0xFF2E1065);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);
  static const Color textOnRed     = Color(0xFFFFFFFF);

  static const Color border  = Color(0xFFDDD6FE);
  static const Color divider = Color(0xFFEDE9FE);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFD32F2F);
  static const Color info    = Color(0xFF2563EB);

  static const Color primaryButton        = Color(0xFF7C3AED);
  static const Color primaryButtonPressed = Color(0xFF5B21B6);
  static const Color secondaryButton      = Color(0xFFEDE9FE);
  static const Color shadow               = Color(0x1A000000);
}

// ============================================================================
// DATABASE CONTENT HELPERS — Module 5
// ============================================================================
const int _moduleNo = 5;
const String _learningMaterialsBucketName = 'Learning Materials';
const String _module5BuildingModelAssetKey = 'model_asset_key';
const String _module5BuildingModelAsset = 'assets/models/buildingfinal.glb';
const String _module5GuideVideoAsset = 'assets/module5.mp4';
const String _module5GuideVideoSourceUrl = 'https://www.youtube.com/watch?v=AtDQB2UsbLc';

class _SourceReference {
  const _SourceReference({
    required this.organization,
    required this.url,
  });

  final String organization;
  final String url;
}

class _Module5LearningMaterialStore {
  static Map<String, String> textEn = <String, String>{};
  static Map<String, String> textTl = <String, String>{};
  static Map<String, _SourceReference> sources =
      <String, _SourceReference>{};
  static String guideVideoPath = '';
  static String buildingModelPath = '';

  static void update({
    required Map<String, String> en,
    required Map<String, String> tl,
    required Map<String, _SourceReference> sourceRefs,
    required String guideVideoAssetPath,
    required String buildingModelAssetPath,
  }) {
    textEn = Map<String, String>.unmodifiable(en);
    textTl = Map<String, String>.unmodifiable(tl);
    sources = Map<String, _SourceReference>.unmodifiable(sourceRefs);
    guideVideoPath = guideVideoAssetPath;
    buildingModelPath = buildingModelAssetPath;
  }
}

String _dbText(
  BuildContext context,
  String key, {
  Map<String, String>? params,
}) {
  final isTl = Localizations.localeOf(context).languageCode == 'tl';
  var value = isTl
      ? (_Module5LearningMaterialStore.textTl[key] ??
          _Module5LearningMaterialStore.textEn[key])
      : _Module5LearningMaterialStore.textEn[key];

  value ??= key;

  if (params != null) {
    params.forEach((placeholder, replacement) {
      value = value!
          .replaceAll('{$placeholder}', replacement)
          .replaceAll('\$$placeholder', replacement);
    });
  }

  return value!;
}


String _dbTextOr(
  BuildContext context,
  String key, {
  required String enFallback,
  required String tlFallback,
  Map<String, String>? params,
}) {
  final isTl = Localizations.localeOf(context).languageCode == 'tl';
  var value = isTl
      ? (_Module5LearningMaterialStore.textTl[key] ??
          _Module5LearningMaterialStore.textEn[key])
      : _Module5LearningMaterialStore.textEn[key];

  if (value == null || value.trim().isEmpty || value.trim() == key) {
    value = isTl ? tlFallback : enFallback;
  }

  if (params != null) {
    params.forEach((placeholder, replacement) {
      value = value!
          .replaceAll('{$placeholder}', replacement)
          .replaceAll('\$$placeholder', replacement);
    });
  }

  return value!;
}

String _sourceOrganization(String sourceKey) {
  return _Module5LearningMaterialStore.sources[sourceKey]?.organization ?? '';
}

String _sourceUrl(String sourceKey) {
  return _Module5LearningMaterialStore.sources[sourceKey]?.url ?? '';
}

String _guideVideoPath() {
  final path = _Module5LearningMaterialStore.guideVideoPath;
  return path.isNotEmpty ? path : _module5GuideVideoAsset;
}

String _resolveGuideVideoSource(String assetPath, String publicUrl) {
  final path = assetPath.trim();
  if (path.startsWith('assets/')) return path;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  final directUrl = publicUrl.trim();
  if (directUrl.isNotEmpty) return directUrl;
  if (path.isEmpty) return _module5GuideVideoAsset;

  final storagePath = path.startsWith('/') ? path.substring(1) : path;
  return Supabase.instance.client.storage
      .from(_learningMaterialsBucketName)
      .getPublicUrl(storagePath);
}

String _buildingModelPath() {
  final path = _Module5LearningMaterialStore.buildingModelPath;
  return path.isNotEmpty ? path : _module5BuildingModelAsset;
}

/// Converts a stored `model_asset_key` filename or storage path into a
/// playable source: bundled asset paths and already-absolute URLs are
/// returned as-is, anything else is resolved to a Supabase public URL.
String _resolveModelStorageUrl(String rawPath) {
  final path = rawPath.trim();
  if (path.isEmpty) return '';
  if (path.startsWith('assets/')) return path;

  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) return path;

  return Supabase.instance.client.storage
      .from(_learningMaterialsBucketName)
      .getPublicUrl(path);
}

// ============================================================================
// MAIN PAGE
// ============================================================================
class LearningMaterialTenementPage extends StatefulWidget {
  const LearningMaterialTenementPage({super.key});

  @override
  State<LearningMaterialTenementPage> createState() =>
      _LearningMaterialTenementPageState();
}

/// Compatibility wrapper so older routes that call BuildingPage still work.
class LearningMaterialBuildingPage extends StatelessWidget {
  const LearningMaterialBuildingPage({super.key});

  @override
  Widget build(BuildContext context) => const LearningMaterialTenementPage();
}

class _LearningMaterialTenementPageState
    extends State<LearningMaterialTenementPage> {
  static const accent  = AppColors.brandRed;
  static const accent2 = AppColors.brandRedDark;

  final PageController   _pageCtrl  = PageController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<Set<int>> _readSections = [<int>{}, <int>{}, <int>{}];

  int    _pageIndex        = 0;
  double _progress         = 0.0;
  bool   _canNext          = false;
  bool   _isSwitchingPage  = false;
  bool   _lastPageCompleted = false;
  bool   _introShown       = false;
  bool   _unreadPromptVisible = false;
  bool   _isLoadingContent = true;
  String? _contentError;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadLearningMaterialContent();
  }

  Future<void> _loadLearningMaterialContent() async {
    setState(() {
      _isLoadingContent = true;
      _contentError = null;
    });

    try {
      final progressionState =
          await ModuleProgressionService().getState(moduleNo: _moduleNo);

      if (!progressionState.hasValidPreTest) {
        if (!mounted) return;
        setState(() {
          _isLoadingContent = false;
          _contentError = _dbTextOr(
            context,
            'progression.locked_content_error',
            enFallback:
                'The Learning Module is locked until the Pre-Assessment is completed and saved.',
            tlFallback:
                'Naka-lock ang Modyul sa Pag-aaral hanggang matapos at ma-save ang Paunang Pagsusulit.',
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showLearningLockedAccessAndClose();
        });
        return;
      }

      final materialRaw = await _supabase
          .from('learning_materials')
          .select('id,title,title_tl,subtitle,subtitle_tl,hero_asset')
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .maybeSingle();

      if (materialRaw == null) {
        throw StateError('No content found');
      }

      final material = Map<String, dynamic>.from(materialRaw);
      final learningMaterialId = material['id'] as String;

      final pagesRaw = await _supabase
          .from('learning_material_pages')
          .select('page_no,page_key,title_en,title_tl')
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('page_no');

      final blocksRaw = await _supabase
          .from('learning_material_blocks')
          .select(
            'page_no,block_no,block_key,block_type,text_en,text_tl,'
            'source_title,source_organization,source_url',
          )
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('page_no')
          .order('block_no');

      final textsRaw = await _supabase
          .from('learning_material_texts')
          .select('text_order,text_key,text_en,text_tl')
          .eq('module_no', _moduleNo)
          .eq('usage_context', 'module_5_learning_material')
          .eq('is_active', true)
          .order('text_order');

      final mediaRaw = await _supabase
          .from('learning_material_media_assets')
          .select('asset_key,asset_path,public_url,asset_type')
          .eq('learning_material_id', learningMaterialId)
          .eq('module_no', _moduleNo)
          .eq('is_active', true)
          .order('display_order');

      final en = <String, String>{};
      final tl = <String, String>{};
      final sources = <String, _SourceReference>{};

      void putText(String key, Object? enValue, Object? tlValue) {
        final cleanKey = key.trim();
        if (cleanKey.isEmpty) return;

        final enText = (enValue ?? '').toString().trim();
        final tlText = (tlValue ?? '').toString().trim();

        if (enText.isNotEmpty) en[cleanKey] = enText;
        if (tlText.isNotEmpty) tl[cleanKey] = tlText;
      }

      putText(
        'header.module_title',
        material['title'],
        material['title_tl'],
      );

      for (final raw in pagesRaw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final pageNo = row['page_no'] as int;
        putText('page$pageNo.title', row['title_en'], row['title_tl']);
      }

      for (final raw in blocksRaw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final blockKey = (row['block_key'] ?? '').toString().trim();

        putText(blockKey, row['text_en'], row['text_tl']);

        final sourceOrganization =
            (row['source_organization'] ?? '').toString().trim();
        final sourceUrl = (row['source_url'] ?? '').toString().trim();

        if (blockKey.isNotEmpty &&
            sourceOrganization.isNotEmpty &&
            sourceUrl.isNotEmpty) {
          sources[blockKey] = _SourceReference(
            organization: sourceOrganization,
            url: sourceUrl,
          );
        }
      }

      for (final raw in textsRaw) {
        final row = Map<String, dynamic>.from(raw as Map);
        putText(row['text_key'].toString(), row['text_en'], row['text_tl']);
      }

      var guideVideoPath = '';
      var buildingModelPath = '';
      for (final raw in mediaRaw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final assetKey = (row['asset_key'] ?? '').toString().trim();
        final publicUrl = (row['public_url'] ?? '').toString().trim();
        final assetPath = (row['asset_path'] ?? '').toString().trim();
        if (assetKey == 'module5_guide_video') {
          guideVideoPath = _resolveGuideVideoSource(assetPath, publicUrl);
        } else if (assetKey == _module5BuildingModelAssetKey) {
          buildingModelPath = _resolveModelStorageUrl(assetPath);
        }
      }

      _Module5LearningMaterialStore.update(
        en: en,
        tl: tl,
        sourceRefs: sources,
        guideVideoAssetPath: guideVideoPath,
        buildingModelAssetPath: buildingModelPath,
      );

      if (!mounted) return;
      setState(() {
        _isLoadingContent = false;
        _contentError = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onScroll();
        _showIntroAfterContentLoad();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingContent = false;
        _contentError = error.toString();
      });
    }
  }

  void _showIntroAfterContentLoad() {
    if (_introShown) return;
    _introShown = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _showIntroPopup();
    });
  }

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  Future<void> _showLearningLockedAccessAndClose() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _StyledDialog(
        icon: Icons.lock_rounded,
        iconColor: AppColors.brandRed,
        title: _dbTextOr(
          context,
          'popup.locked_access.title',
          enFallback: 'Learning Module Locked',
          tlFallback: 'Naka-lock ang Modyul sa Pag-aaral',
        ),
        body: _dbTextOr(
          context,
          'popup.locked_access.body',
          enFallback:
              'Complete the Pre-Assessment first. The Learning Module will open only after the Pre-Assessment is completed.',
          tlFallback:
              'Tapusin muna ang Paunang Pagsusulit. Magbubukas lang ang Modyul sa Pag-aaral kapag tapos na ang Paunang Pagsusulit.',
        ),
        buttonLabel: _dbTextOr(
          context,
          'popup.locked_access.button',
          enFallback: 'I understand',
          tlFallback: 'Naiintindihan',
        ),
        onPressed: () => Navigator.pop(dialogContext),
      ),
    );

    // After the dialog closes, return to the previous screen: learning_materials.dart.
    if (mounted) Navigator.pop(context);
  }


  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _isSwitchingPage) return;

    final max = _scrollCtrl.position.maxScrollExtent;
    final off = _scrollCtrl.offset;

    if (max <= 0) {
      if (_progress != 1.0 || !_canNext) {
        setState(() {
          _progress = 1.0;
          _canNext  = _pageIndex != 2;
        });
      }
      return;
    }

    final p         = (off / max).clamp(0.0, 1.0).toDouble();
    final nearBottom = off >= (max - 8);

    if (_progress != p || _canNext != nearBottom) {
      setState(() {
        _progress = p;
        _canNext  = nearBottom;
      });
    }

    if (_pageIndex == 2 && nearBottom) _lastPageCompleted = true;
  }

  void _resetForNewPage() {
    setState(() {
      _isSwitchingPage   = true;
      _progress          = 0.0;
      _canNext           = false;
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
      case 0: case 1: case 2: return 4;
      default: return 0;
    }
  }

  bool _hasReadAllRequiredSections(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _readSections.length) return false;
    return _readSections[pageIndex].length >=
        _requiredSectionCountForPage(pageIndex);
  }

  void _goBack() {
    if (_pageIndex == 0) { Navigator.pop(context); return; }
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
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
            curve: Curves.easeOutCubic);
      });
    } else {
      setState(() => _lastPageCompleted = true);
      _showFinalCompletePopup();
    }
  }

  // --------------------------------------------------------------------------
  // POPUPS
  // --------------------------------------------------------------------------

  void _showUnreadSectionsPopup() {
    if (_unreadPromptVisible) return;
    _unreadPromptVisible = true;
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.brandRed,
        title: _dbText(context, 'popup.keep_reading.title'),
        body: _dbText(context, 'popup.keep_reading.body'),
        buttonLabel: _dbText(context, 'common.got_it'),
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
        title: _dbText(context, 'popup.intro.title'),
        body: _dbText(context, 'popup.intro.body'),
        buttonLabel: _dbText(context, 'common.got_it_exclamation'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showPageCompletePopup(int pageIndex, VoidCallback onContinue) {
    final titles = [
      _dbText(context, 'popup.page1_complete.title'),
      _dbText(context, 'popup.page2_complete.title'),
    ];
    final bodies = [
      _dbText(context, 'popup.page1_complete.body'),
      _dbText(context, 'popup.page2_complete.body'),
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: titles[pageIndex],
        body: bodies[pageIndex],
        buttonLabel: _dbText(context, 'common.continue_arrow'),
        onPressed: () { Navigator.pop(context); onContinue(); },
      ),
    );
  }

  void _showFinalCompletePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StyledDialog(
        icon: Icons.verified_rounded,
        iconColor: AppColors.brandRed,
        title: _dbText(context, 'popup.final.title'),
        body: _dbText(context, 'popup.final.body'),
        buttonLabel: _dbText(context, 'common.start_post_test_arrow'),
        onPressed: () {
          Navigator.pop(context);
          _completeLearningAndOpenPostAssessment();
        },
      ),
    );
  }

  Future<void> _completeLearningAndOpenPostAssessment() async {
    try {
      final progression = ModuleProgressionService();
      await progression.markLearningMaterialCompleted(moduleNo: _moduleNo);
      await progression.ensureCanStartPostTest(moduleNo: _moduleNo);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostAssessmentIntroPage()),
      );
    } on ProgressionAccessDenied catch (error) {
      if (!mounted) return;
      _showInfoPopup(
        title: _dbTextOr(
          context,
          'popup.locked_access.title',
          enFallback: 'Post-Assessment Locked',
          tlFallback: 'Naka-lock ang Panghuling Pagsusulit',
        ),
        message: error.message,
        icon: Icons.lock_rounded,
      );
    }
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
        buttonLabel: _dbText(context, 'common.got_it'),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showDoThisNowPopup() {
    _showInfoPopup(
      title: _dbText(context, 'popup.emergency_steps.title'),
      icon: Icons.apartment_rounded,
      color: AppColors.brandRed,
      message: _dbText(context, 'popup.emergency_steps.body'),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContent) {
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

    if (_contentError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _LMGradientBackdrop(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _dbTextOr(
                          context,
                          'state.error_loading_title',
                          enFallback: 'Error loading content',
                          tlFallback: 'Error loading content',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _contentError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLearningMaterialContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _dbTextOr(
                            context,
                            'state.retry_button',
                            enFallback: 'Retry',
                            tlFallback: 'Retry',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
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

    final isLast     = _pageIndex == 2;
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
                    sectionTitle: _dbText(context, 'header.section_title'),
                    moduleLabel: _dbText(context, 'header.module_label'),
                    moduleTitle: _dbText(context, 'header.module_title'),
                    currentPage: _pageIndex + 1,
                    totalPages:  3,
                    progress:    _progress,
                    onClose:     () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics:    const NeverScrollableScrollPhysics(),
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
                  pageIndex:   _pageIndex,
                  isLast:      isLast,
                  nextEnabled: nextEnabled,
                  onBack:      _goBack,
                  onNext:      _goNext,
                  context:     context,
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
      physics:    const BouncingScrollPhysics(),
      padding:    const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width:  double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.95), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12)),
              BoxShadow(
                  color: AppColors.brandRed.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PAGE 1 — OVERVIEW & TYPES
  // --------------------------------------------------------------------------
  Widget _page1OverviewAndTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.apartment_rounded,
          accent1: accent,
          accent2: accent2,
          pageTag: _dbText(context, 'page1.tag'),
          title: _dbText(context, 'page1.title'),
          subtitle: _dbText(context, 'page1.subtitle'),
        ),
        const SizedBox(height: 16),
        
        _Tenement3DPhotoCard(
          assetPath: _buildingModelPath(),
          title: _dbText(context, 'page1.preview.title'),
          subtitle: _dbText(context, 'page1.preview.subtitle'),
        ),
        const SizedBox(height: 14),
        _TenementIntroCard(
          icon: Icons.apartment_rounded,
          title: _dbText(context, 'page1.intro.title'),
          body: _dbText(context, 'page1.intro.body'),
        ),
        const SizedBox(height: 8),
        _ReferenceSourceCard(
          label: _dbText(context, 'common.reference'),
          title: _dbText(context, 'ref.usfa_apartment.title'),
          organization: _sourceOrganization('ref.usfa_apartment.title'),
          sourceUrl: _sourceUrl('ref.usfa_apartment.title'),
          icon: Icons.verified_rounded,
          compact: true,
        ),
        const SizedBox(height: 8),
        _ReferenceSourceCard(
          label: _dbText(context, 'common.reference'),
          title: _dbText(context, 'ref.nfpa_highrise_tips.title'),
          organization: _sourceOrganization('ref.nfpa_highrise_tips.title'),
          sourceUrl: _sourceUrl('ref.nfpa_highrise_tips.title'),
          icon: Icons.verified_rounded,
          compact: true,
        ),
        const SizedBox(height: 14),
        _ExpandableLesson(
          sectionIndex: 0,
          pageIndex:    0,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[0].add(i)),
          icon: Icons.warning_rounded,
          accentColor: accent,
          title: _dbText(context, 'page1.section1.title'),
          child: _BodyText(_dbText(context, 'page1.section1.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 1,
          pageIndex:    0,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[0].add(i)),
          icon: Icons.electrical_services_rounded,
          accentColor: accent,
          title: _dbText(context, 'page1.section2.title'),
          child: _BodyText(_dbText(context, 'page1.section2.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 2,
          pageIndex:    0,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[0].add(i)),
          icon: Icons.soup_kitchen_rounded,
          accentColor: accent,
          title: _dbText(context, 'page1.section3.title'),
          child: _BodyText(_dbText(context, 'page1.section3.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 3,
          pageIndex:    0,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[0].add(i)),
          icon: Icons.stairs_rounded,
          accentColor: accent,
          title: _dbText(context, 'page1.section4.title'),
          child: _BodyText(_dbText(context, 'page1.section4.body')),
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount:  _readSections[0].length,
          totalCount: _requiredSectionCountForPage(0),
          context:    context,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // PAGE 2 — CAUSES & PREVENTION
  // --------------------------------------------------------------------------
  Widget _page2CausesAndPrevention() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.shield_rounded,
          accent1: accent2,
          accent2: accent,
          pageTag: _dbText(context, 'page2.tag'),
          title: _dbText(context, 'page2.title'),
          subtitle: _dbText(context, 'page2.subtitle'),
        ),
        const SizedBox(height: 16),
        _SourceCard(
          label: _dbText(context, 'common.source_reference'),
          text: _dbText(context, 'page2.source_note.body'),
        ),
        const SizedBox(height: 8),
        _ReferenceSourceCard(
          label: _dbText(context, 'common.reference'),
          title: _dbText(context, 'ref.usfa_highrise_infographic.title'),
          organization: _sourceOrganization('ref.usfa_highrise_infographic.title'),
          sourceUrl: _sourceUrl('ref.usfa_highrise_infographic.title'),
          icon: Icons.verified_rounded,
          compact: true,
        ),
        const SizedBox(height: 8),
        _ReferenceSourceCard(
          label: _dbText(context, 'common.reference'),
          title: _dbText(context, 'ref.ready_home_fires.title'),
          organization: _sourceOrganization('ref.ready_home_fires.title'),
          sourceUrl: _sourceUrl('ref.ready_home_fires.title'),
          icon: Icons.verified_rounded,
          compact: true,
        ),
        const SizedBox(height: 14),
        _ExpandableLesson(
          sectionIndex: 0,
          pageIndex:    1,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[1].add(i)),
          icon: Icons.power_rounded,
          accentColor: accent,
          title: _dbText(context, 'page2.section1.title'),
          child: _BodyText(_dbText(context, 'page2.section1.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 1,
          pageIndex:    1,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[1].add(i)),
          icon: Icons.restaurant_rounded,
          accentColor: accent,
          title: _dbText(context, 'page2.section2.title'),
          child: _BodyText(_dbText(context, 'page2.section2.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 2,
          pageIndex:    1,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[1].add(i)),
          icon: Icons.door_front_door_rounded,
          accentColor: accent,
          title: _dbText(context, 'page2.section3.title'),
          child: _BodyText(_dbText(context, 'page2.section3.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 3,
          pageIndex:    1,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[1].add(i)),
          icon: Icons.campaign_rounded,
          accentColor: accent,
          title: _dbText(context, 'page2.section4.title'),
          child: _BodyText(_dbText(context, 'page2.section4.body')),
        ),
        const SizedBox(height: 12),
        _Callout(
          icon:  Icons.shield_rounded,
          color: AppColors.brandRedDark,
          title: _dbText(context, 'page2.callout.title'),
          lines: [
            _dbText(context, 'page2.callout.body'),
          ],
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount:  _readSections[1].length,
          totalCount: _requiredSectionCountForPage(1),
          context:    context,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // PAGE 3 — EMERGENCY RESPONSE
  // --------------------------------------------------------------------------
  Widget _page3EmergencyResponse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageBanner(
          icon: Icons.notifications_active_rounded,
          accent1: AppColors.brandRed,
          accent2: accent2,
          pageTag: _dbText(context, 'page3.tag'),
          title: _dbText(context, 'page3.title'),
          subtitle: _dbText(context, 'page3.subtitle'),
        ),
        const SizedBox(height: 16),
        _SourceCard(
          label: _dbText(context, 'common.simulation_context'),
          text: _dbText(context, 'page3.simulation_context.body'),
        ),
        const SizedBox(height: 8),
        _ReferenceSourceCard(
          label: _dbText(context, 'common.reference'),
          title: _dbText(context, 'ref.nfpa_highrise_building.title'),
          organization: _sourceOrganization('ref.nfpa_highrise_building.title'),
          sourceUrl: _sourceUrl('ref.nfpa_highrise_building.title'),
          icon: Icons.verified_rounded,
          compact: true,
        ),
        const SizedBox(height: 8),
        _ReferenceSourceCard(
          label: _dbText(context, 'common.reference'),
          title: _dbText(context, 'ref.ready_home_escape.title'),
          organization: _sourceOrganization('ref.ready_home_escape.title'),
          sourceUrl: _sourceUrl('ref.ready_home_escape.title'),
          icon: Icons.verified_rounded,
          compact: true,
        ),
        const SizedBox(height: 14),
        _Module5VideoSourceCard(
          label: _dbTextOr(
            context,
            'page3.video.source_label',
            enFallback: 'Source: YouTube',
            tlFallback: 'Source: YouTube',
          ),
          title: _dbTextOr(
            context,
            'page3.video.source_title',
            enFallback:
                "USA TODAY – Apartment fires: Here's why they keep happening and how to stay safe | JUST THE FAQS",
            tlFallback:
                "USA TODAY – Apartment fires: Here's why they keep happening and how to stay safe | JUST THE FAQS",
          ),
          body: _dbTextOr(
            context,
            'page3.video.source_body',
            enFallback:
                'Supports the apartment fire safety lesson by showing why apartment fires happen and how residents can plan a safer escape.',
            tlFallback:
                'Dagdag-gabay ito sa aralin tungkol sa sunog sa apartment: bakit ito nangyayari at paano mas ligtas na makalikas.',
          ),
          sourceUrl: _dbTextOr(
            context,
            'page3.video.source_url',
            enFallback: _module5GuideVideoSourceUrl,
            tlFallback: _module5GuideVideoSourceUrl,
          ),
        ),
        const SizedBox(height: 12),
        _Module5GuideVideoCard(
          assetPath: _guideVideoPath(),
          title: _dbTextOr(
            context,
            'page3.video.card_title',
            enFallback: 'Guide Video',
            tlFallback: 'Video na Gabay',
          ),
          subtitle: _dbTextOr(
            context,
            'page3.video.card_subtitle',
            enFallback:
                'Watch this short video as an additional guide before finishing this section.',
            tlFallback:
                'Panoorin ang maikling video bilang karagdagang gabay bago tapusin ang bahaging ito.',
          ),
          tapHint: _dbTextOr(
            context,
            'page3.video.tap_hint',
            enFallback: 'Tap the video to play or pause.',
            tlFallback: 'I-tap ang video para i-play o i-pause.',
          ),
          unavailableMessage: _dbTextOr(
            context,
            'page3.video.unavailable',
            enFallback:
                'Video could not load. Make sure module5.mp4 is added to assets/videos and declared in pubspec.yaml.',
            tlFallback:
                'Hindi ma-load ang video. Siguraduhing nasa assets/videos ang module5.mp4 at naka-declare sa pubspec.yaml.',
          ),
        ),
        const SizedBox(height: 14),
        _ExpandableLesson(
          sectionIndex: 0,
          pageIndex:    2,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[2].add(i)),
          icon: Icons.notifications_active_rounded,
          accentColor: accent,
          title: _dbText(context, 'page3.section1.title'),
          child: _BodyText(_dbText(context, 'page3.section1.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 1,
          pageIndex:    2,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[2].add(i)),
          icon: Icons.smoke_free_rounded,
          accentColor: accent,
          title: _dbText(context, 'page3.section2.title'),
          child: _BodyText(_dbText(context, 'page3.section2.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 2,
          pageIndex:    2,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[2].add(i)),
          icon: Icons.block_rounded,
          accentColor: accent,
          title: _dbText(context, 'page3.section3.title'),
          child: _BodyText(_dbText(context, 'page3.section3.body')),
        ),
        const SizedBox(height: 12),
        _ExpandableLesson(
          sectionIndex: 3,
          pageIndex:    2,
          readSections: _readSections,
          onRead: (i) => setState(() => _readSections[2].add(i)),
          icon: Icons.report_rounded,
          accentColor: accent,
          title: _dbText(context, 'page3.section4.title'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(_dbText(context, 'page3.section4.body')),
              const SizedBox(height: 10),
              _ActionPill(
                icon:  Icons.apartment_rounded,
                label: _dbText(context, 'page3.section4.action_label'),
                onTap: _showDoThisNowPopup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Callout(
          icon:  Icons.verified_user_rounded,
          color: AppColors.success,
          title: _dbText(context, 'page3.callout.title'),
          lines: [
            _dbText(context, 'page3.callout.body'),
          ],
        ),
        const SizedBox(height: 16),
        _ReadingProgressBadge(
          readCount:  _readSections[2].length,
          totalCount: _requiredSectionCountForPage(2),
          context:    context,
        ),
      ],
    );
  }
}

// ============================================================================
// LOADING CARD
// ============================================================================
class _LoadingContentCard extends StatelessWidget {
  const _LoadingContentCard();

  @override
  Widget build(BuildContext context) {
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
            _dbTextOr(
              context,
              'state.loading_materials',
              enFallback: 'Loading learning materials...',
              tlFallback: 'Nilo-load ang mga materyales sa pag-aaral...',
            ),
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

// ============================================================================
// GRADIENT BACKDROP  (aligned to Modules 1–4 structure, purple palette)
// ============================================================================
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
              end:   Alignment.bottomRight,
              colors: [
                AppColors.brandRedDeep,
                AppColors.brandRedDark,
                AppColors.brandRed,
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
          ),
        ),
        const Positioned(
            top: 50, right: -36,
            child: _LMDecorCircle(size: 138, opacity: 0.17)),
        const Positioned(
            top: 178, left: -42,
            child: _LMDecorCircle(size: 124, opacity: 0.13)),
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
      width: size, height: size,
      decoration: BoxDecoration(
        color:  AppColors.textOnRed.withOpacity(opacity),
        shape:  BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// HEADER  (aligned to Modules 1–4 _LearningAssessmentHeader, purple palette)
// ============================================================================
class _LearningAssessmentHeader extends StatelessWidget {
  const _LearningAssessmentHeader({
    required this.sectionTitle,
    required this.moduleLabel,
    required this.moduleTitle,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.onClose,
  });

  final String    sectionTitle;
  final String    moduleLabel;
  final String    moduleTitle;
  final int       currentPage;
  final int       totalPages;
  final double    progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final pageLabel = _dbText(context, 'header.page_label');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:  AppColors.textOnRed.withOpacity(0.18),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: AppColors.textOnRed.withOpacity(0.24)),
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textOnRed, size: 21),
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
              color:        AppColors.textOnRed,
              fontSize:     27,
              height:       1.12,
              fontWeight:   FontWeight.w900,
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
                    color:     AppColors.brandRed.withOpacity(0.24),
                    blurRadius: 12,
                    offset:    const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.apartment_rounded,
                      color: AppColors.textOnRed, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    moduleLabel,
                    style: const TextStyle(
                      color:      AppColors.textOnRed,
                      fontSize:   12,
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
                  color:      AppColors.textOnRed.withOpacity(0.88),
                  fontSize:   12.5,
                  height:     1.28,
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
            value:           safeProgress,
            minHeight:       8,
            backgroundColor: AppColors.textOnRed.withOpacity(0.22),
            valueColor:      const AlwaysStoppedAnimation<Color>(
                AppColors.textOnRed),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '$pageLabel $currentPage/$totalPages',
              style: TextStyle(
                color:      AppColors.textOnRed.withOpacity(0.76),
                fontSize:   12,
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
                  width:  active ? 28 : 10,
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

// ============================================================================
// BOTTOM NAV BAR  (aligned to Modules 1–4 style, purple palette)
// ============================================================================
class _BottomNavBar extends StatelessWidget {
  final int          pageIndex;
  final bool         isLast;
  final bool         nextEnabled;
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
        ? _dbText(context, 'nav.start_post_test')
        : _dbText(context, 'nav.next');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
              color:     Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset:    const Offset(0, -4)),
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
                  side:  const BorderSide(color: AppColors.brandRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onBack,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back_ios_rounded,
                        size: 14, color: AppColors.brandRed),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _dbText(context, 'nav.back'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color:      AppColors.brandRed,
                            fontWeight: FontWeight.bold),
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
              height:   48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextEnabled
                      ? AppColors.brandRed
                      : AppColors.brandRedSoft,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                  padding:     const EdgeInsets.symmetric(horizontal: 12),
                  elevation:   nextEnabled ? 4 : 0,
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
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis,
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

// ============================================================================
// PAGE BANNER  (aligned to Modules 1–4 _PageBanner, purple palette)
// ============================================================================
class _PageBanner extends StatelessWidget {
  const _PageBanner({
    required this.icon,
    required this.accent1,
    required this.accent2,
    required this.pageTag,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color    accent1;
  final Color    accent2;
  final String   pageTag;
  final String   title;
  final String   subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [accent1.withOpacity(0.08), accent2.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent1.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
                colors: [accent1, accent2],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color:      accent1.withOpacity(0.3),
                    blurRadius: 12,
                    offset:     const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pageTag,
                    style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w900,
                        color:      accent1,
                        letterSpacing: 1.0)),
                const SizedBox(height: 3),
                Text(title,
                    style: const TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w900,
                        color:      Color(0xFF111827),
                        height:     1.2)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXPANDABLE LESSON  (aligned to Modules 1–4, purple palette)
// ============================================================================
class _ExpandableLesson extends StatefulWidget {
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

  final int               sectionIndex;
  final int               pageIndex;
  final List<Set<int>>    readSections;
  final ValueChanged<int> onRead;
  final IconData          icon;
  final Color             accentColor;
  final String            title;
  final Widget            child;

  @override
  State<_ExpandableLesson> createState() => _ExpandableLessonState();
}

class _ExpandableLessonState extends State<_ExpandableLesson>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double>   _expandAnim;

  bool get _isRead =>
      widget.readSections[widget.pageIndex].contains(widget.sectionIndex);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _expandAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
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
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset:     const Offset(0, 4)),
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
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _isRead
                          ? AppColors.success.withOpacity(0.1)
                          : color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isRead ? Icons.check_rounded : widget.icon,
                      color: _isRead ? AppColors.success : color,
                      size:  20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize:   14.5,
                        color: _isRead
                            ? AppColors.success
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (_isRead)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _dbText(context, 'lesson.read_badge'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize:   11,
                              color:      AppColors.success,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: color, size: 22),
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

// ============================================================================
// READING PROGRESS BADGE  (aligned to Modules 1–4 style, purple palette)
// ============================================================================
class _ReadingProgressBadge extends StatelessWidget {
  const _ReadingProgressBadge({
    required this.readCount,
    required this.totalCount,
    required this.context,
  });

  final int          readCount;
  final int          totalCount;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final done  = readCount >= totalCount;
    final color = done ? AppColors.success : AppColors.brandRed;
    final label = done
        ? _dbText(context, 'progress.all_sections_read')
        : _dbText(context, 'progress.sections_read', params: {'readCount': readCount.toString(), 'totalCount': totalCount.toString()});

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.menu_book_rounded,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          if (!done)
            Flexible(
              child: Text(
                _dbText(context, 'progress.scroll_tap_sections'),
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

// ============================================================================
// TENEMENT INTRO CARD  (non-gated overview card, replaces _IntroMediaBox)
// ============================================================================
class _TenementIntroCard extends StatelessWidget {
  const _TenementIntroCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String   title;
  final String   body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              gradient:     AppColors.module5Gradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.textOnRed, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize:   16)),
                const SizedBox(height: 6),
                Text(body,
                    style: const TextStyle(
                        color:      AppColors.textSecondary,
                        height:     1.45,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SOURCE CARD  (visual style aligned to Modules 1–4, purple palette)
// ============================================================================
class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.brandRedSoft.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded,
                color: AppColors.brandRed, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color:      AppColors.brandRed,
                        fontSize:   12.5,
                        fontWeight: FontWeight.w900,
                        height:     1.2)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        color:      AppColors.textPrimary,
                        fontSize:   11.5,
                        fontWeight: FontWeight.w600,
                        height:     1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CALLOUT  (kept from original Module 5, purple palette)
// ============================================================================
class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  final IconData     icon;
  final Color        color;
  final String       title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: color.withOpacity(0.22)),
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
                Text(title,
                    style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                const SizedBox(height: 8),
                ...lines.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line,
                          style: const TextStyle(
                              color:      AppColors.textSecondary,
                              height:     1.4,
                              fontWeight: FontWeight.w600)),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTION PILL  (aligned to Modules 1–4 style, purple palette)
// ============================================================================
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData      icon;
  final String        label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        AppColors.brandRedSoft.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:      MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.brandRed),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color:      AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BODY TEXT  (helper widget, aligned to Modules 1–4)
// ============================================================================
class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13.5, height: 1.55, color: Color(0xFF4B5563)));
  }
}

// ============================================================================
// REFERENCE SOURCE CARD  (mirrors Module 1 _ReferenceSourceCard, purple palette)
// ============================================================================
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
            child: Icon(icon,
                color: AppColors.brandRed, size: compact ? 17 : 19),
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


// ============================================================================
// PAGE 3 GUIDE VIDEO — Module 5 apartment fire YouTube source
// ============================================================================
class _Module5VideoSourceCard extends StatelessWidget {
  const _Module5VideoSourceCard({
    required this.label,
    required this.title,
    required this.body,
    required this.sourceUrl,
  });

  final String label;
  final String title;
  final String body;
  final String sourceUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft.withOpacity(0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.13)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brandRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.brandRed,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sourceUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
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

class _Module5GuideVideoCard extends StatefulWidget {
  const _Module5GuideVideoCard({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.tapHint,
    required this.unavailableMessage,
  });

  final String assetPath;
  final String title;
  final String subtitle;
  final String tapHint;
  final String unavailableMessage;

  @override
  State<_Module5GuideVideoCard> createState() => _Module5GuideVideoCardState();
}

class _Module5GuideVideoCardState extends State<_Module5GuideVideoCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.module5Gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandRed.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ReliableVideoPlayer(
                source: widget.assetPath,
                errorText: widget.unavailableMessage,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandRedSoft.withOpacity(0.48),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.brandRed,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.tapHint,
                    style: const TextStyle(
                      color: AppColors.brandRedDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
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

class _Module5VideoLoadingBox extends StatelessWidget {
  const _Module5VideoLoadingBox();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandRedSoft.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.brandRed),
        ),
      ),
    );
  }
}

class _Module5VideoUnavailableBox extends StatelessWidget {
  const _Module5VideoUnavailableBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandRedSoft.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_file_rounded,
              color: AppColors.brandRed,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TENEMENT 3D MODEL PREVIEW CARD — Page 1 only
// ============================================================================
class _Tenement3DPhotoCard extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;

  const _Tenement3DPhotoCard({
    required this.assetPath,
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
          colors: [AppColors.purple50, AppColors.purple100],
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.5,
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _TenementInPageVisualChip(),
          const SizedBox(height: 22),
          _PageOneBuilding3DPreview(assetPath: assetPath),
        ],
      ),
    );
  }
}

class _TenementInPageVisualChip extends StatelessWidget {
  const _TenementInPageVisualChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandRed.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandRed.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_rounded,
            color: AppColors.brandRed,
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _dbText(context, 'preview.visual_chip'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.brandRed,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageOneBuilding3DPreview extends StatelessWidget {
  final String assetPath;

  const _PageOneBuilding3DPreview({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final modelPath = _resolveBuildingModelPath(assetPath);

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth * 1.75)
            .clamp(560.0, 720.0)
            .toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dbTextOr(
                context,
                'preview.3d_model_title',
                enFallback: '3D Model Preview',
                tlFallback: '3D Model Preview',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dbText(context, 'preview.visual_chip'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                  color: AppColors.purple50,
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
                              AppColors.purple100.withOpacity(0.55),
                              AppColors.brandRed.withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _BuildingViewerBadge(
                        icon: Icons.view_in_ar_rounded,
                        label: _dbTextOr(
                          context,
                          'preview.3d_badge',
                          enFallback: '3D Preview',
                          tlFallback: '3D Preview',
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 24,
                      bottom: 8,
                      child: _AnimatedBuildingModelViewer(modelPath: modelPath),
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
                      _dbTextOr(
                        context,
                        'preview.3d_interaction_hint',
                        enFallback: 'Drag to rotate. Pinch to zoom.',
                        tlFallback: 'I-drag para i-rotate. I-pinch para i-zoom.',
                      ),
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

  String _resolveBuildingModelPath(String rawPath) {
    final path = rawPath.trim();
    if (path.toLowerCase().endsWith('.glb') ||
        path.toLowerCase().endsWith('.gltf')) {
      return path;
    }
    return _module5BuildingModelAsset;
  }
}

class _AnimatedBuildingModelViewer extends StatelessWidget {
  final String modelPath;

  const _AnimatedBuildingModelViewer({required this.modelPath});

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: modelPath,
      alt: _dbTextOr(
        context,
        'preview.3d_model_alt',
        enFallback: 'Building fire 3D model preview',
        tlFallback: 'Building fire 3D model preview',
      ),
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
      backgroundColor: Colors.transparent,
      cameraOrbit: '0deg 72deg 1.85m',
      fieldOfView: '25deg',
      shadowIntensity: 0.55,
      exposure: 1.05,
    );
  }
}

class _BuildingModelLabel extends StatelessWidget {
  final String label;

  const _BuildingModelLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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

class _BuildingViewerBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BuildingViewerBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.84),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brandRed.withOpacity(0.14)),
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
            Icon(icon, size: 16, color: AppColors.brandRed),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.brandRed,
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

class _BuildingSoftGlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _BuildingSoftGlowBlob({
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

class _BuildingPreviewGridPainter extends CustomPainter {
  final Color color;

  const _BuildingPreviewGridPainter({required this.color});

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
  bool shouldRepaint(covariant _BuildingPreviewGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ============================================================================
// STYLED DIALOG  (aligned to Modules 1–4 style: centered icon + close X)
// ============================================================================
class _StyledDialog extends StatelessWidget {
  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String       body;
  final String       buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 34, height: 34,
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    padding:     EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon:  const Icon(Icons.close_rounded, size: 18),
                    color: Colors.black54,
                    onPressed: () => Navigator.pop(context),
                    tooltip:   _dbText(context, 'dialog.close'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w900,
                    color:      iconColor)),
            const SizedBox(height: 10),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, height: 1.55, color: Color(0xFF374151))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:     const EdgeInsets.symmetric(vertical: 14),
                  elevation:   3,
                  shadowColor: iconColor.withOpacity(0.3),
                ),
                onPressed: onPressed,
                child: Text(buttonLabel,
                    style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize:   15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
