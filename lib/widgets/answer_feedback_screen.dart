import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        foregroundColor: theme.textPrimary,
        title: Text(
          t(context, 'Answer Feedback', 'Paliwanag sa Sagot'),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: theme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context, theme)),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _SummaryHeader(
          correctCount: _correctCount,
          totalQuestions: _items.length,
          assessmentTitle: widget.assessmentTitle,
          theme: theme,
        ),
        const SizedBox(height: 18),
        for (final item in _items) ...[
          _FeedbackCard(item: item, theme: theme),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              theme.icon,
              color: theme.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assessmentTitle != null && assessmentTitle!.trim().isNotEmpty)
                  Text(
                    assessmentTitle!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: theme.textSecondary,
                    ),
                  ),
                Text(
                  t(context, 'Review Your Answers', 'Suriin ang Iyong mga Sagot'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t(
                    context,
                    '$correctCount out of $totalQuestions correct',
                    '$correctCount sa $totalQuestions ang tama',
                  ),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: theme.textSecondary,
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
