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
  RealtimeChannel? _progressChannel;
  RealtimeChannel? _assessmentAttemptsChannel;
  RealtimeChannel? _simulationAttemptsChannel;

  bool _isLoading = true;

  List<Map<String, dynamic>> _preAttempts = [];
  List<Map<String, dynamic>> _postAttempts = [];

  bool _preDone = false;
  bool _simDone = false;
  bool _postDone = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadHistory();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_progressChannel != null) {
      _supabase.removeChannel(_progressChannel!);
    }
    if (_assessmentAttemptsChannel != null) {
      _supabase.removeChannel(_assessmentAttemptsChannel!);
    }
    if (_simulationAttemptsChannel != null) {
      _supabase.removeChannel(_simulationAttemptsChannel!);
    }

    _progressChannel = _supabase
        .channel('module_history_progress_${user.id}_${widget.moduleId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'module_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) async {
            if (!mounted) return;
            await _loadHistory();
          },
        )
        .subscribe();

    _assessmentAttemptsChannel = _supabase
        .channel('module_history_assessment_attempts_${user.id}_${widget.moduleId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assessment_attempts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) async {
            if (!mounted) return;
            await _loadHistory();
          },
        )
        .subscribe();

    _simulationAttemptsChannel = _supabase
        .channel('module_history_sim_attempts_${user.id}_${widget.moduleId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'simulation_attempts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) async {
            if (!mounted) return;
            await _loadHistory();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_progressChannel != null) {
      _supabase.removeChannel(_progressChannel!);
    }
    if (_assessmentAttemptsChannel != null) {
      _supabase.removeChannel(_assessmentAttemptsChannel!);
    }
    if (_simulationAttemptsChannel != null) {
      _supabase.removeChannel(_simulationAttemptsChannel!);
    }
    super.dispose();
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

      if (!mounted) return;
      setState(() {
        _preAttempts = preAttempts;
        _postAttempts = postAttempts;

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
                            _SimulationStatusCard(
                              title: "Simulation",
                              done: _simDone,
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          title: Row(
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
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Total Attempts: ${attempts.length}",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Retakes: $retakes",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            if (attempts.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "No attempts yet.",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
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
      ),
    );
  }
}

class _SimulationStatusCard extends StatelessWidget {
  const _SimulationStatusCard({
    required this.title,
    required this.done,
  });

  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          title: Row(
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
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                done
                    ? "The simulation for this module is already completed."
                    : "The simulation for this module is not completed yet.",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}