import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languageCodeKey);
    if (code != null && (code == 'tl' || code == 'en')) {
      _locale = Locale(code);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'tl') return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);
  }
}
