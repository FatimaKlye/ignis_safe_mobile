import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProgressSync {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const int defaultTrainingSimulationTotal = 5;

  static Future<void> syncCompletedSimulations({
    int totalSimulations = defaultTrainingSimulationTotal,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final completedSimulations = await fetchCompletedSimulationCount(
      totalSimulations: totalSimulations,
    );

    await _supabase
        .from('profiles')
        .update({
          'completed_simulations': completedSimulations,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }

  static Future<int> fetchCompletedSimulationCount({
    int totalSimulations = defaultTrainingSimulationTotal,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final moduleRows = await _supabase
        .from('modules')
        .select('id')
        .gte('module_no', 1)
        .lte('module_no', totalSimulations);

    final moduleIds = moduleRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toList();

    if (moduleIds.isEmpty) return 0;

    final rows = await _supabase
        .from('module_progress')
        .select('module_id, simulation_completed_at')
        .eq('user_id', user.id)
        .inFilter('module_id', moduleIds)
        .not('simulation_completed_at', 'is', null);

    return completedSimulationCountFromRows(rows);
  }

  static int completedSimulationCountFromRows(Iterable<dynamic> rows) {
    final completedModuleIds = <String>{};

    for (final row in rows) {
      if (row is! Map) continue;
      if (row['simulation_completed_at'] == null) continue;

      final moduleId = row['module_id']?.toString().trim();
      if (moduleId == null || moduleId.isEmpty) continue;

      completedModuleIds.add(moduleId);
    }

    return completedModuleIds.length;
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
