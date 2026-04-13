import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProgressSync {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> syncCompletedSimulations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final rows = await _supabase
        .from('module_progress')
        .select('pre_test_completed_at, simulation_completed_at, post_test_completed_at')
        .eq('user_id', user.id);

    int completedModules = 0;

    for (final row in rows) {
      final preDone = row['pre_test_completed_at'] != null;
      final simDone = row['simulation_completed_at'] != null;
      final postDone = row['post_test_completed_at'] != null;

      if (preDone && simDone && postDone) {
        completedModules++;
      }
    }

    await _supabase
        .from('profiles')
        .update({
          'completed_simulations': completedModules,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }

  static Future<void> updateLastSimulation(String label) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('profiles')
        .update({
          'last_simulation': label,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }
}
