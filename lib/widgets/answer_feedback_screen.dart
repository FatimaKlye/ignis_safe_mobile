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
  });

  final String attemptId;
  final String? assessmentTitle;

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

  _ModuleTheme get _theme => _ModuleTheme.forModuleNo(_moduleNo);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Resolves which module this attempt belongs to so the screen can wear that
  /// module's theme. Failures are non-fatal: the feedback still loads and the
  /// neutral theme is kept.
  Future<int?> _resolveModuleNo() async {
    try {
      final attemptRow = await _supabase
          .from('assessment_attempts')
          .select('module_id')
          .eq('id', widget.attemptId)
          .maybeSingle();

      final moduleId = attemptRow?['module_id']?.toString();
      if (moduleId == null || moduleId.isEmpty) return null;

      final moduleRow = await _supabase
          .from('modules')
          .select('module_no')
          .eq('id', moduleId)
          .maybeSingle();

      return (moduleRow?['module_no'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final moduleNo = await _resolveModuleNo();
    if (!mounted) return;
    setState(() => _moduleNo = moduleNo);

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        for (final item in _items) ...[
          _FeedbackCard(item: item, theme: theme),
          const SizedBox(height: 14),
        ],
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

  /// The white summary card that overlaps the bottom of the header, or null
  /// while there is no score to show (loading, error, empty).
  final Widget? summaryCard;

  /// How far the summary card hangs below the gradient.
  static const double _cardOverhang = 62;

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
              padding: EdgeInsets.fromLTRB(18, 6, 18, hasCard ? 74 : 28),
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
                  const SizedBox(height: 16),
                  Text(
                    t(context, 'Answer Feedback', 'Paliwanag sa Sagot'),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      color: theme.onGradient,
                      fontFamily: 'Poppins',
                      fontSize: 29,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (moduleNo != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      context.tr('module_${moduleNo}_full_header'),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        color: theme.onGradient.withValues(alpha: 0.88),
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        height: 1.32,
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
          left: 20,
          right: 20,
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

/// Rounded white summary card that overlaps the gradient header, styled after
/// the Pre-Assessment Introduction screen's `_AssessmentIntroCard`: generous
/// corner radius, soft deep shadow, and a gradient rounded-square icon tile.
/// The wording stays this screen's own.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.correctCount,
    required this.totalQuestions,
    required this.assessmentTitle,
    required this.theme,
  });

  final int correctCount;
  final int totalQuestions;
  final String? assessmentTitle;
  final _ModuleTheme theme;

  @override
  Widget build(BuildContext context) {
    final title = assessmentTitle?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.gradientBase, theme.gradientDark],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(theme.icon, color: theme.onGradient, size: 26),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.25,
                      letterSpacing: 0.2,
                      color: theme.accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  t(context, 'Review Your Answers', 'Suriin ang Iyong mga Sagot'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                    height: 1.15,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    t(
                      context,
                      '$correctCount out of $totalQuestions correct',
                      '$correctCount sa $totalQuestions ang tama',
                    ),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: theme.accent,
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

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item, required this.theme});

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                    fontSize: 11.5,
                    color: theme.accent,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isCorrect
                          ? t(context, 'Correct', 'Tama')
                          : t(context, 'Wrong', 'Mali'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prompt,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              height: 1.4,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _AnswerBlock(
            label: t(context, 'Your Answer', 'Iyong Sagot'),
            text: selectedText,
            color: statusColor,
            background: statusBg,
            theme: theme,
          ),
          if (!item.isCorrect && correctText.isNotEmpty) ...[
            const SizedBox(height: 8),
            _AnswerBlock(
              label: t(context, 'Correct Answer', 'Tamang Sagot'),
              text: correctText,
              color: _kSuccess,
              background: _kSuccessSoft,
              theme: theme,
            ),
          ],
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: theme.accent,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(context, 'Explanation', 'Paliwanag'),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          explanation,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            height: 1.45,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
