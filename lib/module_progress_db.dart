import 'package:supabase_flutter/supabase_flutter.dart';

class ModuleProgressDb {
  static Future<void> markSimulationCompleted(int moduleNo) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final moduleRow = await supabase
        .from('modules')
        .select('id')
        .eq('module_no', moduleNo)
        .maybeSingle();

    if (moduleRow == null) {
      throw Exception('Module $moduleNo not found in modules table.');
    }

    final moduleId = moduleRow['id'].toString();

    final existing = await supabase
        .from('module_progress')
        .select('id')
        .eq('user_id', user.id)
        .eq('module_id', moduleId)
        .maybeSingle();

    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      await supabase
          .from('module_progress')
          .update({
            'simulation_completed_at': now,
          })
          .eq('id', existing['id']);
    } else {
      await supabase
          .from('module_progress')
          .insert({
            'user_id': user.id,
            'module_id': moduleId,
            'simulation_completed_at': now,
          });
    }
  }
}