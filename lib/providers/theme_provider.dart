// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final bool isNight;
  const AppTheme({required this.isNight});

  // ── App Bar ───────────────────────────────────────────────────────────────
  Color get appBarColor      => isNight ? const Color(0xFF0F2440) : const Color(0xFFEAF2FB);
  Color get appBarTextColor  => isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
  Color get appBarFg         => isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  Color get scaffoldBg       => isNight ? const Color(0xFF112D4E) : const Color(0xFFD6E4F0);
  Color get scaffoldBg2      => isNight ? const Color(0xFF112D4E) : const Color(0xFFEAF2FB);

  // ── Cards ─────────────────────────────────────────────────────────────────
  Color get cardColor        => isNight ? const Color(0xFF22517F) : Colors.white;

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get primaryText      => isNight ? Colors.white.withOpacity(0.75) : const Color(0xFF486D99);
  Color get secondaryText    => isNight ? Colors.white.withOpacity(0.75) : const Color(0xFF486D99);

  // ── Icons ─────────────────────────────────────────────────────────────────
  Color get iconColor        => isNight ? const Color(0xFFD5C38B) : const Color(0xFF275F8C);

  // ── Navigation (top filter tabs - unchanged) ──────────────────────────────
  Color get navSelectedColor   => isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
  Color get navUnselectedColor => isNight ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.5);
  Color get navUnselectedBg    => isNight ? const Color(0xFF133D6A) : const Color(0xFFD6E4F0);

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  // Day:   bar bg = #486D99 (blue), selected = white, unselected = white 50%
  // Night: bar bg = #D5C38B (gold), selected = #1A3A5C (navy), unselected = #1A3A5C 50%
  Color get bottomNavBg => isNight ? const Color(0xFFD5C38B).withOpacity(0.75) : const Color(0xFF486D99);
  Color get bottomNavSelected      => isNight ? const Color(0xFF1A3A5C) : Colors.white;
  Color get bottomNavUnselected    => isNight ? const Color(0xFF1A3A5C).withOpacity(0.5) : Colors.white.withOpacity(0.5);

  // ── Buttons ───────────────────────────────────────────────────────────────
  Color get buttonColor      => isNight ? const Color(0xFF1E4268) : const Color(0xFF486D99);
  Color get buttonTextColor  => Colors.white;

  // ── Selection ─────────────────────────────────────────────────────────────
  Color get selectionColor   => isNight ? const Color(0xFF1465A6) : const Color(0xFF486D99);

  // ── Divider ───────────────────────────────────────────────────────────────
  Color get dividerColor     => isNight ? Colors.white12 : const Color(0xFFE2E8F0);

  // ── Input fields ─────────────────────────────────────────────────────────
  Color get inputBg          => isNight ? const Color(0xFF1F2F3F) : Colors.white;
}

class ThemeProvider extends ChangeNotifier {
  bool _isNight = false;

  bool get isNight => _isNight;
  AppTheme get theme => AppTheme(isNight: _isNight);

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isNight = prefs.getBool('night_mode') ?? false;
  }

  Future<void> toggle() async {
    _isNight = !_isNight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('night_mode', _isNight);
    notifyListeners();
  }
}