import 'package:supabase_flutter/supabase_flutter.dart';

class ModuleProgressOverview {
  const ModuleProgressOverview({
    required this.moduleNo,
    required this.preTestCompleted,
    required this.canOpenLearning,
    required this.learningCompleted,
    required this.canOpenPostTest,
    required this.postTestCompleted,
  });

  final int moduleNo;
  final bool preTestCompleted;
  final bool canOpenLearning;
  final bool learningCompleted;
  final bool canOpenPostTest;
  final bool postTestCompleted;

  factory ModuleProgressOverview.fromMap(Map<String, dynamic> row) {
    return ModuleProgressOverview(
      moduleNo: _toInt(row['module_no']),
      preTestCompleted: row['pre_test_completed'] == true,
      canOpenLearning: row['can_open_learning'] == true,
      learningCompleted: row['learning_completed'] == true,
      canOpenPostTest: row['can_open_post_test'] == true,
      postTestCompleted: row['post_test_completed'] == true,
    );
  }
}

class ModuleProgressOverviewService {
  ModuleProgressOverviewService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<int, ModuleProgressOverview>> load() async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('Please log in again to continue.');
    }

    final response = await _client.rpc('get_my_module_progress_overview');
    final rows = response is List ? response : const <dynamic>[];
    final result = <int, ModuleProgressOverview>{};

    for (final value in rows) {
      if (value is! Map) continue;
      final progress = ModuleProgressOverview.fromMap(
        Map<String, dynamic>.from(value),
      );
      if (progress.moduleNo > 0) {
        result[progress.moduleNo] = progress;
      }
    }

    return result;
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
