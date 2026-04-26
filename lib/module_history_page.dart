import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/localized_db_text.dart';

import 'module_history_detail_page.dart';

class ModuleHistoryPage extends StatefulWidget {
  const ModuleHistoryPage({super.key});

  @override
  State<ModuleHistoryPage> createState() => _ModuleHistoryPageState();
}

class _ModuleHistoryPageState extends State<ModuleHistoryPage> {
  static const Color brandRed = Color(0xFFB11217);
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _modulesChannel;

  bool _isLoading = true;
  final List<Map<String, dynamic>> _modules = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadModules();
    _subscribeToModules();
  }

  void _subscribeToModules() {
    if (_modulesChannel != null) {
      _supabase.removeChannel(_modulesChannel!);
    }

    _modulesChannel = _supabase
        .channel('module_history_modules_live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'modules',
          callback: (_) async {
            if (!mounted) return;
            await _loadModules();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_modulesChannel != null) {
      _supabase.removeChannel(_modulesChannel!);
    }
    super.dispose();
  }

  Future<void> _loadModules() async {
    try {
      final rows = await _supabase
          .from('modules')
          .select('id, module_no, title, title_tl')
          .order('module_no', ascending: true);

      if (!mounted) return;
      setState(() {
        _modules
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(rows));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 900,
            child: Image.asset('assets/bg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Module History",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          itemCount: _modules.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final module = _modules[index];
                            final moduleId = module['id'].toString();
                            final moduleNo = module['module_no'] as int;
                            final title = LocalizedDbText.pick(
                              context,
                              module,
                              'title',
                              'title_tl',
                              fallback: 'Module $moduleNo',
                            );

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ModuleHistoryDetailPage(
                                      moduleId: moduleId,
                                      moduleNo: moduleNo,
                                      moduleTitle: title,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            LocalizedDbText.moduleLabel(context, moduleNo),
                                            style: const TextStyle(
                                              color: Color(0xFFB11217),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF222222),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}