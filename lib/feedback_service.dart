import 'package:supabase_flutter/supabase_flutter.dart';

/// The current account's Feedback submission cooldown, as computed by
/// `public.get_feedback_cooldown()` from the actual latest `user_feedback`
/// row for this user — never derived or cached locally.
class FeedbackCooldown {
  const FeedbackCooldown({required this.isLimited, this.nextAllowedAt});

  final bool isLimited;
  final DateTime? nextAllowedAt;
}

/// Writes learner feedback (star rating + optional comment) submitted from
/// Mobile > Profile > Account & Support to `public.user_feedback`.
class FeedbackService {
  FeedbackService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const String _table = 'user_feedback';

  /// Hint set on the Postgres error raised by the `user_feedback_rate_limit`
  /// trigger when an insert is attempted before the 72-hour cooldown ends.
  static const String rateLimitHint = 'feedback_rate_limited';

  /// Asks the database for this account's real cooldown state (based on its
  /// latest `user_feedback` row) so the UI can gate the Submit button before
  /// attempting an insert. The 72-hour rule itself is enforced separately by
  /// the `user_feedback_rate_limit` trigger, which is what actually prevents
  /// a submission — this call only informs the UI.
  Future<FeedbackCooldown> getFeedbackCooldown() async {
    final response = await _supabase.rpc('get_feedback_cooldown');
    final rows = response as List<dynamic>;
    if (rows.isEmpty) return const FeedbackCooldown(isLimited: false);

    final row = Map<String, dynamic>.from(rows.first as Map);
    final nextAllowedAtRaw = row['next_allowed_at'] as String?;
    return FeedbackCooldown(
      isLimited: row['is_limited'] as bool? ?? false,
      nextAllowedAt: nextAllowedAtRaw == null
          ? null
          : DateTime.parse(nextAllowedAtRaw).toLocal(),
    );
  }

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
