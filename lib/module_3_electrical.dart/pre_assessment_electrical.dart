import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/app_text.dart';
import '../localization/localized_db_text.dart';
import '../localization/language_controller.dart';
import 'pre_assess_completion_page.dart';
import 'pre_assess_instruction.dart';
import 'module_progression_service.dart';
import '../module_progress_refresh_notifier.dart';
import '../widgets/assessment_nav_buttons.dart';

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

class PreAssessmentElectricalPage extends StatefulWidget {
  const PreAssessmentElectricalPage({super.key});

  @override
  State<PreAssessmentElectricalPage> createState() =>
      _PreAssessmentElectricalPageState();
}

class _PreAssessmentElectricalPageState
    extends State<PreAssessmentElectricalPage> {
  static const int _moduleNo = 3;
  static const String _assessmentType = 'pre';
  static const int _quizDurationSeconds = 300;

  final PageController _pageCtrl = PageController();

  Timer? _quizTimer;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSummary = false;
  bool _showReview = false;
  bool _editingFromSummary = false;
  bool _timeExpired = false;
  bool _oneMinuteWarningShown = false;

  String? _moduleId;
  String? _assessmentId;
  String? _attemptId;
  String _assessmentTitle = 'Pre-Assessment';
  String _instructions = '';

  int _currentIndex = 0;
  int _score = 0;
  int _remainingSeconds = _quizDurationSeconds;

  List<_QuestionVm> _questions = [];
  List<String?> _selectedOptionIds = [];
  Set<int> _flaggedIndexes = {};

  bool get _isTl => Localizations.localeOf(context).languageCode == 'tl';

  String _txt(String en, String tl) {
    return _isTl ? tl : en;
  }


  String get _timeLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadOrCreateAttempt();
  }

  @override
  void dispose() {
    _stopQuizTimer();
    _pageCtrl.dispose();
    super.dispose();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  User get _user {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No active user session.');
    }
    return user;
  }

  void _stopQuizTimer() {
    _quizTimer?.cancel();
    _quizTimer = null;
  }

  void _startQuizTimer() {
    _stopQuizTimer();

    if (!mounted || _isLoading || _showReview || _questions.isEmpty) return;

    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isSubmitting || _showReview) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _handleTimeExpired();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 60 && !_oneMinuteWarningShown) {
        _oneMinuteWarningShown = true;
        _showOneMinuteWarning();
      }
    });
  }

  Future<void> _handleTimeExpired() async {
    if (!mounted || _timeExpired || _isSubmitting || _showReview) return;

    setState(() {
      _remainingSeconds = 0;
      _timeExpired = true;
      _showSummary = false;
      _editingFromSummary = false;
    });

    await _showAutoCloseInfoDialog(
      title: _txt('Time is up', 'Tapos na ang oras'),
      message: _txt(
        'Your quiz will be submitted automatically. Unanswered questions will be marked incorrect.',
        'Awtomatikong ipapasa ang pagsusulit. Ang hindi nasagutang tanong ay mamarkahang mali.',
      ),
    );

    await _submitAssessment(forceSubmit: true, dueToTimeUp: true);
  }

  void _showOneMinuteWarning() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isTl = Localizations.localeOf(dialogContext).languageCode == 'tl';
        final title = isTl ? 'Babala sa Oras' : 'Time Warning';
        final message = isTl
            ? 'Mayroon ka na lamang 1 minuto. Sagutan na ang mga natitirang tanong.'
            : 'You only have 1 minute left. Please answer the remaining questions.';
        final badgeText = isTl ? 'ORAS NG PAGSUSULIT' : 'QUIZ TIME ALERT';
        final buttonText = isTl ? 'Naiintindihan ko' : 'I understand';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.85),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brandRed, AppColors.brandRedLight],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          color: AppColors.brandRedSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandRed.withOpacity(0.22),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: AppColors.brandRed,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandRedSoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandRed,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            elevation: 4,
                            shadowColor: AppColors.primaryButton.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                buttonText,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textOnRed,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.textOnRed,
                                size: 20,
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
          ),
        );
      },
    );
  }

  int _intFrom(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  List<_QuestionVm> _orderedQuestions(List<_QuestionVm> questions) {
    final ordered = List<_QuestionVm>.from(questions)
      ..sort((a, b) {
        final byNumber = a.questionNo.compareTo(b.questionNo);
        if (byNumber != 0) return byNumber;
        return a.id.compareTo(b.id);
      });
    return ordered;
  }

  Future<void> _loadOrCreateAttempt({bool forceNewAttempt = false}) async {
    _stopQuizTimer();

    try {
      setState(() {
        _isLoading = true;
        _timeExpired = false;
        _remainingSeconds = _quizDurationSeconds;
        _oneMinuteWarningShown = false;
      });

      await ModuleProgressionService(client: _supabase)
          .ensureCanStartPreTest(moduleNo: _moduleNo);

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

      final assessmentRow = await _supabase
          .from('assessments')
          .select('id, title, title_tl, instructions, instructions_tl')
          .eq('module_id', moduleId)
          .eq('type', _assessmentType)
          .order('created_at', ascending: false)
          .limit(1)
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

      final questionIds =
          questionRows.map((row) => row['id'].toString()).toList();

      final optionRows = await _supabase
          .from('assessment_options')
          .select(
            'id, question_id, option_key, option_text, option_text_tl, is_correct, display_order, is_active',
          )
          .inFilter('question_id', questionIds)
          .eq('is_active', true)
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
          questionNo: _intFrom(row['question_no'], 999),
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

      final created = await _createNewAttempt(
        userId: user.id,
        assessmentId: assessmentId,
        moduleId: moduleId,
        questions: baseQuestions,
      );
      final attemptId = created.attemptId;
      final orderedQuestions = created.questions;
      final selectedOptionIds =
          List<String?>.filled(orderedQuestions.length, null);
      final flaggedIndexes = <int>{};

      if (!mounted) return;

      setState(() {
        _moduleId = moduleId;
        _assessmentId = assessmentId;
        _attemptId = attemptId;
        _assessmentTitle = assessmentTitle;
        _instructions = instructions;
        _questions = orderedQuestions;
        _selectedOptionIds = selectedOptionIds;
        _flaggedIndexes = flaggedIndexes;
        _currentIndex = 0;
        _score = 0;
        _showSummary = false;
        _showReview = false;
        _editingFromSummary = false;
        _timeExpired = false;
        _remainingSeconds = _quizDurationSeconds;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(0);
        }
        _startQuizTimer();
      });
    } on ProgressionAccessDenied catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await _showInfoDialog(
        title: _txt('Pre-Assessment Locked', 'Naka-lock ang Paunang Pagsusulit'),
        message: e.message,
        buttonText: _txt('OK', 'Sige'),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

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
    required String moduleId,
    required List<_QuestionVm> questions,
  }) async {
    final ordered = _orderedQuestions(questions);
    final now = DateTime.now().toUtc().toIso8601String();

    final existingAttempts = await _supabase
        .from('assessment_attempts')
        .select('id')
        .eq('user_id', userId)
        .eq('assessment_id', assessmentId)
        .eq('status', 'in_progress')
        .order('started_at', ascending: false)
        .limit(1);

    final String attemptId;

    if (existingAttempts.isNotEmpty) {
      attemptId = existingAttempts.first['id'].toString();

      await _supabase.from('assessment_attempts').update({
        'started_at': now,
        'module_id': moduleId,
        'submitted_at': null,
        'status': 'in_progress',
        'total_questions': ordered.length,
        'correct_count': 0,
        'score': 0,
      }).eq('id', attemptId);
    } else {
      final insertedAttempt = await _supabase
          .from('assessment_attempts')
          .insert({
            'user_id': userId,
            'assessment_id': assessmentId,
            'module_id': moduleId,
            'status': 'in_progress',
            'total_questions': ordered.length,
            'correct_count': 0,
            'score': 0,
          })
          .select('id')
          .single();

      attemptId = insertedAttempt['id'].toString();
    }

    try {
      await _supabase
          .from('assessment_attempt_answers')
          .delete()
          .eq('attempt_id', attemptId);
    } catch (e) {
      debugPrint('CLEAR PRE-ASSESSMENT ANSWERS WARNING: $e');
    }

    if (ordered.isNotEmpty) {
      await _supabase.from('assessment_attempt_answers').upsert(
        List.generate(
          ordered.length,
          (index) => {
            'attempt_id': attemptId,
            'question_id': ordered[index].id,
            'selected_option_id': null,
            'is_flagged': false,
            'display_order': index,
            'is_correct': null,
            'updated_at': now,
          },
        ),
        onConflict: 'attempt_id,question_id',
      );
    }

    return _CreatedAttempt(
      attemptId: attemptId,
      questions: ordered,
    );
  }

  Future<_CreatedAttempt> _createAnswerRowsForExistingAttempt({
    required String attemptId,
    required List<_QuestionVm> questions,
  }) async {
    final ordered = _orderedQuestions(questions);

    if (ordered.isNotEmpty) {
      final now = DateTime.now().toUtc().toIso8601String();

      await _supabase.from('assessment_attempt_answers').upsert(
        List.generate(
          ordered.length,
          (index) => {
            'attempt_id': attemptId,
            'question_id': ordered[index].id,
            'selected_option_id': null,
            'is_flagged': false,
            'display_order': index,
            'is_correct': null,
            'updated_at': now,
          },
        ),
        onConflict: 'attempt_id,question_id',
      );
    }

    return _CreatedAttempt(
      attemptId: attemptId,
      questions: ordered,
    );
  }

  Future<void> _handleRefresh() async {
    if (_timeExpired || _isSubmitting) return;

    if (_showReview) {
      await _showInfoDialog(
        title: _txt('Pre-Assessment Locked', 'Naka-lock ang Paunang Pagsusulit'),
        message: _txt(
          ModuleProgressionService.preTestAlreadyTakenMessage,
          'Isang beses lang pwedeng sagutan ang Paunang Pagsusulit. Subukan ang susunod na modyul.',
        ),
        buttonText: _txt('OK', 'Sige'),
      );
      return;
    }

    await _showInfoDialog(
      title: _txt('Current attempt preserved', 'Napanatili ang kasalukuyang subok'),
      message: _txt(
        'This pre-assessment is already in progress. The loaded questions will stay fixed until you submit or leave and start again.',
        'Kasalukuyang sinasagutan ang paunang pagsusulit. Mananatili muna ang naka-load na mga tanong hanggang maipasa mo ito o lumabas at magsimula ulit.',
      ),
      buttonText: _txt('OK', 'Sige'),
    );
  }

  Future<void> _selectAnswer(int questionIndex, String optionId) async {
    if (_timeExpired || _isSubmitting || _showReview) return;

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
    if (_timeExpired || _isSubmitting || _showReview) return;

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

    return 'The correct answer is "${correct.text}" based on the lesson content for this module.';
  }

  int get _answeredCount =>
      _selectedOptionIds.where((value) => value != null).length;

  int get _unansweredCount =>
      _selectedOptionIds.where((value) => value == null).length;

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
    if (index >= 0) {
      return String.fromCharCode(65 + index);
    }
    if (option.key.trim().isNotEmpty) {
      return option.key.trim().toUpperCase();
    }
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
      'Your answer: ${_optionDisplay(question, selected)}\nCorrect answer: ${_optionDisplay(question, correct)}',
      'Sagot mo: ${_optionDisplay(question, selected)}\nTamang sagot: ${_optionDisplay(question, correct)}',
    );
  }

  void _goNext() {
    if (_timeExpired || _isSubmitting) return;

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
      setState(() {
        _showSummary = true;
      });
    }
  }

  void _goBack() {
    if (_isSubmitting) return;

    if (_showReview) {
      Navigator.pop(context);
      return;
    }

    if (_timeExpired) return;

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
    if (_timeExpired || _isSubmitting) return;

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

  Future<void> _showIncompletePopup() async {
    final missing = _unansweredIndexes.map((i) => 'Q${i + 1}').toList();
    final preview = missing.take(8).join(', ');
    final suffix = missing.length > 8 ? '...' : '';

    await _showInfoDialog(
      title: _txt('Incomplete answers', 'May hindi pa nasasagutan'),
      message: _txt(
        'Please answer all questions before submitting.\n\nMissing: $preview$suffix',
        'Sagutan muna ang lahat ng tanong bago ipasa.\n\nKulang: $preview$suffix',
      ),
      buttonText: _txt('OK', 'Sige'),
    );
  }

  /// Persists a finished Pre-Assessment and proves it landed, before the
  /// Score Result screen is shown.
  ///
  /// Both writes read their row back: a PostgREST write that matches no row
  /// still succeeds, so without the read-back a rejected write would look
  /// exactly like a saved completion. The module progress write is a single
  /// upsert on the (user_id, module_id) unique key, so repeated submits can
  /// never leave a duplicate progress record behind.
  Future<void> _saveSubmittedPreTest({
    required String submittedAt,
    required num scorePercent,
    required int correctCount,
  }) async {
    final submittedAttempt = await _supabase
        .from('assessment_attempts')
        .update({
          'submitted_at': submittedAt,
          'status': 'submitted',
          'correct_count': correctCount,
          'total_questions': _questions.length,
          'score': scorePercent,
        })
        .eq('id', _attemptId!)
        .select('id')
        .maybeSingle();

    if (submittedAttempt == null) {
      throw Exception(
        'Your attempt could not be marked as submitted, so nothing was saved. '
        'Please check your connection and try again.',
      );
    }

    final savedProgress = await _supabase
        .from('module_progress')
        .upsert({
          'user_id': _user.id,
          'module_id': _moduleId,
          'pre_test_completed_at': submittedAt,
          'pre_test_attempt_id': _attemptId,
          'pre_test_score': scorePercent,
          'pre_test_correct_count': correctCount,
          'pre_test_total_questions': _questions.length,
          'updated_at': submittedAt,
        }, onConflict: 'user_id,module_id')
        .select(
          'id, pre_test_completed_at, pre_test_attempt_id, pre_test_score',
        )
        .maybeSingle();

    if (savedProgress == null ||
        savedProgress['pre_test_completed_at'] == null ||
        savedProgress['pre_test_score'] == null ||
        savedProgress['pre_test_attempt_id']?.toString() != _attemptId) {
      throw Exception(
        'Your Pre-Assessment result was not saved to your module progress. '
        'Please check your connection and try again.',
      );
    }

    // The completion is stored and verified before the Score Result screen is
    // shown, so leaving that screen by X, Continue, Answer Feedback or back
    // can no longer lose it.
    notifyModuleProgressChanged();
  }

  Future<void> _submitAssessment({
    bool forceSubmit = false,
    bool dueToTimeUp = false,
  }) async {
    if (_isSubmitting) return;

    if (!forceSubmit && _hasUnansweredQuestions) {
      await _showIncompletePopup();
      return;
    }

    if (!forceSubmit) {
      final confirmed = await _showConfirmDialog(
        title: _txt('Submit Pre-Assessment?', 'Ipasa ang Paunang Pagsusulit?'),
        answeredSummary: _txt(
          'All ${_questions.length} questions answered',
          'Nasagutan ang lahat ng ${_questions.length} tanong',
        ),
        message: _txt(
          'Once submitted, your answers cannot be changed and this '
          'Pre-Assessment cannot be retaken.',
          'Kapag naipasa na, hindi na maaaring baguhin ang iyong mga sagot '
          'at hindi na muling makukuha ang Paunang Pagsusulit na ito.',
        ),
        confirmText: _txt('Submit Pre-Assessment →', 'Ipasa ang Pre-Assessment →'),
        cancelText: _txt('Review Answers', 'Suriin ang mga Sagot'),
      );

      if (confirmed != true) return;
    }

    _stopQuizTimer();

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      if (dueToTimeUp) {
        _timeExpired = true;
        _remainingSeconds = 0;
      }
    });

    try {
      await ModuleProgressionService(client: _supabase).ensureCanStartPreTest(
        moduleNo: _moduleNo,
      );

      int correctCount = 0;

      for (int i = 0; i < _questions.length; i++) {
        final selectedId = _selectedOptionIds[i];
        final isCorrect =
            selectedId == null ? false : _isCorrectSelection(i, selectedId);

        if (isCorrect) {
          correctCount++;
        }

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

      final scorePercent =
          _questions.isEmpty ? 0 : (correctCount / _questions.length) * 100;

      final submittedAt = DateTime.now().toUtc().toIso8601String();

      await _saveSubmittedPreTest(
        submittedAt: submittedAt,
        scorePercent: scorePercent,
        correctCount: correctCount,
      );

      if (!mounted) return;

      _score = correctCount;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PreAssessmentCompletionPage1(
            score: correctCount,
            totalQuestions: _questions.length,
            assessmentTitle: _assessmentTitle,
            attemptId: _attemptId!,
          ),
        ),
      );
    } on ProgressionAccessDenied catch (e) {
      debugPrint('PRE-ASSESSMENT ACCESS DENIED DURING SUBMIT: ${e.message}');

      if (!mounted) return;

      await _showInfoDialog(
        title: _txt('Pre-Test Locked', 'Naka-lock ang Paunang Pagsusulit'),
        message: _txt(
          e.message,
          e.message == ModuleProgressionService.preTestAlreadyTakenMessage
              ? 'Isang beses lang pwedeng sagutan ang Paunang Pagsusulit. Magpatuloy sa susunod na modyul.'
              : e.message,
        ),
        buttonText: _txt('OK', 'Sige'),
      );

      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('SUBMIT ASSESSMENT ERROR: $e');

      if (!mounted) return;

      await _showInfoDialog(
        title: _txt('Submission failed', 'Nabigo ang pagpapasa'),
        message: '$e',
        buttonText: _txt('OK', 'Sige'),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String answeredSummary,
    required String message,
    required String confirmText,
    required String cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.80),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 68,
                  width: 68,
                  decoration: const BoxDecoration(
                    color: AppColors.brandRedSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.brandRed,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        answeredSummary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryButton,
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryButton,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 4,
                      shadowColor: AppColors.primaryButton.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
    required String buttonText,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.80),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 68,
                  width: 68,
                  decoration: const BoxDecoration(
                    color: AppColors.brandRedSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.brandRed,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.brandRed,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 4,
                      shadowColor: AppColors.primaryButton.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAutoCloseInfoDialog({
    required String title,
    required String message,
    Duration duration = const Duration(milliseconds: 1400),
  }) async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.80),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_off_rounded,
                    color: AppColors.error,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryButton,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(duration);

    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildQuizView() {
    return PageView.builder(
      controller: _pageCtrl,
      physics: _timeExpired || _isSubmitting
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemCount: _questions.length,
      onPageChanged: (index) {
        if (_timeExpired || _isSubmitting) return;
        setState(() {
          _currentIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final question = _questions[index];
        final selectedId = _selectedOptionIds[index];
        final isFlagged = _flaggedIndexes.contains(index);
        final locked = _timeExpired || _isSubmitting;

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 610;
            final sidePadding = compact ? 18.0 : 20.0;
            final verticalGap = compact ? 8.0 : 12.0;
            final optionGap = compact ? 7.0 : 9.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuizProgressHeader(
                    questionNumber: index + 1,
                    totalQuestions: _questions.length,
                    answered: _answeredCount,
                    flagged: _flaggedIndexes.length,
                    timeLabel: _timeLabel,
                    timeWarning: _remainingSeconds <= 30,
                    compact: compact,
                  ),
                  SizedBox(height: verticalGap),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuestionHeaderCard(
                            questionNumber: index + 1,
                            totalQuestions: _questions.length,
                            question: question.prompt,
                            isFlagged: isFlagged,
                            onFlagTap: locked ? null : () => _toggleFlag(index),
                            compact: compact,
                          ),
                          SizedBox(height: verticalGap),
                          Text(
                            _txt('Choose one answer', 'Pumili ng isang sagot'),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: compact ? 12.5 : 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          Column(
                            children: question.options.asMap().entries.map((entry) {
                              final option = entry.value;
                              final selected = selectedId == option.id;
                              final label = String.fromCharCode(65 + entry.key);
                              final isLastOption = entry.key == question.options.length - 1;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLastOption ? 0 : optionGap,
                                ),
                                child: _OptionCard(
                                  label: label,
                                  text: option.text,
                                  selected: selected,
                                  enabled: !locked,
                                  onTap: locked
                                      ? null
                                      : () => _selectAnswer(index, option.id),
                                  compact: compact,
                                  maxTextLines: compact ? 2 : 3,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                      ? _txt('No answer selected', 'Walang napiling sagot')
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
          _ReviewTopCard(
            score: _score,
            total: _questions.length,
          ),
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
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: AssessmentSecondaryButton(
                label: _txt('Back', 'Bumalik'),
                icon: Icons.arrow_back_rounded,
                backgroundColor: AppColors.secondaryButton,
                accentColor: AppColors.primaryButton,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AssessmentPrimaryButton(
                label: _txt('Close', 'Isara'),
                icon: Icons.lock_rounded,
                backgroundColor: AppColors.primaryButton,
                disabledBackgroundColor: AppColors.textMuted,
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_showSummary) {
      final locked = _hasUnansweredQuestions;

      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: AssessmentSecondaryButton(
                label: _txt('Questions', 'Mga Tanong'),
                icon: Icons.arrow_back_rounded,
                backgroundColor: AppColors.secondaryButton,
                accentColor: AppColors.primaryButton,
                onPressed: _timeExpired || _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _showSummary = false;
                          _editingFromSummary = false;
                        });
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AssessmentPrimaryButton(
                label: _isSubmitting
                    ? _txt('Submitting...', 'Ipinapasa...')
                    : locked
                        ? _txt('Complete All', 'Kumpletuhin')
                        : _txt('Submit', 'Ipasa'),
                icon: locked ? Icons.lock_outline_rounded : Icons.check_rounded,
                onPressed: _isSubmitting || _timeExpired ? null : () => _submitAssessment(),
                backgroundColor: locked ? AppColors.textMuted : AppColors.primaryButton,
                disabledBackgroundColor: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final isLast = _currentIndex == _questions.length - 1;
    final nextLabel = _editingFromSummary
        ? _txt('Review Summary', 'Suriin')
        : (isLast
            ? _txt('Review Summary', 'Suriin')
            : _txt('Next Question', 'Susunod'));

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: AssessmentSecondaryButton(
              label: _editingFromSummary
                  ? _txt('Summary', 'Buod')
                  : (_currentIndex == 0
                      ? _txt('Exit', 'Lumabas')
                      : _txt('Back', 'Bumalik')),
              icon: _currentIndex == 0 && !_editingFromSummary
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              backgroundColor: AppColors.secondaryButton,
              accentColor: AppColors.primaryButton,
              onPressed: _isSubmitting ? null : _goBack,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AssessmentPrimaryButton(
              label: _isSubmitting
                  ? _txt('Submitting...', 'Ipinapasa...')
                  : nextLabel,
              icon: Icons.arrow_forward_rounded,
              backgroundColor: AppColors.primaryButton,
              disabledBackgroundColor: AppColors.textMuted,
              onPressed: _timeExpired || _isSubmitting ? null : _goNext,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _AssessmentGradientBackdrop(),
          SafeArea(
            child: _isLoading
                ? const Center(child: _LoadingCard())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                        child: _TopAssessmentBar(
                          title: getAssessmentDisplayTitle(context),
                          moduleLabel: context.tr('module_3'),
                          moduleTitle: context.tr('module_3_full_header'),
                          onClose: () => Navigator.pop(context),
                          onRefresh: _handleRefresh,
                        ),
                      ),
                      const SizedBox(height: 14),
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
        ],
      ),
    );
  }
}

class _AssessmentGradientBackdrop extends StatelessWidget {
  const _AssessmentGradientBackdrop();

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
          child: _DecorCircle(size: 138, opacity: 0.17),
        ),
        const Positioned(
          top: 178,
          left: -42,
          child: _DecorCircle(size: 124, opacity: 0.13),
        ),
      ],
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.opacity});

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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryButton),
          const SizedBox(height: 14),
          Text(
            t(context, 'Loading assessment...', 'Nilo-load ang pagsusulit...'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAssessmentBar extends StatelessWidget {
  const _TopAssessmentBar({
    required this.title,
    required this.moduleLabel,
    required this.moduleTitle,
    required this.onClose,
    required this.onRefresh,
  });

  final String title;
  final String moduleLabel;
  final String moduleTitle;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            _TopIconButton(
              icon: Icons.close_rounded,
              onTap: onClose,
            ),
            const Spacer(),
            _TopIconButton(
              icon: Icons.refresh_rounded,
              onTap: () {
                onRefresh();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
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
                    Icons.electrical_services_rounded,
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
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.textOnRed.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textOnRed.withOpacity(0.24)),
        ),
        child: Icon(icon, color: AppColors.textOnRed, size: 21),
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.instructions});

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandRedSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.brandRed,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: instructions.map((instruction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.brandRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instruction,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            height: 1.34,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
  final int questionNo;
  final String prompt;
  final String explanation;
  final List<_OptionVm> options;

  const _QuestionVm({
    required this.id,
    required this.questionNo,
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

class _QuizProgressHeader extends StatelessWidget {
  const _QuizProgressHeader({
    required this.questionNumber,
    required this.totalQuestions,
    required this.answered,
    required this.flagged,
    required this.timeLabel,
    required this.timeWarning,
    required this.compact,
  });

  final int questionNumber;
  final int totalQuestions;
  final int answered;
  final int flagged;
  final String timeLabel;
  final bool timeWarning;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions == 0 ? 0.0 : questionNumber / totalQuestions;
    final timerColor = timeWarning ? AppColors.warning : AppColors.textOnRed;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandRedDeep,
            AppColors.brandRedDark,
            AppColors.brandRed,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandRed.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeaderPill(
                icon: Icons.quiz_rounded,
                label: '${t(context, 'Question', 'Tanong')} $questionNumber/$totalQuestions',
              ),
              const Spacer(),
              _HeaderPill(
                icon: Icons.timer_outlined,
                label: timeLabel,
                foregroundColor: timerColor,
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: compact ? 7 : 9,
              backgroundColor: AppColors.textOnRed.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.textOnRed,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              Text(
                t(context, 'Progress', 'Progreso'),
                style: TextStyle(
                  color: AppColors.textOnRed.withOpacity(0.76),
                  fontFamily: 'Poppins',
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${t(context, 'Answered', 'Nasagutan')}: $answered/$totalQuestions',
                style: TextStyle(
                  color: AppColors.textOnRed,
                  fontFamily: 'Poppins',
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (flagged > 0) ...[
                const SizedBox(width: 10),
                Text(
                  '${t(context, 'Flagged', 'Naka-flag')}: $flagged',
                  style: TextStyle(
                    color: AppColors.textOnRed,
                    fontFamily: 'Poppins',
                    fontSize: compact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    this.foregroundColor = AppColors.textOnRed,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textOnRed.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.textOnRed.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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
            label: t(context, 'Answered', 'Nasagutan'),
            value: '$answered / $total',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.outlined_flag_rounded,
            label: t(context, 'Flagged', 'Naka-flag'),
            value: '$flagged',
            color: AppColors.brandRed,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
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
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
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
    required this.compact,
  });

  final int questionNumber;
  final int totalQuestions;
  final String question;
  final bool isFlagged;
  final VoidCallback? onFlagTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 14),
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
                  color: AppColors.brandRedSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${t(context, 'Question', 'Tanong')} $questionNumber',
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onFlagTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFlagged
                        ? AppColors.brandRedSoft
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isFlagged ? AppColors.brandRed : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFlagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                        size: 16,
                        color: isFlagged
                            ? AppColors.brandRed
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFlagged
                            ? t(context, 'Flagged', 'Naka-flag')
                            : t(context, 'Flag', 'I-flag'),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isFlagged
                              ? AppColors.brandRed
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 18),
          Text(
            question,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 16.5 : 20,
              height: compact ? 1.28 : 1.38,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
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
    required this.enabled,
    required this.onTap,
    required this.compact,
    required this.maxTextLines,
  });

  final String label;
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final bool compact;
  final int maxTextLines;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.brandRed : AppColors.border;
    final bgColor = selected ? AppColors.brandRedSoft : AppColors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 15,
            vertical: compact ? 9 : 15,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.brandRed.withOpacity(0.14)
                    : AppColors.shadow,
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 32 : 38,
                height: compact ? 32 : 38,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brandRed : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(compact ? 11 : 14),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textOnRed
                          : AppColors.textSecondary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 13.2 : 15,
                      height: compact ? 1.28 : 1.45,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.brandRed,
                  size: 22,
                ),
              ],
            ],
          ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandRedSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
    final statusColor = hasUnanswered ? AppColors.warning : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: statusColor.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  hasUnanswered
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'Review before submitting', 'Suriin bago ipasa'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasUnanswered
                          ? t(
                              context,
                              '$unansweredCount question(s) still need an answer.',
                              '$unansweredCount tanong pa ang kailangang sagutin.',
                            )
                          : t(
                              context,
                              'All questions have an answer.',
                              'Nasagutan na ang lahat ng tanong.',
                            ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
    final statusColor = answered ? AppColors.success : AppColors.error;
    final cardBackground = answered
        ? AppColors.surface
        : AppColors.error.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: answered
              ? AppColors.success.withOpacity(0.18)
              : AppColors.error.withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
                  color: AppColors.brandRedSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandRed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  answered
                      ? t(context, 'Answered', 'Nasagutan')
                      : t(context, 'Unanswered', 'Hindi pa nasasagutan'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: t(context, 'Flag', 'I-flag'),
                onPressed: onFlagTap,
                icon: Icon(
                  flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                  color: flagged ? AppColors.brandRed : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            question,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            selectedAnswer,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: answered ? AppColors.textSecondary : AppColors.error,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.textOnRed,
                size: 17,
              ),
              label: Text(
                t(context, 'Edit', 'I-edit'),
                style: const TextStyle(
                  color: AppColors.textOnRed,
                  fontFamily: 'Poppins',
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
    final strong = percent >= 75;
    final color = strong ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            strong ? Icons.emoji_events_rounded : Icons.tips_and_updates_rounded,
            color: color,
            size: 38,
          ),
          const SizedBox(height: 8),
          Text(
            t(context, 'Pre-Assessment Result', 'Resulta ng Paunang Pagsusulit'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score / $total',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0.0 : score / total,
              minHeight: 9,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percent%',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
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
    final statusColor = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      color: statusColor,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCorrect
                          ? t(context, 'Correct', 'Tama')
                          : t(context, 'Incorrect', 'Mali'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            question,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              height: 1.42,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _AnswerBlock(
            title: t(context, 'Your Answer', 'Sagot Mo'),
            body: userAnswer,
            color: statusColor,
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            _AnswerBlock(
              title: t(context, 'Correct Answer', 'Tamang Sagot'),
              body: correctAnswer,
              color: AppColors.success,
            ),
          ],
          if (!isCorrect && explanation != null && explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, 'Explanation', 'Paliwanag'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandRed,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    explanation!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
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
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
