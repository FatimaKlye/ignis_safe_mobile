import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile_progress_sync.dart';

const Color kBrandBlue = Color(0xFF2563EB);
const Color kBrandBlueDark = Color(0xFF1D4ED8);
const Color kBrandBlueSoft = Color(0xFFEFF6FF);
const Color kDarkText = Color(0xFF1F2937);
const Color kSoftBg = Color(0xFFF8FAFC);

class PostAssessmentElectricalPage extends StatefulWidget {
  const PostAssessmentElectricalPage({super.key});

  @override
  State<PostAssessmentElectricalPage> createState() =>
      _PostAssessmentElectricalPageState();
}

class _PostAssessmentElectricalPageState
    extends State<PostAssessmentElectricalPage> {
  static const int _moduleNo = 3;
  static const String _assessmentType = 'post';

  final PageController _pageCtrl = PageController();
  final Map<int, TextEditingController> _essayControllers = {};

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSummary = false;
  bool _showReview = false;
  bool _editingFromSummary = false;

  String? _moduleId;
  String? _assessmentId;
  String? _attemptId;
  String _assessmentTitle = 'Post-Assessment';
  String _moduleDisplayTitle = '';
  String _instructions = '';

  int _currentIndex = 0;
  int _score = 0;

  List<_QuestionVm> _questions = [];
  List<String?> _selectedOptionIds = [];
  List<String?> _writtenAnswers = [];
  Set<int> _flaggedIndexes = {};

  SupabaseClient get _supabase => Supabase.instance.client;

  User get _user {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No active user session.');
    }
    return user;
  }

  @override
  void initState() {
    super.initState();
    _loadOrCreateAttempt();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isEssay(_QuestionVm q) => q.type == 'essay';
  bool _isMcq(_QuestionVm q) => q.type == 'multiple_choice';

  int get _scoredTotal => _questions.where(_isMcq).length;

  int get _answeredCount {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_isEssay(_questions[i])) {
        if ((_writtenAnswers[i] ?? '').trim().isNotEmpty) count++;
      } else {
        if (_selectedOptionIds[i] != null) count++;
      }
    }
    return count;
  }

  int get _unansweredCount => _questions.length - _answeredCount;

  bool get _hasUnansweredQuestions => _unansweredCount > 0;

  List<int> get _unansweredIndexes {
    final result = <int>[];
    for (int i = 0; i < _questions.length; i++) {
      final unanswered = _isEssay(_questions[i])
          ? (_writtenAnswers[i] ?? '').trim().isEmpty
          : _selectedOptionIds[i] == null;
      if (unanswered) result.add(i);
    }
    return result;
  }

  void _rebuildEssayControllers(
    List<_QuestionVm> questions,
    List<String?> writtenAnswers,
  ) {
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    _essayControllers.clear();

    for (int i = 0; i < questions.length; i++) {
      if (_isEssay(questions[i])) {
        _essayControllers[i] =
            TextEditingController(text: writtenAnswers[i] ?? '');
      }
    }
  }

  List<_QuestionVm> _orderedQuestions(List<_QuestionVm> questions) {
    final mcq = questions.where(_isMcq).toList()..shuffle();
    final essay = questions.where(_isEssay).toList();
    return [...mcq, ...essay];
  }

  Future<void> _loadOrCreateAttempt({bool forceNewAttempt = false}) async {
    try {
      setState(() => _isLoading = true);

      final user = _user;

      final moduleRow = await _supabase
          .from('modules')
          .select('id, title')
          .eq('module_no', _moduleNo)
          .maybeSingle();

      if (moduleRow == null) {
        throw Exception('Module $_moduleNo not found in database.');
      }

      final moduleId = moduleRow['id'].toString();
      final moduleDisplayTitle = (moduleRow['title'] ?? '').toString();

      final assessmentRow = await _supabase
          .from('assessments')
          .select('id, title, instructions')
          .eq('module_id', moduleId)
          .eq('type', _assessmentType)
          .maybeSingle();

      if (assessmentRow == null) {
        throw Exception('Post-assessment for module $_moduleNo was not found.');
      }

      final assessmentId = assessmentRow['id'].toString();
      final assessmentTitle =
          (assessmentRow['title'] ?? 'Post-Assessment').toString();
      final instructions = (assessmentRow['instructions'] ?? '').toString();

      final questionRows = await _supabase
          .from('assessment_questions')
          .select('id, question_no, prompt, explanation, question_type')
          .eq('assessment_id', assessmentId)
          .eq('is_active', true)
          .order('question_no');

      if (questionRows.isEmpty) {
        throw Exception('No active questions found for this assessment.');
      }

      final questionIds =
          questionRows.map((row) => row['id'].toString()).toList();

      final optionRows = await _supabase
          .from('assessment_options')
          .select(
            'id, question_id, option_key, option_text, is_correct, display_order',
          )
          .inFilter('question_id', questionIds)
          .order('question_id')
          .order('display_order');

      final optionsByQuestion = <String, List<_OptionVm>>{};
      for (final row in optionRows) {
        final questionId = row['question_id'].toString();
        optionsByQuestion.putIfAbsent(questionId, () => []);
        final rawDisplayOrder = row['display_order'];
        final displayOrder = rawDisplayOrder is num
            ? rawDisplayOrder.toInt()
            : int.tryParse((rawDisplayOrder ?? '').toString()) ?? 999;

        optionsByQuestion[questionId]!.add(
          _OptionVm(
            id: row['id'].toString(),
            key: (row['option_key'] ?? '').toString().toUpperCase(),
            text: (row['option_text'] ?? '').toString(),
            isCorrect: (row['is_correct'] ?? false) as bool,
            displayOrder: displayOrder,
          ),
        );
      }

      for (final entry in optionsByQuestion.entries) {
        entry.value.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      }

      final baseQuestions = questionRows.map((row) {
        final questionId = row['id'].toString();
        return _QuestionVm(
          id: questionId,
          prompt: (row['prompt'] ?? '').toString(),
          explanation: (row['explanation'] ?? '').toString(),
          type: ((row['question_type'] ?? 'multiple_choice').toString()),
          options: optionsByQuestion[questionId] ?? [],
        );
      }).toList();

      if (baseQuestions.any((q) => _isMcq(q) && q.options.isEmpty)) {
        throw Exception(
          'One or more multiple-choice questions do not have options.',
        );
      }

      String attemptId;
      List<_QuestionVm> orderedQuestions;
      List<String?> selectedOptionIds;
      List<String?> writtenAnswers;
      Set<int> flaggedIndexes;

      if (!forceNewAttempt) {
        final attemptRows = await _supabase
            .from('assessment_attempts')
            .select('id, started_at')
            .eq('user_id', user.id)
            .eq('assessment_id', assessmentId)
            .eq('status', 'in_progress')
            .order('started_at', ascending: false)
            .limit(1);

        if (attemptRows.isNotEmpty) {
          attemptId = attemptRows.first['id'].toString();

          final savedRows = await _supabase
              .from('assessment_attempt_answers')
              .select(
                'question_id, selected_option_id, answer_text, is_flagged, display_order',
              )
              .eq('attempt_id', attemptId)
              .order('display_order');

          if (savedRows.isEmpty) {
            final created = await _createAnswerRowsForExistingAttempt(
              attemptId: attemptId,
              questions: baseQuestions,
            );
            orderedQuestions = created.questions;
            selectedOptionIds =
                List<String?>.filled(orderedQuestions.length, null);
            writtenAnswers =
                List<String?>.filled(orderedQuestions.length, null);
            flaggedIndexes = {};
          } else {
            final existingQuestionIds = savedRows
                .map((row) => row['question_id'].toString())
                .toSet();

            final missingQuestions = baseQuestions
                .where((q) => !existingQuestionIds.contains(q.id))
                .toList();

            if (missingQuestions.isNotEmpty) {
              final startOrder = savedRows.length;
              final orderedMissing = _orderedQuestions(missingQuestions);

              await _supabase.from('assessment_attempt_answers').insert(
                List.generate(
                  orderedMissing.length,
                  (index) => {
                    'attempt_id': attemptId,
                    'question_id': orderedMissing[index].id,
                    'display_order': startOrder + index,
                    'is_flagged': false,
                  },
                ),
              );
            }

            final refreshedSavedRows = await _supabase
                .from('assessment_attempt_answers')
                .select(
                  'question_id, selected_option_id, answer_text, is_flagged, display_order',
                )
                .eq('attempt_id', attemptId)
                .order('display_order');

            final questionMap = {for (final q in baseQuestions) q.id: q};

            orderedQuestions = [];
            selectedOptionIds = [];
            writtenAnswers = [];
            flaggedIndexes = {};

            for (int i = 0; i < refreshedSavedRows.length; i++) {
              final row = refreshedSavedRows[i];
              final questionId = row['question_id'].toString();
              final question = questionMap[questionId];
              if (question == null) continue;

              orderedQuestions.add(question);
              selectedOptionIds.add(
                row['selected_option_id'] == null
                    ? null
                    : row['selected_option_id'].toString(),
              );
              writtenAnswers.add(
                row['answer_text'] == null
                    ? null
                    : row['answer_text'].toString(),
              );

              if ((row['is_flagged'] ?? false) as bool) {
                flaggedIndexes.add(i);
              }
            }

            if (orderedQuestions.isEmpty) {
              final created = await _createNewAttempt(
                userId: user.id,
                assessmentId: assessmentId,
                questions: baseQuestions,
              );
              attemptId = created.attemptId;
              orderedQuestions = created.questions;
              selectedOptionIds =
                  List<String?>.filled(orderedQuestions.length, null);
              writtenAnswers =
                  List<String?>.filled(orderedQuestions.length, null);
              flaggedIndexes = {};
            }
          }
        } else {
          final created = await _createNewAttempt(
            userId: user.id,
            assessmentId: assessmentId,
            questions: baseQuestions,
          );
          attemptId = created.attemptId;
          orderedQuestions = created.questions;
          selectedOptionIds =
              List<String?>.filled(orderedQuestions.length, null);
          writtenAnswers =
              List<String?>.filled(orderedQuestions.length, null);
          flaggedIndexes = {};
        }
      } else {
        final created = await _createNewAttempt(
          userId: user.id,
          assessmentId: assessmentId,
          questions: baseQuestions,
        );
        attemptId = created.attemptId;
        orderedQuestions = created.questions;
        selectedOptionIds = List<String?>.filled(orderedQuestions.length, null);
        writtenAnswers = List<String?>.filled(orderedQuestions.length, null);
        flaggedIndexes = {};
      }

      _rebuildEssayControllers(orderedQuestions, writtenAnswers);

      if (!mounted) return;

      setState(() {
        _moduleId = moduleId;
        _assessmentId = assessmentId;
        _attemptId = attemptId;
        _assessmentTitle = assessmentTitle;
        _moduleDisplayTitle = moduleDisplayTitle;
        _instructions = instructions;
        _questions = orderedQuestions;
        _selectedOptionIds = selectedOptionIds;
        _writtenAnswers = writtenAnswers;
        _flaggedIndexes = flaggedIndexes;
        _currentIndex = 0;
        _score = 0;
        _showSummary = false;
        _showReview = false;
        _editingFromSummary = false;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(0);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      await _showInfoDialog(
        title: 'Failed to load post-assessment',
        message: '$e',
        buttonText: 'OK',
      );
    }
  }

  Future<_CreatedAttempt> _createNewAttempt({
    required String userId,
    required String assessmentId,
    required List<_QuestionVm> questions,
  }) async {
    final ordered = _orderedQuestions(questions);

    final insertedAttempt = await _supabase
        .from('assessment_attempts')
        .insert({
          'user_id': userId,
          'assessment_id': assessmentId,
          'status': 'in_progress',
          'total_questions': ordered.length,
          'correct_count': 0,
          'score': 0,
        })
        .select('id')
        .single();

    final attemptId = insertedAttempt['id'].toString();

    await _supabase.from('assessment_attempt_answers').insert(
      List.generate(
        ordered.length,
        (index) => {
          'attempt_id': attemptId,
          'question_id': ordered[index].id,
          'display_order': index,
          'is_flagged': false,
        },
      ),
    );

    return _CreatedAttempt(attemptId: attemptId, questions: ordered);
  }

  Future<_CreatedAttempt> _createAnswerRowsForExistingAttempt({
    required String attemptId,
    required List<_QuestionVm> questions,
  }) async {
    final ordered = _orderedQuestions(questions);

    await _supabase.from('assessment_attempt_answers').insert(
      List.generate(
        ordered.length,
        (index) => {
          'attempt_id': attemptId,
          'question_id': ordered[index].id,
          'display_order': index,
          'is_flagged': false,
        },
      ),
    );

    return _CreatedAttempt(attemptId: attemptId, questions: ordered);
  }

  Future<void> _handleRefresh() async {
    if (_showReview) {
      final confirmed = await _showConfirmDialog(
        title: 'Start new attempt?',
        message:
            'You already finished this post-assessment. Starting again will generate a new attempt.',
        confirmText: 'New Attempt',
        cancelText: 'Cancel',
      );

      if (confirmed == true) {
        await _loadOrCreateAttempt(forceNewAttempt: true);
      }
      return;
    }

    await _showInfoDialog(
      title: 'Current attempt preserved',
      message:
          'This post-assessment is still unfinished, so refresh will keep the same attempt and the same questions.',
      buttonText: 'OK',
    );

    await _loadOrCreateAttempt(forceNewAttempt: false);
  }

  Future<void> _selectAnswer(int questionIndex, String optionId) async {
    setState(() => _selectedOptionIds[questionIndex] = optionId);

    try {
      await _supabase.from('assessment_attempt_answers').upsert(
        {
          'attempt_id': _attemptId,
          'question_id': _questions[questionIndex].id,
          'selected_option_id': optionId,
          'answer_text': null,
          'is_correct': _isCorrectSelection(questionIndex, optionId),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'attempt_id,question_id',
      );
    } catch (_) {}
  }

  Future<void> _saveEssayAnswer(int questionIndex, String value) async {
    setState(() => _writtenAnswers[questionIndex] = value);

    try {
      await _supabase.from('assessment_attempt_answers').upsert(
        {
          'attempt_id': _attemptId,
          'question_id': _questions[questionIndex].id,
          'selected_option_id': null,
          'answer_text': value.trim().isEmpty ? null : value.trim(),
          'is_correct': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'attempt_id,question_id',
      );
    } catch (_) {}
  }

  Future<void> _toggleFlag(int questionIndex) async {
    final newFlagState = !_flaggedIndexes.contains(questionIndex);

    setState(() {
      if (newFlagState) {
        _flaggedIndexes.add(questionIndex);
      } else {
        _flaggedIndexes.remove(questionIndex);
      }
    });

    try {
      await _supabase.from('assessment_attempt_answers').upsert(
        {
          'attempt_id': _attemptId,
          'question_id': _questions[questionIndex].id,
          'is_flagged': newFlagState,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'attempt_id,question_id',
      );
    } catch (_) {}
  }

  bool _isCorrectSelection(int questionIndex, String optionId) {
    return _questions[questionIndex]
        .options
        .any((opt) => opt.id == optionId && opt.isCorrect);
  }

  _OptionVm? _selectedOptionFor(int questionIndex) {
    final selectedId = _selectedOptionIds[questionIndex];
    if (selectedId == null) return null;

    for (final option in _questions[questionIndex].options) {
      if (option.id == selectedId) return option;
    }
    return null;
  }

  _OptionVm? _correctOptionFor(int questionIndex) {
    if (_questions[questionIndex].options.isEmpty) return null;
    return _questions[questionIndex].options.firstWhere(
      (opt) => opt.isCorrect,
      orElse: () => _questions[questionIndex].options.first,
    );
  }

  String _optionDisplay(_QuestionVm question, _OptionVm option) {
    final index = question.options.indexWhere((opt) => opt.id == option.id);
    final letter = index >= 0 ? String.fromCharCode(65 + index) : option.key;
    return '$letter. ${option.text}';
  }

  String _reviewExplanationFor(int questionIndex) {
    final question = _questions[questionIndex];
    final correct = _correctOptionFor(questionIndex);

    if (question.explanation.trim().isNotEmpty) {
      return question.explanation.trim();
    }

    if (correct != null) {
      return 'The correct answer is "${correct.text}" based on the electrical fire simulation.';
    }

    return 'Review the electrical fire simulation steps from this module.';
  }

  void _goNext() {
    if (_editingFromSummary) {
      setState(() {
        _showSummary = true;
        _editingFromSummary = false;
      });
      return;
    }

    if (_currentIndex < _questions.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _showSummary = true);
    }
  }

  void _goBack() {
    if (_showReview) {
      Navigator.pop(context);
      return;
    }

    if (_showSummary) {
      setState(() {
        _showSummary = false;
        _editingFromSummary = false;
      });
      return;
    }

    if (_editingFromSummary) {
      setState(() {
        _showSummary = true;
        _editingFromSummary = false;
      });
      return;
    }

    if (_currentIndex == 0) {
      Navigator.pop(context);
      return;
    }

    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _openQuestionFromSummary(int index) {
    setState(() {
      _showSummary = false;
      _showReview = false;
      _editingFromSummary = true;
      _currentIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(index);
      }
    });
  }

  Future<void> _submitAssessment() async {
    if (_hasUnansweredQuestions) {
      await _showInfoDialog(
        title: 'Cannot submit yet',
        message:
            'You must answer all questions before submitting the post-assessment.',
        buttonText: 'OK',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Submit Post-Assessment',
      message:
          'Answered: $_answeredCount / ${_questions.length}\n\nAfter submission, you will see your score for the 4 multiple-choice questions and your written reflection.',
      confirmText: 'Submit',
      cancelText: 'Review Again',
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      int correctCount = 0;

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];

        if (_isEssay(question)) {
          final answerText = (_writtenAnswers[i] ?? '').trim();

          await _supabase.from('assessment_attempt_answers').upsert(
            {
              'attempt_id': _attemptId,
              'question_id': question.id,
              'selected_option_id': null,
              'answer_text': answerText.isEmpty ? null : answerText,
              'is_flagged': _flaggedIndexes.contains(i),
              'display_order': i,
              'is_correct': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'attempt_id,question_id',
          );
        } else {
          final selectedId = _selectedOptionIds[i];
          final isCorrect =
              selectedId == null ? false : _isCorrectSelection(i, selectedId);

          if (isCorrect) correctCount++;

          await _supabase.from('assessment_attempt_answers').upsert(
            {
              'attempt_id': _attemptId,
              'question_id': question.id,
              'selected_option_id': selectedId,
              'answer_text': null,
              'is_flagged': _flaggedIndexes.contains(i),
              'display_order': i,
              'is_correct': isCorrect,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'attempt_id,question_id',
          );
        }
      }

      final scorePercent =
          _scoredTotal == 0 ? 0 : (correctCount / _scoredTotal) * 100;

      await _supabase.from('assessment_attempts').update({
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'submitted',
        'correct_count': correctCount,
        'score': scorePercent,
      }).eq('id', _attemptId!);

      final progressRow = await _supabase
          .from('module_progress')
          .select('id')
          .eq('user_id', _user.id)
          .eq('module_id', _moduleId!)
          .maybeSingle();

      if (progressRow == null) {
        await _supabase.from('module_progress').insert({
          'user_id': _user.id,
          'module_id': _moduleId,
          'post_test_completed_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await _supabase.from('module_progress').update({
          'post_test_completed_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', progressRow['id']);
      }

      await ProfileProgressSync.syncCompletedSimulations();

      if (!mounted) return;

      setState(() {
        _score = correctCount;
        _showSummary = false;
        _showReview = true;
      });
    } catch (e) {
      if (!mounted) return;

      await _showInfoDialog(
        title: 'Submission failed',
        message: '$e',
        buttonText: 'OK',
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message, style: const TextStyle(height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
    required String buttonText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message, style: const TextStyle(height: 1.45)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: _StatsRow(
            answered: _answeredCount,
            total: _questions.length,
            flagged: _flaggedIndexes.length,
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final question = _questions[index];
              final selectedId = _selectedOptionIds[index];
              final isFlagged = _flaggedIndexes.contains(index);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionHeaderCard(
                      questionNumber: index + 1,
                      totalQuestions: _questions.length,
                      question: question.prompt,
                      isFlagged: isFlagged,
                      onFlagTap: () => _toggleFlag(index),
                    ),
                    const SizedBox(height: 16),
                    if (_isMcq(question)) ...[
                      ...question.options.asMap().entries.map((entry) {
                        final option = entry.value;
                        final selected = selectedId == option.id;
                        final label = String.fromCharCode(65 + entry.key);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionCard(
                            label: label,
                            text: option.text,
                            selected: selected,
                            onTap: () => _selectAnswer(index, option.id),
                          ),
                        );
                      }),
                    ] else ...[
                      _EssayAnswerCard(
                        controller: _essayControllers[index]!,
                        onChanged: (value) => _saveEssayAnswer(index, value),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _HintCard(
                      icon: Icons.info_outline_rounded,
                      text: _isEssay(question)
                          ? 'Write 1 to 2 sentences about what you learned from the electrical fire simulation.'
                          : 'Use the summary to jump back to any question before submitting.',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Column(
        children: [
          _SummaryHeaderCard(
            answered: _answeredCount,
            total: _questions.length,
            flagged: _flaggedIndexes.length,
            hasUnanswered: _hasUnansweredQuestions,
            unansweredCount: _unansweredCount,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final question = _questions[index];
                final selected = _selectedOptionFor(index);

                final selectedAnswer = _isEssay(question)
                    ? ((_writtenAnswers[index] ?? '').trim().isEmpty
                        ? 'No reflection written'
                        : _writtenAnswers[index]!.trim())
                    : (selected == null
                        ? 'No answer selected'
                        : _optionDisplay(question, selected));

                final answered = _isEssay(question)
                    ? ((_writtenAnswers[index] ?? '').trim().isNotEmpty)
                    : selected != null;

                return _SummaryCard(
                  questionNumber: index + 1,
                  question: question.prompt,
                  selectedAnswer: selectedAnswer,
                  answered: answered,
                  flagged: _flaggedIndexes.contains(index),
                  onEdit: () => _openQuestionFromSummary(index),
                  onFlagTap: () => _toggleFlag(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Column(
        children: [
          _ReviewTopCard(score: _score, total: _scoredTotal),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final question = _questions[index];

                if (_isEssay(question)) {
                  return _ReviewCard(
                    questionNumber: index + 1,
                    question: question.prompt,
                    userAnswer: (_writtenAnswers[index] ?? '').trim().isEmpty
                        ? 'No reflection submitted'
                        : _writtenAnswers[index]!.trim(),
                    correctAnswer: '',
                    isCorrect: false,
                    explanation: question.explanation,
                    isEssay: true,
                  );
                }

                final selected = _selectedOptionFor(index);
                final correct = _correctOptionFor(index);
                final isCorrect =
                    selected != null && correct != null && selected.id == correct.id;

                return _ReviewCard(
                  questionNumber: index + 1,
                  question: question.prompt,
                  userAnswer: selected == null
                      ? 'No answer selected'
                      : _optionDisplay(question, selected),
                  correctAnswer: correct == null
                      ? 'No correct answer configured'
                      : _optionDisplay(question, correct),
                  isCorrect: isCorrect,
                  explanation: isCorrect ? null : _reviewExplanationFor(index),
                  isEssay: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_showReview) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBrandBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: kBrandBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlueDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _loadOrCreateAttempt(forceNewAttempt: true),
                child: const Text(
                  'New Attempt',
                  style: TextStyle(
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

    if (_showSummary) {
      final locked = _hasUnansweredQuestions;

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBrandBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _showSummary = false;
                    _editingFromSummary = false;
                  });
                },
                child: const Text(
                  'Back to Questions',
                  style: TextStyle(
                    color: kBrandBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: locked ? Colors.grey.shade400 : kBrandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submitAssessment,
                child: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : locked
                          ? 'Complete All'
                          : 'Submit',
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

    final isLast = _currentIndex == _questions.length - 1;
    final nextLabel = _editingFromSummary
        ? 'Review Summary'
        : (isLast ? 'Review Summary' : 'Next');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBrandBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _goBack,
              child: Text(
                _editingFromSummary
                    ? 'Back to Summary'
                    : (_currentIndex == 0 ? 'Exit' : 'Back'),
                style: const TextStyle(
                  color: kBrandBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _goNext,
              child: Text(
                nextLabel,
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

  @override
  Widget build(BuildContext context) {
    final headerTitle = _moduleDisplayTitle.trim().isEmpty
        ? 'Electrical Fire: Causes, Safe Actions, and Prevention'
        : _moduleDisplayTitle.trim();

    return Scaffold(
      backgroundColor: kSoftBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(left: 9, right: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(height: 15),
                              Center(
                                child: Text(
                                  _showReview ? 'Assessment Review' : 'Post-Assessment',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Padding(
                                padding: const EdgeInsets.only(left: 25),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kBrandBlue,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'MODULE 3',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        _showReview
                                            ? 'Your score for the graded items plus your written reflection'
                                            : headerTitle,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_instructions.trim().isNotEmpty &&
                                  !_showReview) ...[
                                const SizedBox(height: 15),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _instructions,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Expanded(
                          child: _showReview
                              ? _buildReviewView()
                              : _showSummary
                                  ? _buildSummaryView()
                                  : _buildQuizView(),
                        ),
                        _buildBottomBar(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CreatedAttempt {
  final String attemptId;
  final List<_QuestionVm> questions;

  const _CreatedAttempt({
    required this.attemptId,
    required this.questions,
  });
}

class _QuestionVm {
  final String id;
  final String prompt;
  final String explanation;
  final String type;
  final List<_OptionVm> options;

  const _QuestionVm({
    required this.id,
    required this.prompt,
    required this.explanation,
    required this.type,
    required this.options,
  });
}

class _OptionVm {
  final String id;
  final String key;
  final String text;
  final bool isCorrect;
  final int displayOrder;

  const _OptionVm({
    required this.id,
    required this.key,
    required this.text,
    required this.isCorrect,
    required this.displayOrder,
  });
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.answered,
    required this.total,
    required this.flagged,
  });

  final int answered;
  final int total;
  final int flagged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_outline_rounded,
            label: 'Answered',
            value: '$answered / $total',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.outlined_flag_rounded,
            label: 'Flagged',
            value: '$flagged',
            color: kBrandBlue,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
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

class _QuestionHeaderCard extends StatelessWidget {
  const _QuestionHeaderCard({
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.isFlagged,
    required this.onFlagTap,
  });

  final int questionNumber;
  final int totalQuestions;
  final String question;
  final bool isFlagged;
  final VoidCallback onFlagTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kBrandBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'QUESTION $questionNumber / $totalQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onFlagTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isFlagged
                        ? kBrandBlue.withOpacity(0.12)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isFlagged ? kBrandBlue : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFlagged
                            ? Icons.flag_rounded
                            : Icons.outlined_flag_rounded,
                        size: 16,
                        color: isFlagged ? kBrandBlue : kDarkText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFlagged ? 'Flagged' : 'Flag',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isFlagged ? kBrandBlue : kDarkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: kDarkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? kBrandBlue : Colors.black.withOpacity(0.08);
    final bgColor = selected ? kBrandBlue.withOpacity(0.08) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? kBrandBlue : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: kDarkText,
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

class _EssayAnswerCard extends StatelessWidget {
  const _EssayAnswerCard({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBrandBlue.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        minLines: 4,
        cursorColor: kBrandBlue,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText:
              'Write 1 to 2 sentences about what you learned from the electrical fire simulation.',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: kDarkText,
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kBrandBlueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBrandBlue.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kBrandBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeaderCard extends StatelessWidget {
  const _SummaryHeaderCard({
    required this.answered,
    required this.total,
    required this.flagged,
    required this.hasUnanswered,
    required this.unansweredCount,
  });

  final int answered;
  final int total;
  final int flagged;
  final bool hasUnanswered;
  final int unansweredCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasUnanswered
              ? Colors.orange.withOpacity(0.25)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Review all questions before you submit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: kDarkText,
            ),
          ),
          if (hasUnanswered) ...[
            const SizedBox(height: 8),
            Text(
              '$unansweredCount question(s) still need an answer.',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _StatsRow(
            answered: answered,
            total: total,
            flagged: flagged,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.answered,
    required this.flagged,
    required this.onEdit,
    required this.onFlagTap,
  });

  final int questionNumber;
  final String question;
  final String selectedAnswer;
  final bool answered;
  final bool flagged;
  final VoidCallback onEdit;
  final VoidCallback onFlagTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = answered ? const Color(0xFF16A34A) : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answered ? Colors.white : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: kBrandBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kBrandBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  answered ? 'Answered' : 'Unanswered',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ),
              if (flagged) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: kBrandBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Flagged',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kBrandBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onFlagTap,
                icon: Icon(
                  flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                  color: flagged ? kBrandBlue : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.4,
              color: kDarkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            selectedAnswer,
            style: TextStyle(
              color: answered ? Colors.black87 : Colors.orange.shade800,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Edit',
                style: TextStyle(
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

class _ReviewTopCard extends StatelessWidget {
  const _ReviewTopCard({
    required this.score,
    required this.total,
  });

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((score / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Post-Assessment Result',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kDarkText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score / $total',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: kBrandBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent% • scored questions only',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kBrandBlueDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.questionNumber,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.explanation,
    required this.isEssay,
  });

  final int questionNumber;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;
  final bool isEssay;

  @override
  Widget build(BuildContext context) {
    final statusColor = isEssay
        ? kBrandBlue
        : (isCorrect ? const Color(0xFF16A34A) : kBrandBlue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isEssay ? 'Reflection' : (isCorrect ? 'Correct' : 'Incorrect'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.4,
              color: kDarkText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isEssay ? 'Your Reflection' : 'Answer Review',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userAnswer,
            style: TextStyle(
              color: isEssay
                  ? kDarkText
                  : (isCorrect ? const Color(0xFF16A34A) : kBrandBlue),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (!isEssay) ...[
            const SizedBox(height: 12),
            const Text(
              'Correct Answer',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              correctAnswer,
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          if (explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isEssay ? 'Reflection Note' : 'Why this is wrong',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation!,
              style: const TextStyle(
                color: kDarkText,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

