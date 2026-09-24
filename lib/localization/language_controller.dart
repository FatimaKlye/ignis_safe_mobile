import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageController extends ChangeNotifier {
  static const String _languageCodeKey = 'app_language_code';

  Locale _locale = const Locale('en');
  bool _ready = false;
  bool _selectedByUser = false;

  Locale get locale => _locale;
  bool get isReady => _ready;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isTagalog => _locale.languageCode == 'tl';

  /// Display name of the current language, e.g. "English" or "Filipino".
  String get currentLanguageName => languageName(_locale.languageCode);

  /// Language names are shown in their own language so users can always
  /// recognize them, whichever language the app is currently in.
  static String languageName(String code) {
    return code == 'tl' ? 'Filipino' : 'English';
  }

  LanguageController() {
    _load();
  }

  bool _isValidCode(String? code) {
    return code == 'en' || code == 'tl';
  }

  Future<void> _load() async {
    String code = 'en';
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageCodeKey);

      if (_isValidCode(savedCode)) {
        // The choice saved on this device (from Login or Profile) wins, so it
        // survives restarts even if the last profile sync failed offline.
        code = savedCode!;
      } else {
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
      }
    } catch (_) {
      // Fall back to the code resolved so far.
    } finally {
      // Never override a language the user picked while this was loading.
      if (!_selectedByUser) {
        _locale = Locale(code);
      }
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!_isValidCode(code)) return;

    _selectedByUser = true;
    final changed = _locale.languageCode != code;

    _locale = Locale(code);

    // Apply immediately; persistence below must not delay the UI update.
    if (changed) {
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, code);
    } catch (_) {
      // Keep the in-memory choice even if local storage is unavailable.
    }

    await _saveLanguageToProfile(code);
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
