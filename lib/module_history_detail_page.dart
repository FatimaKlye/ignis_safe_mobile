import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModuleHistoryDetailPage extends StatefulWidget {
  const ModuleHistoryDetailPage({
    super.key,
    required this.moduleId,
    required this.moduleNo,
    required this.moduleTitle,
  });

  final String moduleId;
  final int moduleNo;
  final String moduleTitle;

  @override
  State<ModuleHistoryDetailPage> createState() => _ModuleHistoryDetailPageState();
}

class _ModuleHistoryDetailPageState extends State<ModuleHistoryDetailPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;

  List<Map<String, dynamic>> _preAttempts = [];
  List<Map<String, dynamic>> _postAttempts = [];
  List<Map<String, dynamic>> _simulationAttempts = [];

  bool _preDone = false;
  bool _simDone = false;
  bool _postDone = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final progressRow = await _supabase
          .from('module_progress')
          .select('pre_test_completed_at, simulation_completed_at, post_test_completed_at')
          .eq('user_id', user.id)
          .eq('module_id', widget.moduleId)
          .maybeSingle();

      final preAssessment = await _supabase
          .from('assessments')
          .select('id')
          .eq('module_id', widget.moduleId)
          .eq('type', 'pre')
          .maybeSingle();

      final postAssessment = await _supabase
          .from('assessments')
          .select('id')
          .eq('module_id', widget.moduleId)
          .eq('type', 'post')
          .maybeSingle();

      List<Map<String, dynamic>> preAttempts = [];
      List<Map<String, dynamic>> postAttempts = [];
      List<Map<String, dynamic>> simulationAttempts = [];

      if (preAssessment != null) {
        final rows = await _supabase
            .from('assessment_attempts')
            .select(
              'id, score, correct_count, total_questions, status, started_at, submitted_at, created_at',
            )
            .eq('user_id', user.id)
            .eq('assessment_id', preAssessment['id'])
            .order('created_at', ascending: false);

        preAttempts = List<Map<String, dynamic>>.from(rows);
      }

      if (postAssessment != null) {
        final rows = await _supabase
            .from('assessment_attempts')
            .select(
              'id, score, correct_count, total_questions, status, started_at, submitted_at, created_at',
            )
            .eq('user_id', user.id)
            .eq('assessment_id', postAssessment['id'])
            .order('created_at', ascending: false);

        postAttempts = List<Map<String, dynamic>>.from(rows);
      }

      final simRows = await _supabase
          .from('simulation_attempts')
          .select('id, score, status, started_at, submitted_at, created_at')
          .eq('user_id', user.id)
          .eq('module_id', widget.moduleId)
          .order('created_at', ascending: false);

      simulationAttempts = List<Map<String, dynamic>>.from(simRows);

      if (!mounted) return;
      setState(() {
        _preAttempts = preAttempts;
        _postAttempts = postAttempts;
        _simulationAttempts = simulationAttempts;

        _preDone = progressRow?['pre_test_completed_at'] != null;
        _simDone = progressRow?['simulation_completed_at'] != null;
        _postDone = progressRow?['post_test_completed_at'] != null;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return "No date";
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return "No date";
    final local = dt.toLocal();
    return "${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}/${local.year} "
        "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  String _formatAssessmentScore({
    required Map<String, dynamic> item,
    required String type,
  }) {
    final status = (item['status'] ?? '').toString().toLowerCase();
    if (status != 'submitted') return '—';

    final correctCount = item['correct_count'];
    final totalQuestions = item['total_questions'];

    if (type == 'pre') {
      final correct = correctCount is num
          ? correctCount.toInt()
          : int.tryParse('$correctCount') ?? 0;
      return '$correct / 10';
    }

    if (type == 'post') {
      final correct = correctCount is num
          ? correctCount.toInt()
          : int.tryParse('$correctCount') ?? 0;
      return '$correct / 4';
    }

    return '—';
  }

  String _formatSimulationScore(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString().toLowerCase();
    if (status != 'submitted') return '—';
    return 'N/A';
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
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Text(
                              "MODULE ${widget.moduleNo}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.moduleTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF444444),
                                height: 1.25,
                              ),
                            ),
                          ],
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
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _HistorySectionCard(
                              title: "Pre Assessment",
                              done: _preDone,
                              attempts: _preAttempts,
                              formatDate: _formatDate,
                              formatScore: (item) => _formatAssessmentScore(
                                item: item,
                                type: 'pre',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _HistorySectionCard(
                              title: "Simulation",
                              done: _simDone,
                              attempts: _simulationAttempts,
                              formatDate: _formatDate,
                              formatScore: _formatSimulationScore,
                            ),
                            const SizedBox(height: 14),
                            _HistorySectionCard(
                              title: "Post Assessment",
                              done: _postDone,
                              attempts: _postAttempts,
                              formatDate: _formatDate,
                              formatScore: (item) => _formatAssessmentScore(
                                item: item,
                                type: 'post',
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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

class _HistorySectionCard extends StatelessWidget {
  const _HistorySectionCard({
    required this.title,
    required this.done,
    required this.attempts,
    required this.formatDate,
    required this.formatScore,
  });

  final String title;
  final bool done;
  final List<Map<String, dynamic>> attempts;
  final String Function(dynamic) formatDate;
  final String Function(Map<String, dynamic>) formatScore;

  @override
  Widget build(BuildContext context) {
    final retakes = attempts.isEmpty ? 0 : attempts.length - 1;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: done ? const Color(0x142EB872) : const Color(0x14B11217),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  done ? "DONE" : "NOT DONE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: done ? const Color(0xFF2EB872) : const Color(0xFFB11217),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Total Attempts: ${attempts.length}",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            "Retakes: $retakes",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (attempts.isEmpty)
            const Text(
              "No attempts yet.",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            )
          else
            Column(
              children: List.generate(attempts.length, (index) {
                final item = attempts[index];
                final attemptNo = attempts.length - index;

                return Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 110),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Attempt $attemptNo",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Score: ${formatScore(item)}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Status: ${item['status'] ?? 'N/A'}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Submitted: ${formatDate(item['submitted_at'])}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}