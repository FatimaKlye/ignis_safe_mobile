import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimulationTrackingSession {
  final String moduleId;
  final String attemptId;
  final bool alreadyCompleted;

  const SimulationTrackingSession({
    required this.moduleId,
    required this.attemptId,
    this.alreadyCompleted = false,
  });
}

class SimulationHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<SimulationTrackingSession> startAttempt({
    required int moduleNo,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      final user = session?.user ?? _supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException('Please log in again to start a simulation.');
      }

      final moduleRow = await _supabase
          .from('modules')
          .select('id')
          .eq('module_no', moduleNo)
          .limit(1)
          .maybeSingle();

      if (moduleRow == null) {
        throw StateError('Module $moduleNo was not found.');
      }

      final moduleId = moduleRow['id'].toString();

      final completedAttempt = await _supabase
          .from('simulation_attempts')
          .select('id')
          .eq('user_id', user.id)
          .eq('module_id', moduleId)
          .eq('status', 'done')
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (completedAttempt != null) {
        return SimulationTrackingSession(
          moduleId: moduleId,
          attemptId: completedAttempt['id'].toString(),
          alreadyCompleted: true,
        );
      }

      // Reuse an unfinished attempt instead of creating a duplicate every
      // time the same scene is reopened.
      final unfinishedAttempt = await _supabase
          .from('simulation_attempts')
          .select('id')
          .eq('user_id', user.id)
          .eq('module_id', moduleId)
          .eq('status', 'in_progress')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (unfinishedAttempt != null) {
        return SimulationTrackingSession(
          moduleId: moduleId,
          attemptId: unfinishedAttempt['id'].toString(),
        );
      }

      Map<String, dynamic> inserted;
      final payload = {
        'user_id': user.id,
        'module_id': moduleId,
        'status': 'in_progress',
      };

      try {
        inserted = await _supabase
            .from('simulation_attempts')
            .insert(payload)
            .select('id')
            .single();
      } on PostgrestException catch (e) {
        final isRlsViolation =
            e.code == '42501' || e.message.contains('row-level security');

        if (!isRlsViolation) rethrow;

        // Some setups derive user_id from auth.uid() via default/trigger.
        inserted = await _supabase
            .from('simulation_attempts')
            .insert({'module_id': moduleId, 'status': 'in_progress'})
            .select('id')
            .single();
      }

      return SimulationTrackingSession(
        moduleId: moduleId,
        attemptId: inserted['id'].toString(),
      );
    } catch (e) {
      debugPrint('SIMULATION START ERROR: $e');
      rethrow;
    }
  }

  Future<void> completeAttempt({
    required String moduleId,
    required String attemptId,
    num? score,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException('Please log in again to save progress.');
      }

      final now = DateTime.now().toUtc().toIso8601String();

      final savedAttempt = await _supabase
          .from('simulation_attempts')
          .update({
            'status': 'done',
            'submitted_at': now,
            if (score != null) 'score': score,
          })
          .eq('id', attemptId)
          .eq('user_id', user.id)
          .eq('module_id', moduleId)
          .select('id, status')
          .single();

      if (savedAttempt['status'] != 'done') {
        throw StateError('The completed simulation attempt was not saved.');
      }

      await _supabase.from('module_progress').upsert({
        'user_id': user.id,
        'module_id': moduleId,
        'simulation_completed_at': now,
        'updated_at': now,
      }, onConflict: 'user_id,module_id');

      final savedProgress = await _supabase
          .from('module_progress')
          .select('simulation_completed_at')
          .eq('user_id', user.id)
          .eq('module_id', moduleId)
          .single();

      if (savedProgress['simulation_completed_at'] == null) {
        throw StateError('The simulation progress could not be verified.');
      }
    } catch (e) {
      debugPrint('SIMULATION COMPLETE ERROR: $e');
      rethrow;
    }
  }
}
