// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';

  String _languageCode = 'en';

  String get languageCode => _languageCode;
  bool   get isAmharic   => _languageCode == 'am';
  AppLocalizations get tr => AppLocalizations(_languageCode);

  // Call this once at app start
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_key) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifyListeners();
  }

  // Convenience: toggle between en and am
  Future<void> toggle() async {
    await setLanguage(isAmharic ? 'en' : 'am');
  }
}