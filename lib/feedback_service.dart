import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes learner feedback (star rating + optional comment) submitted from
/// Mobile > Profile > Account & Support to `public.user_feedback`.
class FeedbackService {
  FeedbackService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const String _table = 'user_feedback';

  Future<void> submitFeedback({
    required String userId,
    required int rating,
    String? comment,
  }) async {
    assert(rating >= 1 && rating <= 5);

    final trimmedComment = comment?.trim();

    await _supabase.from(_table).insert({
      'user_id': userId,
      'rating': rating,
      'comment': (trimmedComment == null || trimmedComment.isEmpty)
          ? null
          : trimmedComment,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
