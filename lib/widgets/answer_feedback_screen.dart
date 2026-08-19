import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_text.dart';
import '../localization/language_controller.dart';
import '../localization/localized_db_text.dart';
import '../module_1_extinguisher.dart/module_1_learningmaterials.dart' as m1;
import '../module_2_house.dart/module_2_learningmaterials.dart' as m2;
import '../module_3_electrical.dart/module_3_learningmaterials.dart' as m3;
import '../module_4_kitchen.dart/module_4_learningmaterials.dart' as m4;
import '../module_5_building.dart/module_5_learningmaterials.dart' as m5;

// Semantic feedback colors are deliberately module-independent: a wrong answer
// is always red and a correct answer is always green, whichever module the
// reviewed attempt belongs to.
const Color _kSuccess = Color(0xFF198754);
const Color _kSuccessSoft = Color(0xFFE8F5EC);
const Color _kError = Color(0xFFD32F2F);
const Color _kErrorSoft = Color(0xFFFDEBEA);

// Neutral rail behind the score progress bar. Kept module-independent so the
// filled part (always the semantic green) reads the same in every module.
const Color _kTrack = Color(0xFFE7EAEE);

// Module 1's palette predates the shared border/shadow tokens the other
// modules define, so those two values stay with its theme entry below.
const Color _kModule1Border = Color(0xFFE8D8D9);
const Color _kModule1Shadow = Color(0x1A000000);

/// The visual identity of one module, reused verbatim from the palette that
/// module already applies to its Learning Material screen.
class _ModuleTheme {
  const _ModuleTheme({
    required this.accent,
    required this.accentSoft,
    required this.background,
    required this.surface,
    required this.border,
    required this.shadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.gradientDeep,
    required this.gradientDark,
    required this.gradientBase,
    required this.onGradient,
    required this.icon,
  });

  final Color accent;
  final Color accentSoft;
  final Color background;
  final Color surface;
  final Color border;
  final Color shadow;
  final Color textPrimary;
  final Color textSecondary;

  /// The three stops of the module's header gradient, in the same order the
  /// Pre-Assessment Introduction screen paints them (deep -> dark -> base).
  final Color gradientDeep;
  final Color gradientDark;
  final Color gradientBase;

  /// Foreground color that reads on top of the gradient header.
  final Color onGradient;

  /// Module-specific accent icon (fire extinguisher, house, ...).
  final IconData icon;

  /// Used until the module behind the attempt is known, and when it cannot be
  /// resolved at all. Keeps the neutral review icon rather than claiming a
  /// module the attempt may not belong to.
  static const _ModuleTheme fallback = _ModuleTheme(
    accent: m1.AppColors.brandRed,
    accentSoft: m1.AppColors.brandRedSoft,
    background: m1.AppColors.background,
    surface: m1.AppColors.surface,
    border: _kModule1Border,
    shadow: _kModule1Shadow,
    textPrimary: m1.AppColors.textPrimary,
    textSecondary: m1.AppColors.textSecondary,
    gradientDeep: m1.AppColors.brandRedDeep,
    gradientDark: m1.AppColors.brandRedDark,
    gradientBase: m1.AppColors.brandRed,
    onGradient: m1.AppColors.textOnRed,
    icon: Icons.fact_check_outlined,
  );

  /// Maps a `modules.module_no` to that module's own theme. Anything the app
  /// does not know about keeps the neutral [fallback].
  static _ModuleTheme forModuleNo(int? moduleNo) {
    switch (moduleNo) {
      case 1:
        return const _ModuleTheme(
          accent: m1.AppColors.brandRed,
          accentSoft: m1.AppColors.brandRedSoft,
          background: m1.AppColors.background,
          surface: m1.AppColors.surface,
          border: _kModule1Border,
          shadow: _kModule1Shadow,
          textPrimary: m1.AppColors.textPrimary,
          textSecondary: m1.AppColors.textSecondary,
          gradientDeep: m1.AppColors.brandRedDeep,
          gradientDark: m1.AppColors.brandRedDark,
          gradientBase: m1.AppColors.brandRed,
          onGradient: m1.AppColors.textOnRed,
          icon: Icons.fire_extinguisher_rounded,
        );
      case 2:
        return const _ModuleTheme(
          accent: m2.AppColors.brandRed,
          accentSoft: m2.AppColors.brandRedSoft,
          background: m2.AppColors.background,
          surface: m2.AppColors.surface,
          border: m2.AppColors.border,
          shadow: m2.AppColors.shadow,
          textPrimary: m2.AppColors.textPrimary,
          textSecondary: m2.AppColors.textSecondary,
          gradientDeep: m2.AppColors.brandRedDeep,
          gradientDark: m2.AppColors.brandRedDark,
          gradientBase: m2.AppColors.brandRed,
          onGradient: m2.AppColors.textOnRed,
          icon: Icons.home_rounded,
        );
      case 3:
        return const _ModuleTheme(
          accent: m3.AppColors.brandRed,
          accentSoft: m3.AppColors.brandRedSoft,
          background: m3.AppColors.background,
          surface: m3.AppColors.surface,
          border: m3.AppColors.border,
          shadow: m3.AppColors.shadow,
          textPrimary: m3.AppColors.textPrimary,
          textSecondary: m3.AppColors.textSecondary,
          gradientDeep: m3.AppColors.brandRedDeep,
          gradientDark: m3.AppColors.brandRedDark,
          gradientBase: m3.AppColors.brandRed,
          onGradient: m3.AppColors.textOnRed,
          icon: Icons.electrical_services_rounded,
        );
      case 4:
        return const _ModuleTheme(
          accent: m4.AppColors.brandRed,
          accentSoft: m4.AppColors.brandRedSoft,
          background: m4.AppColors.background,
          surface: m4.AppColors.surface,
          border: m4.AppColors.border,
          shadow: m4.AppColors.shadow,
          textPrimary: m4.AppColors.textPrimary,
          textSecondary: m4.AppColors.textSecondary,
          gradientDeep: m4.AppColors.brandRedDeep,
          gradientDark: m4.AppColors.brandRedDark,
          gradientBase: m4.AppColors.brandRed,
          onGradient: m4.AppColors.textOnRed,
          icon: Icons.restaurant_rounded,
        );
      case 5:
        return const _ModuleTheme(
          accent: m5.AppColors.brandRed,
          accentSoft: m5.AppColors.brandRedSoft,
          background: m5.AppColors.background,
          surface: m5.AppColors.surface,
          border: m5.AppColors.border,
          shadow: m5.AppColors.shadow,
          textPrimary: m5.AppColors.textPrimary,
          textSecondary: m5.AppColors.textSecondary,
          gradientDeep: m5.AppColors.brandRedDeep,
          gradientDark: m5.AppColors.brandRedDark,
          gradientBase: m5.AppColors.brandRed,
          onGradient: m5.AppColors.textOnRed,
          icon: Icons.apartment_rounded,
        );
      default:
        return fallback;
    }
  }
}

/// A single question's persisted feedback, reconstructed from Supabase
/// (assessment_attempt_answers joined with assessment_questions /
/// assessment_options) — never from local/in-memory quiz state.
class _FeedbackItem {
  _FeedbackItem({
    required this.questionNo,
    required this.questionRow,
    required this.options,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
  });

  final int questionNo;
  final Map<String, dynamic> questionRow;
  final List<Map<String, dynamic>> options;
  final Map<String, dynamic>? selectedOption;
  final Map<String, dynamic>? correctOption;
  final bool isCorrect;
}

/// Which subset of the reviewed questions the list is currently showing.
/// Purely a display filter — it never touches the loaded data or the score.
enum _ReviewFilter { all, correct, wrong }

/// Read-only Answer Feedback screen for a submitted Pre-Assessment attempt.
///
/// Shown from the Pre-Assessment Score Result screen. Every question,
/// option, the user's submitted answer, the correct answer, and the
/// explanation are fetched fresh from Supabase by [attemptId] — nothing is
/// hardcoded and nothing on this screen can be edited.
///
/// The screen's accents follow the theme of the module the attempt belongs to.
/// That module is resolved from the attempt's own `module_id`, so a single
/// screen serves every module.
class AnswerFeedbackScreen extends StatefulWidget {
  const AnswerFeedbackScreen({
    super.key,
    required this.attemptId,
    this.assessmentTitle,
    this.onBackToModule,
  });

  final String attemptId;
  final String? assessmentTitle;

  /// Optional override for the "Back to Module" action at the end of the
  /// review. Left null by every current caller, in which case the button
  /// leaves this screen exactly the way its back arrow already does — no
  /// existing navigation flow is altered.
  final VoidCallback? onBackToModule;

  @override
  State<AnswerFeedbackScreen> createState() => _AnswerFeedbackScreenState();
}

class _AnswerFeedbackScreenState extends State<AnswerFeedbackScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;
  List<_FeedbackItem> _items = const [];
  int _correctCount = 0;
  int? _moduleNo;

  /// `pre` / `post` from `assessments.type`, or null while unknown.
  String? _assessmentType;

  _ReviewFilter _filter = _ReviewFilter.all;

  // Scroll-progress plumbing for the "Question n of N" pill. None of this
  // changes what is displayed — only when the pill appears and what it counts.
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final List<GlobalKey> _itemKeys = [];
  int _visibleIndex = 0;
  bool _pillVisible = false;

  _ModuleTheme get _theme => _ModuleTheme.forModuleNo(_moduleNo);

  /// The questions the active filter lets through, in their loaded order.
  List<_FeedbackItem> get _visibleItems {
    switch (_filter) {
      case _ReviewFilter.correct:
        return _items.where((item) => item.isCorrect).toList();
      case _ReviewFilter.wrong:
        return _items.where((item) => !item.isCorrect).toList();
      case _ReviewFilter.all:
        return _items;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Stable key per card slot. Keyed by list position rather than by question
  /// number so it stays unique even if two rows share a `question_no`.
  GlobalKey _keyAt(int index) {
    while (_itemKeys.length <= index) {
      _itemKeys.add(GlobalKey());
    }
    return _itemKeys[index];
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 16;
    final index = _computeVisibleIndex();
    if (shouldShow != _pillVisible || index != _visibleIndex) {
      setState(() {
        _pillVisible = shouldShow;
        _visibleIndex = index;
      });
    }
  }

  /// Index of the card currently sitting at the top of the review list.
  int _computeVisibleIndex() {
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.attached) return _visibleIndex;

    final listTop = listBox.localToGlobal(Offset.zero).dy;
    final count = _visibleItems.length;
    var index = 0;

    for (var i = 0; i < count && i < _itemKeys.length; i++) {
      final box = _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= listTop + 96) {
        index = i;
      } else {
        break;
      }
    }

    return index;
  }

  void _setFilter(_ReviewFilter filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _visibleIndex = 0;
      _pillVisible = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _handleBackToModule() {
    final override = widget.onBackToModule;
    if (override != null) {
      override();
      return;
    }
    Navigator.pop(context);
  }

  /// Resolves which module this attempt belongs to (so the screen can wear
  /// that module's theme) and whether it was a pre- or post-assessment.
  /// Failures are non-fatal: the feedback still loads and the neutral theme
  /// is kept.
  Future<Map<String, dynamic>> _resolveAttemptContext() async {
    try {
      final attemptRow = await _supabase
          .from('assessment_attempts')
          .select('module_id, assessment_id')
          .eq('id', widget.attemptId)
          .maybeSingle();

      int? moduleNo;
      String? assessmentType;

      final moduleId = attemptRow?['module_id']?.toString();
      if (moduleId != null && moduleId.isNotEmpty) {
        final moduleRow = await _supabase
            .from('modules')
            .select('module_no')
            .eq('id', moduleId)
            .maybeSingle();
        moduleNo = (moduleRow?['module_no'] as num?)?.toInt();
      }

      final assessmentId = attemptRow?['assessment_id']?.toString();
      if (assessmentId != null && assessmentId.isNotEmpty) {
        final assessmentRow = await _supabase
            .from('assessments')
            .select('type')
            .eq('id', assessmentId)
            .maybeSingle();
        assessmentType = assessmentRow?['type']?.toString();
      }

      return {'module_no': moduleNo, 'assessment_type': assessmentType};
    } catch (_) {
      return const {'module_no': null, 'assessment_type': null};
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final attemptContext = await _resolveAttemptContext();
    if (!mounted) return;
    setState(() {
      _moduleNo = attemptContext['module_no'] as int?;
      _assessmentType = attemptContext['assessment_type'] as String?;
    });

    try {
      final answerRows = await _supabase
          .from('assessment_attempt_answers')
          .select('question_id, selected_option_id, is_correct, display_order')
          .eq('attempt_id', widget.attemptId)
          .order('display_order', ascending: true);

      final questionIds = answerRows
          .map((row) => row['question_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (questionIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _correctCount = 0;
          _isLoading = false;
        });
        return;
      }

      final questionRows = await _supabase
          .from('assessment_questions')
          .select(
            'id, question_no, prompt, prompt_tl, explanation, explanation_tl',
          )
          .inFilter('id', questionIds);

      final optionRows = await _supabase
          .from('assessment_options')
          .select(
            'id, question_id, option_key, option_text, option_text_tl, is_correct, display_order',
          )
          .inFilter('question_id', questionIds)
          .order('display_order', ascending: true);

      final questionsById = <String, Map<String, dynamic>>{
        for (final row in questionRows)
          row['id'].toString(): Map<String, dynamic>.from(row as Map),
      };

      final optionsByQuestion = <String, List<Map<String, dynamic>>>{};
      for (final row in optionRows) {
        final questionId = row['question_id']?.toString();
        if (questionId == null) continue;
        optionsByQuestion
            .putIfAbsent(questionId, () => [])
            .add(Map<String, dynamic>.from(row as Map));
      }

      final items = <_FeedbackItem>[];
      var correct = 0;
      var fallbackNo = 0;

      for (final answerRow in answerRows) {
        fallbackNo++;
        final questionId = answerRow['question_id']?.toString();
        final questionRow = questionId != null
            ? questionsById[questionId]
            : null;
        if (questionRow == null) continue;

        final options = optionsByQuestion[questionId] ?? const [];
        final selectedOptionId = answerRow['selected_option_id']?.toString();
        final isCorrect = answerRow['is_correct'] == true;
        if (isCorrect) correct++;

        Map<String, dynamic>? selectedOption;
        Map<String, dynamic>? correctOption;
        for (final option in options) {
          if (selectedOptionId != null &&
              option['id']?.toString() == selectedOptionId) {
            selectedOption = option;
          }
          if (option['is_correct'] == true) {
            correctOption = option;
          }
        }

        items.add(
          _FeedbackItem(
            questionNo:
                (questionRow['question_no'] as num?)?.toInt() ?? fallbackNo,
            questionRow: questionRow,
            options: options,
            selectedOption: selectedOption,
            correctOption: correctOption,
            isCorrect: isCorrect,
          ),
        );
      }

      items.sort((a, b) => a.questionNo.compareTo(b.questionNo));

      if (!mounted) return;
      setState(() {
        _items = items;
        _correctCount = correct;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;

    // The summary card only rides on the header once there is a real,
    // Supabase-backed score to put in it.
    final hasFeedback = !_isLoading && _error == null && _items.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.background,
      body: Column(
        children: [
          _FeedbackGradientHeader(
            theme: theme,
            moduleNo: _moduleNo,
            summaryCard: hasFeedback
                ? _SummaryHeader(
                    correctCount: _correctCount,
                    totalQuestions: _items.length,
                    assessmentTitle: widget.assessmentTitle,
                    assessmentType: _assessmentType,
                    moduleNo: _moduleNo,
                    theme: theme,
                  )
                : null,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: _buildBody(context, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, _ModuleTheme theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _kError, size: 40),
              const SizedBox(height: 12),
              Text(
                t(
                  context,
                  'We could not load your answer feedback. Please try again.',
                  'Hindi mai-load ang paliwanag sa iyong sagot. Pakisubukang muli.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _load,
                child: Text(t(context, 'Retry', 'Ulitin')),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          t(
            context,
            'No answer feedback is available for this attempt.',
            'Walang paliwanag sa sagot na available para sa pagsusulit na ito.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: theme.textSecondary,
          ),
        ),
      );
    }

    final visibleItems = _visibleItems;
    final wrongCount = _items.length - _correctCount;

    final listChildren = <Widget>[];
    if (visibleItems.isEmpty) {
      listChildren.add(_EmptyFilterState(theme: theme, filter: _filter));
    } else {
      for (var i = 0; i < visibleItems.length; i++) {
        listChildren.add(
          _FeedbackCard(
            key: _keyAt(i),
            item: visibleItems[i],
            theme: theme,
          ),
        );
        listChildren.add(const SizedBox(height: 10));
      }
    }
    listChildren.add(const SizedBox(height: 6));
    listChildren.add(
      _BackToModuleButton(theme: theme, onTap: _handleBackToModule),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: _FilterBar(
            theme: theme,
            selected: _filter,
            allCount: _items.length,
            correctCount: _correctCount,
            wrongCount: wrongCount,
            onChanged: _setFilter,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                key: _listKey,
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                children: listChildren,
              ),
              if (visibleItems.length > 1)
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _pillVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: _ReviewProgressPill(
                          theme: theme,
                          current: _visibleIndex + 1,
                          total: visibleItems.length,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-width themed header for the Answer Feedback screen.
///
/// The visual structure is lifted from the Pre-Assessment Introduction screen
/// (`_IntroGradientHeader` in `module_*/pre_assess_instruction.dart`): the same
/// three-stop diagonal gradient, the same 34px bottom radius, the same
/// translucent decorative circles, the same circular icon button and module
/// chip row, and the same strong centered title over a lighter subtitle.
/// Only the wording is this screen's own.
///
/// Every color comes from [theme], so the header follows the module the
/// reviewed attempt belongs to.
class _FeedbackGradientHeader extends StatelessWidget {
  const _FeedbackGradientHeader({
    required this.theme,
    required this.moduleNo,
    required this.summaryCard,
  });

  final _ModuleTheme theme;

  /// Null while the attempt's module is still unknown; the badge and the
  /// module subtitle are then left out rather than guessed.
  final int? moduleNo;

  /// The summary card that overlaps the bottom of the header, or null while
  /// there is no score to show (loading, error, empty).
  final Widget? summaryCard;

  /// How far the summary card hangs below the gradient.
  static const double _cardOverhang = 80;

  @override
  Widget build(BuildContext context) {
    final hasCard = summaryCard != null;

    final gradient = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.gradientDeep,
            theme.gradientDark,
            theme.gradientBase,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: 18,
            child: _GlowCircle(
              size: 140,
              opacity: 0.18,
              color: theme.onGradient,
            ),
          ),
          Positioned(
            left: -42,
            top: 112,
            child: _GlowCircle(
              size: 120,
              opacity: 0.14,
              color: theme.onGradient,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 6, 18, hasCard ? 82 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        color: theme.onGradient,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (moduleNo != null)
                        _ModuleBadge(theme: theme, moduleNo: moduleNo!),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t(context, 'Answer Feedback', 'Paliwanag sa Sagot'),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      color: theme.onGradient,
                      fontFamily: 'Poppins',
                      fontSize: 25,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (moduleNo != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      context.tr('module_${moduleNo}_full_header'),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        color: theme.onGradient.withValues(alpha: 0.88),
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!hasCard) return gradient;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [gradient, const SizedBox(height: _cardOverhang)],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: summaryCard!,
        ),
      ],
    );
  }
}

/// Translucent decorative circle, matching the intro screen's `_GlowCircle`.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.opacity,
    required this.color,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Circular translucent action button, matching the intro screen's
/// `_CircleIconButton`. Navigation behaviour is unchanged — it simply pops.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

/// "MODULE n" chip sitting in the header, matching the intro screen's badge.
class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.theme, required this.moduleNo});

  final _ModuleTheme theme;
  final int moduleNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.onGradient.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.onGradient.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(theme.icon, color: theme.onGradient, size: 16),
          const SizedBox(width: 6),
          Text(
            context.tr('module_$moduleNo'),
            softWrap: false,
            style: TextStyle(
              color: theme.onGradient,
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// English/Tagalog label for an `assessments.type` value, or null when the
/// type could not be resolved (the line is then simply left out).
String? _assessmentTypeLabel(BuildContext context, String? type) {
  switch (type) {
    case 'pre':
      return t(context, 'Pre-Assessment', 'Paunang Pagsusulit');
    case 'post':
      return t(context, 'Post-Assessment', 'Panghuling Pagsusulit');
    default:
      return null;
  }
}

/// Rounded summary card that overlaps the gradient header, styled after the
/// Pre-Assessment Introduction screen's `_AssessmentIntroCard`: generous
/// corner radius, soft deep shadow, and a gradient rounded-square icon tile.
///
/// It carries the whole result summary in one glance — which module and which
/// assessment type the attempt was, the assessment's own title, the "Review
/// Your Answers" heading, the score, and a slim progress bar for that score.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.correctCount,
    required this.totalQuestions,
    required this.assessmentTitle,
    required this.assessmentType,
    required this.moduleNo,
    required this.theme,
  });

  final int correctCount;
  final int totalQuestions;
  final String? assessmentTitle;
  final String? assessmentType;
  final int? moduleNo;
  final _ModuleTheme theme;

  @override
  Widget build(BuildContext context) {
    final title = assessmentTitle?.trim() ?? '';
    final typeLabel = _assessmentTypeLabel(context, assessmentType);

    // "MODULE 1 · PRE-ASSESSMENT" — whichever of the two is known.
    final metaParts = <String>[
      if (moduleNo != null) context.tr('module_$moduleNo'),
      if (typeLabel != null) typeLabel.toUpperCase(),
    ];

    final progress = totalQuestions > 0 ? correctCount / totalQuestions : 0.0;
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 30,
            offset: const Offset(0, 16),
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
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.gradientBase, theme.gradientDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accent.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(theme.icon, color: theme.onGradient, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metaParts.isNotEmpty) ...[
                      Text(
                        metaParts.join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          height: 1.2,
                          letterSpacing: 0.7,
                          color: theme.accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      t(
                        context,
                        'Review Your Answers',
                        'Suriin ang Iyong mga Sagot',
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        height: 1.15,
                        letterSpacing: -0.2,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          height: 1.28,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: _kSuccess,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t(
                    context,
                    '$correctCount / $totalQuestions Correct',
                    '$correctCount / $totalQuestions Tama',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: _kSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _ScoreBar(value: progress),
        ],
      ),
    );
  }
}

/// Slim rounded score bar. The fill is always the semantic green because it
/// measures correct answers, not the module's brand.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // Explicit width: the summary Column hands its children loose
          // constraints, under which an unsized bar would collapse to zero.
          width: double.infinity,
          height: 7,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _kTrack,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) {
                  return Container(
                    width: constraints.maxWidth * animated,
                    decoration: BoxDecoration(
                      color: _kSuccess,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Segmented All / Correct / Wrong control that filters the review list.
/// The selected pill wears the semantic color of what it shows — the module
/// accent for "All", green for "Correct", red for "Wrong".
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.theme,
    required this.selected,
    required this.allCount,
    required this.correctCount,
    required this.wrongCount,
    required this.onChanged,
  });

  final _ModuleTheme theme;
  final _ReviewFilter selected;
  final int allCount;
  final int correctCount;
  final int wrongCount;
  final ValueChanged<_ReviewFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: t(context, 'All', 'Lahat'),
              count: allCount,
              selected: selected == _ReviewFilter.all,
              activeColor: theme.accent,
              theme: theme,
              onTap: () => onChanged(_ReviewFilter.all),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: t(context, 'Correct', 'Tama'),
              count: correctCount,
              selected: selected == _ReviewFilter.correct,
              activeColor: _kSuccess,
              theme: theme,
              onTap: () => onChanged(_ReviewFilter.correct),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: t(context, 'Wrong', 'Mali'),
              count: wrongCount,
              selected: selected == _ReviewFilter.wrong,
              activeColor: _kError,
              theme: theme,
              onTap: () => onChanged(_ReviewFilter.wrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.activeColor,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color activeColor;
  final _ModuleTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 36,
      decoration: BoxDecoration(
        color: selected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      // Transparent Material so the tap ripple draws above the pill's own
      // fill instead of behind it on the Scaffold's Material.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: Text(
                '$label  $count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: -0.1,
                  color: selected ? Colors.white : theme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle floating "Question n of N" pill that fades in while the review list
/// is scrolled. Purely an orientation aid — it is not interactive.
class _ReviewProgressPill extends StatelessWidget {
  const _ReviewProgressPill({
    required this.theme,
    required this.current,
    required this.total,
  });

  final _ModuleTheme theme;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        t(
          context,
          'Question $current of $total',
          'Tanong $current ng $total',
        ),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.1,
          color: theme.onGradient,
        ),
      ),
    );
  }
}

/// Shown when the active filter matches none of the reviewed questions —
/// e.g. "Wrong" on a perfect attempt.
class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.theme, required this.filter});

  final _ModuleTheme theme;
  final _ReviewFilter filter;

  @override
  Widget build(BuildContext context) {
    final isWrongFilter = filter == _ReviewFilter.wrong;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(
            isWrongFilter
                ? Icons.check_circle_rounded
                : Icons.filter_alt_off_rounded,
            color: isWrongFilter ? _kSuccess : theme.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            isWrongFilter
                ? t(
                    context,
                    'No wrong answers to review.',
                    'Walang maling sagot na susuriin.',
                  )
                : t(
                    context,
                    'No correct answers to review.',
                    'Walang tamang sagot na susuriin.',
                  ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One reviewed question. The prompt is the loudest thing in the card; the
/// badge row, the answer blocks, and the explanation all sit around it in
/// steadily lighter weights.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({super.key, required this.item, required this.theme});

  final _FeedbackItem item;
  final _ModuleTheme theme;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isCorrect ? _kSuccess : _kError;
    final statusBg = item.isCorrect ? _kSuccessSoft : _kErrorSoft;
    final prompt = LocalizedDbText.pick(
      context,
      item.questionRow,
      'prompt',
      'prompt_tl',
    );
    final explanation = LocalizedDbText.pick(
      context,
      item.questionRow,
      'explanation',
      'explanation_tl',
    );

    final selectedText = item.selectedOption != null
        ? LocalizedDbText.pick(
            context,
            item.selectedOption!,
            'option_text',
            'option_text_tl',
          )
        : t(context, 'Not answered', 'Hindi nasagutan');

    final correctText = item.correctOption != null
        ? LocalizedDbText.pick(
            context,
            item.correctOption!,
            'option_text',
            'option_text_tl',
          )
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Question number stays on the left...
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t(
                    context,
                    'Question ${item.questionNo}',
                    'Tanong ${item.questionNo}',
                  ),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: theme.accent,
                  ),
                ),
              ),
              const Spacer(),
              // ...and the Correct / Wrong status stays on the right.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: statusColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isCorrect
                          ? t(context, 'Correct', 'Tama')
                          : t(context, 'Wrong', 'Mali'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            prompt,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              height: 1.34,
              letterSpacing: -0.2,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _AnswerBlock(
            label: t(context, 'Your Answer', 'Iyong Sagot'),
            text: selectedText,
            color: statusColor,
            background: statusBg,
            theme: theme,
          ),
          if (!item.isCorrect && correctText.isNotEmpty) ...[
            const SizedBox(height: 6),
            _AnswerBlock(
              label: t(context, 'Correct Answer', 'Tamang Sagot'),
              text: correctText,
              color: _kSuccess,
              background: _kSuccessSoft,
              theme: theme,
            ),
          ],
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              decoration: BoxDecoration(
                // Soft module tint, no outline — deliberately lighter than the
                // answer blocks so it reads as supporting detail.
                color: theme.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: theme.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(context, 'Explanation', 'Paliwanag'),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.2,
                            color: theme.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          explanation,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            height: 1.42,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tinted answer row with a semantic color rail down its left edge. The rail
/// replaces the old full outline so the block sits quieter under the prompt.
class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({
    required this.label,
    required this.text,
    required this.color,
    required this.background,
    required this.theme,
  });

  final String label;
  final String text;
  final Color color;
  final Color background;
  final _ModuleTheme theme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        color: background,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.2,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        text,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.34,
                          color: theme.textPrimary,
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
    );
  }
}

/// Closing action after the last reviewed question.
class _BackToModuleButton extends StatelessWidget {
  const _BackToModuleButton({required this.theme, required this.onTap});

  final _ModuleTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.gradientBase, theme.gradientDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.accent.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                color: theme.onGradient,
                size: 19,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t(context, 'Back to Module', 'Bumalik sa Modyul'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    letterSpacing: 0.1,
                    color: theme.onGradient,
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
