import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressionAccessDenied implements Exception {
  const ProgressionAccessDenied(this.message);

  final String message;

  @override
  String toString() => message;
}

class AssessmentAttemptSummary {
  const AssessmentAttemptSummary({
    required this.id,
    required this.assessmentId,
    required this.submittedAt,
    required this.status,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
  });

  final String id;
  final String assessmentId;
  final String? submittedAt;
  final String status;
  final double? score;
  final int correctCount;
  final int totalQuestions;

  bool get isSubmitted =>
      submittedAt != null && status == 'submitted' && score != null;

  factory AssessmentAttemptSummary.fromRow(Map<String, dynamic> row) {
    return AssessmentAttemptSummary(
      id: row['id'].toString(),
      assessmentId: row['assessment_id'].toString(),
      submittedAt: row['submitted_at']?.toString(),
      status: (row['status'] ?? '').toString(),
      score: _toDoubleOrNull(row['score']),
      correctCount: _toInt(row['correct_count']),
      totalQuestions: _toInt(row['total_questions']),
    );
  }
}

class ModuleProgressionState {
  const ModuleProgressionState({
    required this.userId,
    required this.moduleId,
    required this.preAssessmentId,
    required this.postAssessmentId,
    required this.progressRow,
    required this.preTestAttempt,
    required this.postTestAttempt,
  });

  final String userId;
  final String moduleId;
  final String preAssessmentId;
  final String? postAssessmentId;
  final Map<String, dynamic>? progressRow;
  final AssessmentAttemptSummary? preTestAttempt;
  final AssessmentAttemptSummary? postTestAttempt;

  bool get hasProgressPreTestCompletion {
    if (progressRow == null) return false;
    return progressRow!['pre_test_completed_at'] != null &&
        _notBlank(progressRow!['pre_test_attempt_id']) &&
        progressRow!['pre_test_score'] != null;
  }

  bool get hasSubmittedPreTest => preTestAttempt?.isSubmitted == true;

  bool get hasValidPreTest {
    if (!hasProgressPreTestCompletion || !hasSubmittedPreTest) return false;
    return progressRow!['pre_test_attempt_id'].toString() == preTestAttempt!.id;
  }

  bool get hasLearningModuleCompletion {
    if (progressRow == null) return false;
    return progressRow!['learning_material_completed_at'] != null &&
        progressRow!['learning_material_read_status'] == true;
  }

  bool get hasProgressPostTestCompletion {
    if (progressRow == null) return false;
    return progressRow!['post_test_completed_at'] != null &&
        _notBlank(progressRow!['post_test_attempt_id']) &&
        progressRow!['post_test_score'] != null;
  }

  bool get hasSubmittedPostTest => postTestAttempt?.isSubmitted == true;

  bool get hasValidPostTest {
    if (!hasProgressPostTestCompletion || !hasSubmittedPostTest) return false;
    return progressRow!['post_test_attempt_id'].toString() == postTestAttempt!.id;
  }
}

class ModuleProgressionService {
  ModuleProgressionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String preTestAlreadyTakenMessage =
      'You can only take the pre-test once. Try learning the next module.';

  static const String postTestAlreadyTakenMessage =
      'You can only take the post-test once. Try learning the next module.';

  Future<ModuleProgressionState> getState({required int moduleNo}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ProgressionAccessDenied('Please log in again to continue.');
    }

    final moduleRow = await _client
        .from('modules')
        .select('id')
        .eq('module_no', moduleNo)
        .maybeSingle();

    if (moduleRow == null) {
      throw ProgressionAccessDenied('Module $moduleNo was not found.');
    }

    final moduleId = moduleRow['id'].toString();
    final preAssessmentId = await _assessmentId(
      moduleId: moduleId,
      type: 'pre',
      moduleNo: moduleNo,
    );
    final postAssessmentId = await _maybeAssessmentId(
      moduleId: moduleId,
      type: 'post',
    );

    var progressRow = await _latestProgressRow(
      userId: user.id,
      moduleId: moduleId,
    );

    final preAttempt = await _submittedAttempt(
      userId: user.id,
      assessmentId: preAssessmentId,
    );
    final postAttempt = postAssessmentId == null
        ? null
        : await _submittedAttempt(
            userId: user.id,
            assessmentId: postAssessmentId,
          );

    progressRow = await _repairProgressIfNeeded(
      userId: user.id,
      moduleId: moduleId,
      progressRow: progressRow,
      preAttempt: preAttempt,
      postAttempt: postAttempt,
    );

    return ModuleProgressionState(
      userId: user.id,
      moduleId: moduleId,
      preAssessmentId: preAssessmentId,
      postAssessmentId: postAssessmentId,
      progressRow: progressRow,
      preTestAttempt: preAttempt,
      postTestAttempt: postAttempt,
    );
  }

  Future<ModuleProgressionState> ensureCanStartPreTest({
    required int moduleNo,
  }) async {
    final state = await getState(moduleNo: moduleNo);
    if (state.hasSubmittedPreTest || state.hasProgressPreTestCompletion) {
      throw const ProgressionAccessDenied(preTestAlreadyTakenMessage);
    }
    return state;
  }

  Future<ModuleProgressionState> ensureCanOpenLearningModule({
    required int moduleNo,
  }) async {
    final state = await getState(moduleNo: moduleNo);
    if (!state.hasValidPreTest) {
      throw const ProgressionAccessDenied(
        'Learning Module is locked until the Pre-Assessment is completed and saved.',
      );
    }
    return state;
  }

  Future<ModuleProgressionState> ensureCanStartPostTest({
    required int moduleNo,
  }) async {
    final state = await getState(moduleNo: moduleNo);

    if (state.postAssessmentId == null || state.postAssessmentId!.isEmpty) {
      throw ProgressionAccessDenied(
        'Post-assessment for module $moduleNo was not found.',
      );
    }

    if (state.hasSubmittedPostTest || state.hasProgressPostTestCompletion) {
      throw const ProgressionAccessDenied(postTestAlreadyTakenMessage);
    }

    if (!state.hasValidPreTest) {
      throw const ProgressionAccessDenied(
        'Post-Assessment is locked. Complete and save the Pre-Assessment first.',
      );
    }

    if (!state.hasLearningModuleCompletion) {
      throw const ProgressionAccessDenied(
        'Post-Assessment is locked. Finish the Learning Module first.',
      );
    }

    return state;
  }

  Future<void> markLearningMaterialCompleted({required int moduleNo}) async {
    final state = await ensureCanOpenLearningModule(moduleNo: moduleNo);
    final completedAt = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'learning_material_read_status': true,
      'learning_material_completed_at': completedAt,
      'updated_at': completedAt,
    };

    if (state.progressRow == null) {
      await _client.from('module_progress').insert({
        'user_id': state.userId,
        'module_id': state.moduleId,
        ...payload,
      });
      return;
    }

    await _client
        .from('module_progress')
        .update(payload)
        .eq('id', state.progressRow!['id']);
  }

  Future<String?> _maybeAssessmentId({
    required String moduleId,
    required String type,
  }) async {
    final row = await _client
        .from('assessments')
        .select('id')
        .eq('module_id', moduleId)
        .eq('type', type)
        .maybeSingle();

    return row == null ? null : row['id'].toString();
  }

  Future<String> _assessmentId({
    required String moduleId,
    required String type,
    required int moduleNo,
  }) async {
    final row = await _client
        .from('assessments')
        .select('id')
        .eq('module_id', moduleId)
        .eq('type', type)
        .maybeSingle();

    if (row == null) {
      throw ProgressionAccessDenied(
        'Assessment for module $moduleNo and type "$type" was not found.',
      );
    }
    return row['id'].toString();
  }

  Future<Map<String, dynamic>?> _latestProgressRow({
    required String userId,
    required String moduleId,
  }) async {
    final rows = await _client
        .from('module_progress')
        .select(
          'id, user_id, module_id, pre_test_completed_at, pre_test_attempt_id, pre_test_score, pre_test_correct_count, pre_test_total_questions, learning_material_completed_at, learning_material_read_status, post_test_completed_at, post_test_attempt_id, post_test_score, post_test_correct_count, post_test_total_questions, improvement_score, has_improved, updated_at',
        )
        .eq('user_id', userId)
        .eq('module_id', moduleId)
        .order('updated_at', ascending: false)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<AssessmentAttemptSummary?> _submittedAttempt({
    required String userId,
    required String assessmentId,
  }) async {
    final rows = await _client
        .from('assessment_attempts')
        .select(
          'id, assessment_id, submitted_at, status, score, correct_count, total_questions, started_at',
        )
        .eq('user_id', userId)
        .eq('assessment_id', assessmentId)
        .eq('status', 'submitted')
        .order('submitted_at', ascending: false)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    final attempt = AssessmentAttemptSummary.fromRow(
      Map<String, dynamic>.from(rows.first as Map),
    );
    return attempt.isSubmitted ? attempt : null;
  }

  Future<Map<String, dynamic>?> _repairProgressIfNeeded({
    required String userId,
    required String moduleId,
    required Map<String, dynamic>? progressRow,
    required AssessmentAttemptSummary? preAttempt,
    required AssessmentAttemptSummary? postAttempt,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{};

    if (preAttempt != null && preAttempt.isSubmitted) {
      final missingPre = progressRow == null ||
          progressRow['pre_test_completed_at'] == null ||
          progressRow['pre_test_attempt_id']?.toString() != preAttempt.id ||
          progressRow['pre_test_score'] == null;

      if (missingPre) {
        payload.addAll({
          'pre_test_completed_at': preAttempt.submittedAt,
          'pre_test_attempt_id': preAttempt.id,
          'pre_test_score': preAttempt.score,
          'pre_test_correct_count': preAttempt.correctCount,
          'pre_test_total_questions': preAttempt.totalQuestions,
        });
      }
    }

    if (postAttempt != null && postAttempt.isSubmitted) {
      final preScore = _toDoubleOrNull(
        payload['pre_test_score'] ?? progressRow?['pre_test_score'],
      );
      final improvementScore = postAttempt.score == null || preScore == null
          ? null
          : postAttempt.score! - preScore;

      final missingPost = progressRow == null ||
          progressRow['post_test_completed_at'] == null ||
          progressRow['post_test_attempt_id']?.toString() != postAttempt.id ||
          progressRow['post_test_score'] == null;

      if (missingPost) {
        payload.addAll({
          'post_test_completed_at': postAttempt.submittedAt,
          'post_test_attempt_id': postAttempt.id,
          'post_test_score': postAttempt.score,
          'post_test_correct_count': postAttempt.correctCount,
          'post_test_total_questions': postAttempt.totalQuestions,
          if (improvementScore != null) 'improvement_score': improvementScore,
          if (improvementScore != null) 'has_improved': improvementScore > 0,
        });
      }
    }

    if (payload.isEmpty) return progressRow;

    payload['updated_at'] = now;

    if (progressRow == null) {
      final inserted = await _client
          .from('module_progress')
          .insert({
            'user_id': userId,
            'module_id': moduleId,
            ...payload,
          })
          .select()
          .single();
      return Map<String, dynamic>.from(inserted as Map);
    }

    final updated = await _client
        .from('module_progress')
        .update(payload)
        .eq('id', progressRow['id'])
        .select()
        .single();
    return Map<String, dynamic>.from(updated as Map);
  }
}

bool _notBlank(dynamic value) => value != null && value.toString().trim().isNotEmpty;

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
