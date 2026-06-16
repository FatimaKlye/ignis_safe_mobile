import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/localized_db_text.dart';

class AssessmentUiContent {
  const AssessmentUiContent({required this.texts});

  const AssessmentUiContent.empty() : texts = const <String, String>{};

  final Map<String, String> texts;

  String text(String key, {Map<String, Object?> tokens = const {}}) {
    var value = texts[key]?.trim() ?? '';
    tokens.forEach((token, replacement) {
      value = value.replaceAll('{$token}', replacement?.toString() ?? '');
    });
    return value;
  }

  List<String> orderedByPrefix(String prefix) {
    final entries = texts.entries
        .where((entry) => entry.key.startsWith(prefix) && entry.value.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value.trim()).toList(growable: false);
  }
}

class AssessmentContentRepository {
  AssessmentContentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AssessmentUiContent> loadUiContent({
    required BuildContext context,
    required int moduleNo,
    required String assessmentType,
  }) async {
    final rows = await _client
        .from('assessment_ui_texts')
        .select('text_key, text_en, text_tl')
        .eq('module_no', moduleNo)
        .eq('assessment_type', assessmentType)
        .eq('is_active', true)
        .order('display_order');

    final texts = <String, String>{};
    for (final row in rows) {
      final key = (row['text_key'] ?? '').toString().trim();
      if (key.isEmpty) continue;
      texts[key] = LocalizedDbText.pick(context, row, 'text_en', 'text_tl');
    }

    return AssessmentUiContent(texts: texts);
  }
}

class AssessmentUiScope extends InheritedWidget {
  const AssessmentUiScope({
    super.key,
    required this.content,
    required super.child,
  });

  final AssessmentUiContent content;

  static AssessmentUiContent of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AssessmentUiScope>();
    return scope?.content ?? const AssessmentUiContent.empty();
  }

  @override
  bool updateShouldNotify(AssessmentUiScope oldWidget) => content != oldWidget.content;
}

String assessmentText(
  BuildContext context,
  String key, {
  Map<String, Object?> tokens = const {},
}) {
  return AssessmentUiScope.of(context).text(key, tokens: tokens);
}
