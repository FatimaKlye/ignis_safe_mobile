import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageController extends ChangeNotifier {
  static const String _languageCodeKey = 'app_language_code';

  Locale _locale = const Locale('en');
  bool _ready = false;

  Locale get locale => _locale;
  bool get isReady => _ready;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isTagalog => _locale.languageCode == 'tl';

  LanguageController() {
    _load();
  }

  bool _isValidCode(String? code) {
    return code == 'en' || code == 'tl';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String code = prefs.getString(_languageCodeKey) ?? 'en';

      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('app_language_code')
            .eq('id', user.id)
            .maybeSingle();

        final dbCode = row?['app_language_code']?.toString();

        if (_isValidCode(dbCode)) {
          code = dbCode!;
          await prefs.setString(_languageCodeKey, code);
        }
      }

      if (_isValidCode(code)) {
        _locale = Locale(code);
      }
    } catch (_) {
      _locale = const Locale('en');
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!_isValidCode(code)) return;

    final changed = _locale.languageCode != code;

    _locale = Locale(code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);

    await _saveLanguageToProfile(code);

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _saveLanguageToProfile(String code) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email?.trim().toLowerCase(),
        'app_language_code': code,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Do not block the app if language sync fails.
    }
  }
}

String t(BuildContext context, String en, String tl) {
  try {
    return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
  } catch (_) {
    return en;
  }
}
