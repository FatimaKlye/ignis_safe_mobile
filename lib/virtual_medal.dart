import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'module_progress_overview_service.dart';

class VirtualMedal {
  const VirtualMedal({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    this.moduleNo,
    this.earned = false,
    this.earnedAt,
  });

  final String code;
  final int? moduleNo;
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final bool earned;
  final DateTime? earnedAt;

  bool get isCompletionMedal => code == 'all_modules';

  VirtualMedal copyWith({bool? earned, DateTime? earnedAt}) {
    return VirtualMedal(
      code: code,
      moduleNo: moduleNo,
      title: title,
      description: description,
      icon: icon,
      primaryColor: primaryColor,
      accentColor: accentColor,
      earned: earned ?? this.earned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  static const List<VirtualMedal> catalog = <VirtualMedal>[
    VirtualMedal(
      code: 'module_1',
      moduleNo: 1,
      title: 'Extinguisher Ready',
      description: 'Completed Fire Extinguisher training.',
      icon: Icons.fire_extinguisher_rounded,
      primaryColor: Color(0xFFB11217),
      accentColor: Color(0xFFFFC857),
    ),
    VirtualMedal(
      code: 'module_2',
      moduleNo: 2,
      title: 'Escape Prepared',
      description: 'Completed House Fire Escape training.',
      icon: Icons.home_rounded,
      primaryColor: Color(0xFF173B6C),
      accentColor: Color(0xFFE95043),
    ),
    VirtualMedal(
      code: 'module_3',
      moduleNo: 3,
      title: 'Electrical Aware',
      description: 'Completed Electrical Fire training.',
      icon: Icons.electrical_services_rounded,
      primaryColor: Color(0xFF253B59),
      accentColor: Color(0xFFFFC23D),
    ),
    VirtualMedal(
      code: 'module_4',
      moduleNo: 4,
      title: 'Kitchen Guardian',
      description: 'Completed Kitchen Fire training.',
      icon: Icons.soup_kitchen_rounded,
      primaryColor: Color(0xFFC44A1A),
      accentColor: Color(0xFFFFD166),
    ),
    VirtualMedal(
      code: 'module_5',
      moduleNo: 5,
      title: 'Building Responder',
      description: 'Completed Tenement Fire training.',
      icon: Icons.apartment_rounded,
      primaryColor: Color(0xFF7D1720),
      accentColor: Color(0xFFF2B84B),
    ),
    VirtualMedal(
      code: 'all_modules',
      title: 'IGNIS SAFE Champion',
      description: 'Completed all five IGNIS SAFE training modules.',
      icon: Icons.local_fire_department_rounded,
      primaryColor: Color(0xFF142D57),
      accentColor: Color(0xFFFFC857),
    ),
  ];
}

class VirtualMedalService {
  VirtualMedalService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<VirtualMedal>> loadAndSync() async {
    if (_client.auth.currentUser == null) {
      return VirtualMedal.catalog;
    }

    try {
      final response = await _client.rpc('sync_my_virtual_medals');
      final rows = response is List ? response : const <dynamic>[];
      final earnedByCode = <String, DateTime?>{};

      for (final value in rows) {
        if (value is! Map) continue;
        final row = Map<String, dynamic>.from(value);
        final code = (row['medal_code'] ?? '').toString().trim();
        if (code.isEmpty) continue;
        earnedByCode[code] = DateTime.tryParse(
          (row['earned_at'] ?? '').toString(),
        )?.toLocal();
      }

      return VirtualMedal.catalog
          .map(
            (medal) => earnedByCode.containsKey(medal.code)
                ? medal.copyWith(
                    earned: true,
                    earnedAt: earnedByCode[medal.code],
                  )
                : medal,
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Virtual medal sync unavailable, using progress: $error');
      return _loadFromValidatedProgress();
    }
  }

  Future<List<VirtualMedal>> _loadFromValidatedProgress() async {
    try {
      final progress = await ModuleProgressOverviewService(
        client: _client,
      ).load();
      final completedModules = <int>{
        for (final entry in progress.entries)
          if (entry.value.isCompleted) entry.key,
      };
      final allComplete = completedModules.length == 5;

      return VirtualMedal.catalog
          .map(
            (medal) => medal.copyWith(
              earned: medal.isCompletionMedal
                  ? allComplete
                  : completedModules.contains(medal.moduleNo),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('Virtual medal fallback failed: $error');
      return VirtualMedal.catalog;
    }
  }
}
