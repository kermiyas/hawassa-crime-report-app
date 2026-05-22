// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum AuthState { unknown, guest, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.unknown;

  // Key that records an explicit guest session across restarts
  static const _guestKey = 'is_guest_session';

  AuthState get state      => _state;
  bool get isGuest         => _state == AuthState.guest;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Called once at app start to restore the correct session state.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // If the user explicitly chose "Browse Without Login",
    // honour that — do NOT auto-login even if a token exists on disk.
    final wasGuest = prefs.getBool(_guestKey) ?? false;
    if (wasGuest) {
      _state = AuthState.guest;
      notifyListeners();
      return;
    }

    // Otherwise restore from saved token
    final token = await ApiService.getToken();
    _state = (token != null && token.isNotEmpty)
        ? AuthState.authenticated
        : AuthState.guest;
    notifyListeners();
  }

  /// Call after a successful login or registration.
  Future<void> setAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear guest flag so future restarts auto-login correctly
    await prefs.setBool(_guestKey, false);
    _state = AuthState.authenticated;
    notifyListeners();
  }

  /// Call when the user taps "Browse Without Login".
  Future<void> setGuest() async {
    final prefs = await SharedPreferences.getInstance();
    // Persist the choice so hot-restart / app restart respects it
    await prefs.setBool(_guestKey, true);
    _state = AuthState.guest;
    notifyListeners();
  }

  /// Call after logout — clears token and marks guest session.
  Future<void> logout() async {
    await ApiService.removeToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
    _state = AuthState.guest;
    notifyListeners();
  }
}