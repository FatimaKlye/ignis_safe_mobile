import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/localized_db_text.dart';

import 'pre_assess_completion_page.dart';

const Color kKitchenAmber = Color(0xFFF59E0B);
const Color kKitchenAmberDark = Color(0xFFEA580C);
const Color kKitchenAmberSoft = Color(0xFFFFFBEB);
const Color kDarkText = Color(0xFF1F2937);
const Color kSoftBg = Color(0xFFF8FAFC);

class PreAssessmentKitchenPage extends StatefulWidget {
  const PreAssessmentKitchenPage({super.key});

  @override
  State<PreAssessmentKitchenPage> createState() =>
      _PreAssessmentKitchenPageState();
}

class _PreAssessmentKitchenPageState extends State<PreAssessmentKitchenPage> {
  static const int _moduleNo = 4;
  static const String _assessmentType = 'pre';

  final PageController _pageCtrl = PageController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSummary = false;
  bool _showReview = false;
  bool _editingFromSummary = false;

  String? _moduleId;
  String? _assessmentId;
  String? _attemptId;
  String _assessmentTitle = 'Pre-Assessment';
  String _moduleDisplayTitle = '';
  String _instructions = '';

  int _currentIndex = 0;
  int _score = 0;

  List<_QuestionVm> _questions = [];
  List<String?> _selectedOptionIds = [];
  Set<int> _flaggedIndexes = {};

  SupabaseClient get _supabase => Supabase.instance.client;

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  String _txt(String en, String tl) => _isTl ? tl : en;

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
    super.dispose();
  }

  Future<void> _loadOrCreateAttempt({bool forceNewAttempt = false}) async {
    try {
      setState(() => _isLoading = true);

      final user = _user;

      final moduleRow = await _supabase
          .from('modules')
          .select('id, title, title_tl, subtitle, subtitle_tl')
          .eq('module_no', _moduleNo)
          .maybeSingle();

      if (moduleRow == null) {
        throw Exception('Module $_moduleNo not found in database.');
      }

      final moduleId = moduleRow['id'].toString();
      final moduleDisplayTitle = LocalizedDbText.pick(
        context,
        moduleRow,
        'title',
        'title_tl',
        fallback: _isTl
            ? 'Sunog sa Kusina: Ano Ito, Karaniwang Uri, at Ano ang Dapat Gawin'
            : 'Kitchen Fire: What It Is, Common Types, and What To Do',
      );

      final assessmentRow = await _supabase
          .from('assessments')
          .select('id, title, title_tl, instructions, instructions_tl')
          .eq('module_id', moduleId)
          .eq('type', _assessmentType)
          .maybeSingle();

      if (assessmentRow == null) {
        throw Exception(
          'Assessment for module $_moduleNo and type "$_assessmentType" was not found.',
        );
      }

      final assessmentId = assessmentRow['id'].toString();
      final assessmentTitle = LocalizedDbText.pick(
        context,
        assessmentRow,
        'title',
        'title_tl',
        fallback: _assessmentType == 'post' ? 'Post-Assessment' : 'Pre-Assessment',
      );

      final instructions = LocalizedDbText.pick(
        context,
        assessmentRow,
        'instructions',
        'instructions_tl',
      );

      final questionRows = await _supabase
          .from('assessment_questions')
          .select('id, question_no, prompt, prompt_tl, explanation, explanation_tl')
          .eq('assessment_id', assessmentId)
          .eq('is_active', true)
          .order('question_no');

      if (questionRows.isEmpty) {
        throw Exception('No active questions found for this assessment.');
      }

      final questionIds = questionRows.map((row) => row['id'].toString()).toList();

      final optionRows = await _supabase
          .from('assessment_options')
          .select(
            'id, question_id, option_key, option_text, option_text_tl, is_correct, display_order',
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
            key: (row['option_key'] ?? '').toString(),
            text: LocalizedDbText.pick(
              context,
              row,
              'option_text',
              'option_text_tl',
            ),
            isCorrect: (row['is_correct'] ?? false) as bool,
            displayOrder: displayOrder,
          ),
        );
      }

      for (final list in optionsByQuestion.values) {
        list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      }

      final baseQuestions = questionRows.map((row) {
        final questionId = row['id'].toString();
        return _QuestionVm(
          id: questionId,
          prompt: LocalizedDbText.pick(
            context,
            row,
            'prompt',
            'prompt_tl',
          ),
          explanation: LocalizedDbText.pick(
            context,
            row,
            'explanation',
            'explanation_tl',
          ),
          options: optionsByQuestion[questionId] ?? [],
        );
      }).toList();

      if (baseQuestions.any((q) => q.options.isEmpty)) {
        throw Exception(
          'One or more questions do not have options in assessment_options.',
        );
      }

      String attemptId;
      List<_QuestionVm> orderedQuestions;
      List<String?> selectedOptionIds;
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
              .select('question_id, selected_option_id, is_flagged, display_order')
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
            flaggedIndexes = {};
          } else {
            final existingQuestionIds =
                savedRows.map((row) => row['question_id'].toString()).toSet();

            final missingQuestions = baseQuestions
                .where((q) => !existingQuestionIds.contains(q.id))
                .toList();

            if (missingQuestions.isNotEmpty) {
              final startOrder = savedRows.length;

              await _supabase.from('assessment_attempt_answers').insert(
                    List.generate(
                      missingQuestions.length,
                      (index) => {
                        'attempt_id': attemptId,
                        'question_id': missingQuestions[index].id,
                        'display_order': startOrder + index,
                        'is_flagged': false,
                      },
                    ),
                  );
            }

            final refreshedSavedRows = await _supabase
                .from('assessment_attempt_answers')
                .select('question_id, selected_option_id, is_flagged, display_order')
                .eq('attempt_id', attemptId)
                .order('display_order');

            final questionMap = {for (final q in baseQuestions) q.id: q};

            orderedQuestions = [];
            selectedOptionIds = [];
            flaggedIndexes = {};

            for (int i = 0; i < refreshedSavedRows.length; i++) {
              final row = refreshedSavedRows[i];
              final questionId = row['question_id'].toString();
              final question = questionMap[questionId];
              if (question == null) continue;

              orderedQuestions.add(question);
              selectedOptionIds.add(
                row['selected_option_id']?.toString(),
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
          selectedOptionIds = List<String?>.filled(orderedQuestions.length, null);
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
        flaggedIndexes = {};
      }

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
        title: _txt('Failed to load pre-assessment', 'Hindi na-load ang paunang pagsusulit'),
        message: '$e',
        buttonText: _txt('OK', 'Sige'),
      );
    }
  }

  Future<_CreatedAttempt> _createNewAttempt({
    required String userId,
    required String assessmentId,
    required List<_QuestionVm> questions,
  }) async {
    final shuffled = List<_QuestionVm>.from(questions)..shuffle();

    final insertedAttempt = await _supabase
        .from('assessment_attempts')
        .insert({
          'user_id': userId,
          'assessment_id': assessmentId,
          'status': 'in_progress',
          'total_questions': shuffled.length,
          'correct_count': 0,
          'score': 0,
        })
        .select('id')
        .single();

    final attemptId = insertedAttempt['id'].toString();

    await _supabase.from('assessment_attempt_answers').insert(
          List.generate(
            shuffled.length,
            (index) => {
              'attempt_id': attemptId,
              'question_id': shuffled[index].id,
              'display_order': index,
              'is_flagged': false,
            },
          ),
        );

    return _CreatedAttempt(attemptId: attemptId, questions: shuffled);
  }

  Future<_CreatedAttempt> _createAnswerRowsForExistingAttempt({
    required String attemptId,
    required List<_QuestionVm> questions,
  }) async {
    final shuffled = List<_QuestionVm>.from(questions)..shuffle();

    await _supabase.from('assessment_attempt_answers').insert(
          List.generate(
            shuffled.length,
            (index) => {
              'attempt_id': attemptId,
              'question_id': shuffled[index].id,
              'display_order': index,
              'is_flagged': false,
            },
          ),
        );

    return _CreatedAttempt(attemptId: attemptId, questions: shuffled);
  }

  Future<void> _handleRefresh() async {
    if (_showReview) {
      final confirmed = await _showConfirmDialog(
        title: _txt('Start new attempt?', 'Magsimula ng bagong pagsubok?'),
        message: _txt(
          'You already finished this pre-assessment. Starting again will generate a new attempt.',
          'Natapos mo na ang paunang pagsusulit na ito. Ang pagsisimula muli ay lilikha ng bagong pagsubok.',
        ),
        confirmText: _txt('New Attempt', 'Bagong Pagsubok'),
        cancelText: _txt('Cancel', 'Kanselahin'),
      );

      if (confirmed == true) {
        await _loadOrCreateAttempt(forceNewAttempt: true);
      }
      return;
    }

    await _showInfoDialog(
      title: _txt('Current attempt preserved', 'Napanatili ang kasalukuyang pagsubok'),
      message: _txt(
        'This pre-assessment is still unfinished, so refresh will keep the same attempt and the same questions.',
        'Hindi pa tapos ang paunang pagsusulit na ito, kaya ang pag-refresh ay magpapanatili ng parehong pagsubok at mga tanong.',
      ),
      buttonText: _txt('OK', 'Sige'),
    );

    await _loadOrCreateAttempt(forceNewAttempt: false);
  }

  Future<void> _selectAnswer(int questionIndex, String optionId) async {
    setState(() {
      _selectedOptionIds[questionIndex] = optionId;
    });

    try {
      await _supabase
          .from('assessment_attempt_answers')
          .update({
            'selected_option_id': optionId,
            'is_correct': _isCorrectSelection(questionIndex, optionId),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('attempt_id', _attemptId!)
          .eq('question_id', _questions[questionIndex].id);
    } catch (e) {
      debugPrint('SELECT ANSWER UPDATE ERROR: $e');
    }
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
      await _supabase
          .from('assessment_attempt_answers')
          .update({
            'is_flagged': newFlagState,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('attempt_id', _attemptId!)
          .eq('question_id', _questions[questionIndex].id);
    } catch (e) {
      debugPrint('FLAG UPDATE ERROR: $e');
    }
  }

  bool _isCorrectSelection(int questionIndex, String optionId) {
    return _questions[questionIndex].options.any(
      (opt) => opt.id == optionId && opt.isCorrect,
    );
  }

  _OptionVm? _selectedOptionFor(int questionIndex) {
    final selectedId = _selectedOptionIds[questionIndex];
    if (selectedId == null) return null;

    for (final option in _questions[questionIndex].options) {
      if (option.id == selectedId) return option;
    }
    return null;
  }

  _OptionVm _correctOptionFor(int questionIndex) {
    return _questions[questionIndex].options.firstWhere(
      (opt) => opt.isCorrect,
      orElse: () => _questions[questionIndex].options.first,
    );
  }

  String _reviewExplanationFor(int questionIndex) {
    final question = _questions[questionIndex];
    final correct = _correctOptionFor(questionIndex);

    if (question.explanation.trim().isNotEmpty) {
      return question.explanation.trim();
    }

    return _txt(
      'The correct answer is "${correct.text}" based on the lesson content for this module.',
      'Ang tamang sagot ay "${correct.text}" batay sa aralin ng modyul na ito.',
    );
  }

  int get _answeredCount => _selectedOptionIds.where((value) => value != null).length;

  int get _unansweredCount => _selectedOptionIds.where((value) => value == null).length;

  bool get _hasUnansweredQuestions => _unansweredCount > 0;

  List<int> get _unansweredIndexes {
    final result = <int>[];
    for (int i = 0; i < _selectedOptionIds.length; i++) {
      if (_selectedOptionIds[i] == null) {
        result.add(i);
      }
    }
    return result;
  }

  String _optionLetter(_QuestionVm question, _OptionVm option) {
    final index = question.options.indexWhere((opt) => opt.id == option.id);
    if (index >= 0) return String.fromCharCode(65 + index);
    if (option.key.trim().isNotEmpty) return option.key.trim().toUpperCase();
    return 'A';
  }

  String _optionDisplay(_QuestionVm question, _OptionVm option) {
    return '${_optionLetter(question, option)}. ${option.text}';
  }

  String _reviewAnswerText(int questionIndex) {
    final question = _questions[questionIndex];
    final selected = _selectedOptionFor(questionIndex);
    final correct = _correctOptionFor(questionIndex);

    if (selected == null) {
      return _txt(
        'No answer selected. Correct answer: ${_optionDisplay(question, correct)}',
        'Walang napiling sagot. Tamang sagot: ${_optionDisplay(question, correct)}',
      );
    }

    if (selected.id == correct.id) {
      return _optionDisplay(question, selected);
    }

    return _txt(
      '${_optionDisplay(question, selected)}. Correct answer: ${_optionDisplay(question, correct)}',
      '${_optionDisplay(question, selected)}. Tamang sagot: ${_optionDisplay(question, correct)}',
    );
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

  void _showIncompleteSnackBar() {
    final missing = _unansweredIndexes
        .map((i) => _isTl ? 'Tanong ${i + 1}' : 'Q${i + 1}')
        .toList();
    final preview = missing.take(8).join(', ');
    final suffix = missing.length > 8 ? '...' : '';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB45309),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.info_outline_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _txt(
                    'Please answer all questions before submitting. Missing: $preview$suffix',
                    'Sagutin muna ang lahat ng tanong bago ipasa. Kulang: $preview$suffix',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _submitAssessment() async {
    if (_hasUnansweredQuestions) {
      _showIncompleteSnackBar();
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: _txt('Submit Pre-Assessment', 'Ipasa ang Paunang Pagsusulit'),
      message: _txt(
        'Answered: $_answeredCount / ${_questions.length}\n\nAfter submission, you will be redirected to the completion page.',
        'Nasagutan: $_answeredCount / ${_questions.length}\n\nPagkatapos ipasa, mapupunta ka sa completion page.',
      ),
      confirmText: _txt('Submit', 'Ipasa'),
      cancelText: _txt('Review Again', 'Suriin Muli'),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      int correctCount = 0;

      for (int i = 0; i < _questions.length; i++) {
        final selectedId = _selectedOptionIds[i];
        final isCorrect = selectedId == null
            ? false
            : _isCorrectSelection(i, selectedId);

        if (isCorrect) correctCount++;

        await _supabase
            .from('assessment_attempt_answers')
            .update({
              'selected_option_id': selectedId,
              'is_flagged': _flaggedIndexes.contains(i),
              'display_order': i,
              'is_correct': isCorrect,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('attempt_id', _attemptId!)
            .eq('question_id', _questions[i].id);
      }

      final scorePercent = _questions.isEmpty
          ? 0
          : (correctCount / _questions.length) * 100;
      final submittedAt = DateTime.now().toUtc().toIso8601String();

      await _supabase
          .from('assessment_attempts')
          .update({
            'submitted_at': submittedAt,
            'status': 'submitted',
            'correct_count': correctCount,
            'score': scorePercent,
          })
          .eq('id', _attemptId!);

      if (_moduleId != null) {
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
            'pre_test_completed_at': submittedAt,
          });
        } else {
          await _supabase
              .from('module_progress')
              .update({'pre_test_completed_at': submittedAt})
              .eq('id', progressRow['id']);
        }
      }

      if (!mounted) return;

      _score = correctCount;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PreAssessmentCompletionPage2(
            score: correctCount,
            totalQuestions: _questions.length,
            assessmentTitle: _assessmentTitle,
          ),
        ),
      );
    } catch (e) {
      debugPrint('SUBMIT ASSESSMENT ERROR: $e');

      if (!mounted) return;

      await _showInfoDialog(
        title: _txt('Submission failed', 'Nabigo ang pagsusumite'),
        message: '$e',
        buttonText: _txt('OK', 'Sige'),
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
              backgroundColor: kKitchenAmber,
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
              backgroundColor: kKitchenAmber,
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
                    const SizedBox(height: 8),
                    _HintCard(
                      icon: Icons.info_outline_rounded,
                      text: _txt(
                        'Use the summary to jump back to any question before submitting.',
                        'Gamitin ang buod para bumalik sa anumang tanong bago ipasa.',
                      ),
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

                return _SummaryCard(
                  questionNumber: index + 1,
                  question: question.prompt,
                  selectedAnswer: selected == null
                      ? (_isTl ? 'Walang napiling sagot' : 'No answer selected')
                      : _optionDisplay(question, selected),
                  answered: selected != null,
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
          _ReviewTopCard(score: _score, total: _questions.length),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final question = _questions[index];
                final selected = _selectedOptionFor(index);
                final correct = _correctOptionFor(index);
                final isCorrect = selected != null && selected.id == correct.id;

                return _ReviewCard(
                  questionNumber: index + 1,
                  question: question.prompt,
                  userAnswer: _reviewAnswerText(index),
                  correctAnswer: _optionDisplay(question, correct),
                  isCorrect: isCorrect,
                  explanation: isCorrect ? null : _reviewExplanationFor(index),
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
                  side: const BorderSide(color: kKitchenAmber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _isTl ? 'Bumalik' : 'Back',
                  style: const TextStyle(
                    color: kKitchenAmber,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kKitchenAmberDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed:
                    _isSubmitting ? null : () => _loadOrCreateAttempt(forceNewAttempt: true),
                child: Text(
                  _isTl ? 'Bagong Pagsubok' : 'New Attempt',
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

    if (_showSummary) {
      final locked = _hasUnansweredQuestions;

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kKitchenAmber),
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
                child: Text(
                  _isTl ? 'Bumalik sa Tanong' : 'Back to Questions',
                  style: const TextStyle(
                    color: kKitchenAmber,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: locked ? Colors.grey.shade400 : kKitchenAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submitAssessment,
                child: Text(
                  _isSubmitting
                      ? (_isTl ? 'Ipinapasa...' : 'Submitting...')
                      : locked
                          ? (_isTl ? 'Kumpletuhin Lahat' : 'Complete All')
                          : (_isTl ? 'Ipasa' : 'Submit'),
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
        ? (_isTl ? 'Suriin ang Buod' : 'Review Summary')
        : (isLast
            ? (_isTl ? 'Suriin ang Buod' : 'Review Summary')
            : (_isTl ? 'Susunod' : 'Next'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kKitchenAmber),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _goBack,
              child: Text(
                _editingFromSummary
                    ? (_isTl ? 'Bumalik sa Buod' : 'Back to Summary')
                    : (_currentIndex == 0
                        ? (_isTl ? 'Lumabas' : 'Exit')
                        : (_isTl ? 'Bumalik' : 'Back')),
                style: const TextStyle(
                  color: kKitchenAmber,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kKitchenAmber,
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
        ? (_isTl
            ? 'Sunog sa Kusina: Ano Ito, Karaniwang Uri, at Ano ang Dapat Gawin'
            : 'Kitchen Fire: What It Is, Common Types, and What To Do')
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
                          padding: const EdgeInsets.symmetric(horizontal: 25),
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
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _txt('PRE – ASSESSMENT', 'PAUNANG – PAGSUSULIT'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [kKitchenAmber, kKitchenAmberDark],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_fire_department_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            LocalizedDbText.moduleLabel(context, _moduleNo),
                                            style: const TextStyle(
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
                                        headerTitle,
                                        softWrap: true,
                                        maxLines: 3,
                                        overflow: TextOverflow.visible,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_instructions.trim().isNotEmpty && !_showReview) ...[
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

  const _CreatedAttempt({required this.attemptId, required this.questions});
}

class _QuestionVm {
  final String id;
  final String prompt;
  final String explanation;
  final List<_OptionVm> options;

  const _QuestionVm({
    required this.id,
    required this.prompt,
    required this.explanation,
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
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_outline_rounded,
            label: isTl ? 'Nasagutan' : 'Answered',
            value: '$answered / $total',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.outlined_flag_rounded,
            label: isTl ? 'Minarkahan' : 'Flagged',
            value: '$flagged',
            color: kKitchenAmberDark,
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
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
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
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kKitchenAmber, kKitchenAmberDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTl
                      ? 'TANONG $questionNumber / $totalQuestions'
                      : 'QUESTION $questionNumber / $totalQuestions',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isFlagged
                        ? kKitchenAmber.withOpacity(0.12)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isFlagged ? kKitchenAmber : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFlagged
                            ? Icons.flag_rounded
                            : Icons.outlined_flag_rounded,
                        size: 16,
                        color: isFlagged ? kKitchenAmberDark : kDarkText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFlagged
                            ? (isTl ? 'Minarkahan' : 'Flagged')
                            : (isTl ? 'Markahan' : 'Flag'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isFlagged ? kKitchenAmberDark : kDarkText,
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
        selected ? kKitchenAmberDark : Colors.black.withOpacity(0.08);
    final bgColor = selected ? kKitchenAmber.withOpacity(0.10) : Colors.white;

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
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
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
                  color: selected ? kKitchenAmberDark : Colors.grey.shade100,
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

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kKitchenAmberSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kKitchenAmber.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kKitchenAmberDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.35, fontWeight: FontWeight.w600),
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
          Text(
            LocalizedDbText.isTagalog(context)
                ? 'Suriin muna ang lahat ng tanong bago ipasa'
                : 'Review all questions before you submit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: kDarkText,
            ),
          ),
          if (hasUnanswered) ...[
            const SizedBox(height: 8),
            Text(
              LocalizedDbText.isTagalog(context)
                  ? '$unansweredCount tanong ang kailangan pang sagutan.'
                  : '$unansweredCount question(s) still need an answer.',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _StatsRow(answered: answered, total: total, flagged: flagged),
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
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: kKitchenAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kKitchenAmberDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  answered
                      ? (isTl ? 'Nasagutan' : 'Answered')
                      : (isTl ? 'Hindi pa nasasagutan' : 'Unanswered'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: kKitchenAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isTl ? 'Minarkahan' : 'Flagged',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kKitchenAmberDark,
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
                  color: flagged ? kKitchenAmberDark : Colors.grey.shade600,
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
                backgroundColor: kKitchenAmber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: Text(
                isTl ? 'Baguhin' : 'Edit',
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

class _ReviewTopCard extends StatelessWidget {
  const _ReviewTopCard({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
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
          Text(
            isTl ? 'Resulta ng Paunang Pagsusulit' : 'Pre-Assessment Result',
            style: const TextStyle(
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
              color: kKitchenAmberDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kKitchenAmber,
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
  });

  final int questionNumber;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    final statusColor = isCorrect ? const Color(0xFF16A34A) : kKitchenAmberDark;

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCorrect
                      ? (isTl ? 'Tama' : 'Correct')
                      : (isTl ? 'Mali' : 'Incorrect'),
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
            isTl ? 'Pagsusuri ng Sagot' : 'Answer Review',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userAnswer,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            Text(
              isTl ? 'Tamang Sagot' : 'Correct Answer',
              style: const TextStyle(
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
          if (!isCorrect && explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTl ? 'Bakit Mali Ito' : 'Why this is wrong',
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
