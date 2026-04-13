import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimulationTrackingSession {
  final String moduleId;
  final String attemptId;

  const SimulationTrackingSession({
    required this.moduleId,
    required this.attemptId,
  });
}

class SimulationHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<SimulationTrackingSession?> startAttempt({
    required int moduleNo,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final moduleRow = await _supabase
          .from('modules')
          .select('id')
          .eq('module_no', moduleNo)
          .limit(1)
          .maybeSingle();

      if (moduleRow == null) return null;

      final moduleId = moduleRow['id'].toString();

      final inserted = await _supabase
          .from('simulation_attempts')
          .insert({
            'user_id': user.id,
            'module_id': moduleId,
            'status': 'in_progress',
          })
          .select('id')
          .single();

      return SimulationTrackingSession(
        moduleId: moduleId,
        attemptId: inserted['id'].toString(),
      );
    } catch (e) {
      debugPrint('SIMULATION START ERROR: $e');
      return null;
    }
  }

  Future<void> completeAttempt({
    required String moduleId,
    required String attemptId,
    num? score,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now().toUtc().toIso8601String();

      await _supabase
          .from('simulation_attempts')
          .update({
            'status': 'submitted',
            'submitted_at': now,
            'score': score,
          })
          .eq('id', attemptId);

      final progressRow = await _supabase
          .from('module_progress')
          .select('id')
          .eq('user_id', user.id)
          .eq('module_id', moduleId)
          .limit(1)
          .maybeSingle();

      if (progressRow == null) {
        await _supabase.from('module_progress').insert({
          'user_id': user.id,
          'module_id': moduleId,
          'simulation_completed_at': now,
        });
      } else {
        await _supabase
            .from('module_progress')
            .update({
              'simulation_completed_at': now,
            })
            .eq('id', progressRow['id']);
      }
    } catch (e) {
      debugPrint('SIMULATION COMPLETE ERROR: $e');
    }
  }
}

