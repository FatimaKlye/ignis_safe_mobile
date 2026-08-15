import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/language_controller.dart';
import '../localization/localized_db_text.dart';

const Color _kRed = Color(0xFFB11217);
const Color _kRedSoft = Color(0xFFFFE8EA);
const Color _kBackground = Color(0xFFFFF7F7);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF1F1F1F);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE8D8D9);
const Color _kSuccess = Color(0xFF198754);
const Color _kSuccessSoft = Color(0xFFE8F5EC);
const Color _kError = Color(0xFFD32F2F);
const Color _kErrorSoft = Color(0xFFFDEBEA);
const Color _kShadow = Color(0x1A000000);

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        foregroundColor: _kTextPrimary,
        title: Text(
          t(context, 'Answer Feedback', 'Paliwanag sa Sagot'),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: _kTextPrimary,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kRed),
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
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
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
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: _kTextSecondary,
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
        ),
        const SizedBox(height: 18),
        for (final item in _items) ...[
          _FeedbackCard(item: item),
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
  });

  final int correctCount;
  final int totalQuestions;
  final String? assessmentTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kRedSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: _kRed,
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
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _kTextSecondary,
                    ),
                  ),
                Text(
                  t(context, 'Review Your Answers', 'Suriin ang Iyong mga Sagot'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t(
                    context,
                    '$correctCount out of $totalQuestions correct',
                    '$correctCount sa $totalQuestions ang tama',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: _kTextSecondary,
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
  const _FeedbackCard({required this.item});

  final _FeedbackItem item;

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
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 4)),
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
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t(
                    context,
                    'Question ${item.questionNo}',
                    'Tanong ${item.questionNo}',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: _kRed,
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              height: 1.4,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _AnswerBlock(
            label: t(context, 'Your Answer', 'Iyong Sagot'),
            text: selectedText,
            color: statusColor,
            background: statusBg,
          ),
          if (!item.isCorrect && correctText.isNotEmpty) ...[
            const SizedBox(height: 8),
            _AnswerBlock(
              label: t(context, 'Correct Answer', 'Tamang Sagot'),
              text: correctText,
              color: _kSuccess,
              background: _kSuccessSoft,
            ),
          ],
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _kRed,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(context, 'Explanation', 'Paliwanag'),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: _kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          explanation,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            height: 1.45,
                            color: _kTextSecondary,
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
  });

  final String label;
  final String text;
  final Color color;
  final Color background;

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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
              color: _kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
