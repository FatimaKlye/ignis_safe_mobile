import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'module_progress_refresh_notifier.dart';

/// Thrown when a finished Pre-Assessment cannot be confirmed as stored in
/// Supabase. Carries the real reason so the learner sees what actually went
/// wrong instead of silently losing the completion.
class PreAssessmentNotSavedException implements Exception {
  const PreAssessmentNotSavedException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Confirms that a submitted Pre-Assessment really is persisted before the
/// learner is allowed to leave the Score Result screen.
///
/// The Pre-Assessment is saved by the assessment page itself, at submit time
/// and before the Score Result screen is shown. This guard never creates a
/// completion: it only re-reads the learner's own Supabase records and, when
/// the `module_progress` row is missing or out of sync with the attempt that
/// was actually submitted, rewrites it *from that attempt*. Scores, answers
/// and every other column are left exactly as the submission wrote them.
///
/// It is idempotent and safe to call repeatedly:
///  * the module progress write is a single upsert keyed on the existing
///    `module_progress_user_id_module_id_key` unique constraint, so repeated
///    taps can never create a duplicate progress record;
///  * concurrent calls for the same attempt share one in-flight future, so
///    double-tapping X does not fire two round trips.
class PreAssessmentCompletionGuard {
  PreAssessmentCompletionGuard._();

  static final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  /// Resolves once the attempt and its module progress record are confirmed
  /// stored. Throws [PreAssessmentNotSavedException] with the real reason
  /// when the completion cannot be confirmed.
  static Future<void> confirmSaved({
    required int moduleNo,
    required String attemptId,
    SupabaseClient? client,
  }) {
    final key = '$moduleNo:$attemptId';
    final running = _inFlight[key];
    if (running != null) return running;

    final pending = _confirm(
      moduleNo: moduleNo,
      attemptId: attemptId,
      client: client ?? Supabase.instance.client,
    );

    _inFlight[key] = pending;

    return pending.whenComplete(() {
      if (identical(_inFlight[key], pending)) {
        _inFlight.remove(key);
      }
    });
  }

  static Future<void> _confirm({
    required int moduleNo,
    required String attemptId,
    required SupabaseClient client,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const PreAssessmentNotSavedException(
        'You are signed out, so your Pre-Assessment result cannot be '
        'confirmed. Please log in again.',
      );
    }

    final trimmedAttemptId = attemptId.trim();
    if (trimmedAttemptId.isEmpty) {
      throw const PreAssessmentNotSavedException(
        'This Pre-Assessment result has no saved attempt to confirm.',
      );
    }

    final moduleRow = await client
        .from('modules')
        .select('id')
        .eq('module_no', moduleNo)
        .maybeSingle();

    if (moduleRow == null) {
      throw PreAssessmentNotSavedException(
        'Module $moduleNo was not found, so its progress cannot be updated.',
      );
    }
    final moduleId = moduleRow['id'].toString();

    final assessmentRow = await client
        .from('assessments')
        .select('id')
        .eq('module_id', moduleId)
        .eq('type', 'pre')
        .maybeSingle();

    if (assessmentRow == null) {
      throw PreAssessmentNotSavedException(
        'The Pre-Assessment for module $moduleNo was not found, so its '
        'progress cannot be updated.',
      );
    }
    final assessmentId = assessmentRow['id'].toString();

    // 1. The completed attempt must already be stored as submitted.
    final attemptRow = await client
        .from('assessment_attempts')
        .select(
          'id, submitted_at, status, score, correct_count, total_questions',
        )
        .eq('id', trimmedAttemptId)
        .eq('user_id', user.id)
        .eq('assessment_id', assessmentId)
        .maybeSingle();

    if (attemptRow == null) {
      throw const PreAssessmentNotSavedException(
        'Your Pre-Assessment attempt was not found in your saved records. '
        'Please check your connection and try again.',
      );
    }

    final submittedAt = attemptRow['submitted_at']?.toString();
    final status = (attemptRow['status'] ?? '').toString();
    final score = attemptRow['score'];

    if (submittedAt == null ||
        submittedAt.trim().isEmpty ||
        status != 'submitted' ||
        score == null) {
      throw const PreAssessmentNotSavedException(
        'Your Pre-Assessment attempt is not stored as submitted yet. Please '
        'check your connection and try again.',
      );
    }

    // 2. The module progress record must point at that same attempt. There is
    // at most one row per (user_id, module_id) thanks to the unique
    // constraint, so this reads and writes exactly one record.
    final progressRow = await client
        .from('module_progress')
        .select('id, pre_test_completed_at, pre_test_attempt_id, pre_test_score')
        .eq('user_id', user.id)
        .eq('module_id', moduleId)
        .maybeSingle();

    final progressIsInSync = progressRow != null &&
        progressRow['pre_test_completed_at'] != null &&
        progressRow['pre_test_score'] != null &&
        progressRow['pre_test_attempt_id']?.toString() == trimmedAttemptId;

    if (!progressIsInSync) {
      await client.from('module_progress').upsert(
        {
          'user_id': user.id,
          'module_id': moduleId,
          'pre_test_completed_at': submittedAt,
          'pre_test_attempt_id': trimmedAttemptId,
          'pre_test_score': score,
          'pre_test_correct_count': attemptRow['correct_count'],
          'pre_test_total_questions': attemptRow['total_questions'],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,module_id',
      );
    }

    // 3. Read the record back so a write that silently affected no rows (for
    // example when it was rejected by row-level security) is reported instead
    // of being mistaken for a saved completion.
    final verifiedRow = await client
        .from('module_progress')
        .select('pre_test_completed_at, pre_test_attempt_id, pre_test_score')
        .eq('user_id', user.id)
        .eq('module_id', moduleId)
        .maybeSingle();

    final verified = verifiedRow != null &&
        verifiedRow['pre_test_completed_at'] != null &&
        verifiedRow['pre_test_score'] != null &&
        verifiedRow['pre_test_attempt_id']?.toString() == trimmedAttemptId;

    if (!verified) {
      throw const PreAssessmentNotSavedException(
        'Your Pre-Assessment completion could not be confirmed as saved. '
        'Please check your connection and try again.',
      );
    }

    debugPrint(
      'PRE-ASSESSMENT COMPLETION CONFIRMED: module $moduleNo, '
      'attempt $trimmedAttemptId',
    );

    notifyModuleProgressChanged();
  }
}
