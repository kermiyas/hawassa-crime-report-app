// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _prefix    = 'cache_';
  static const _tsPrefix  = 'cache_ts_';

  // How long cache is considered fresh (30 minutes)
  static const _ttlMs = 30 * 60 * 1000;

  // Save JSON string to cache with timestamp
  static Future<void> save(String key, String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonData);
    await prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  // Load cached JSON string (returns null if not found)
  static Future<String?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$key');
  }

  // Check if cache exists and is still fresh
  static Future<bool> isFresh(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ts    = prefs.getInt('$_tsPrefix$key');
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < _ttlMs;
  }

  // Check if any cache exists (even stale) — for offline fallback
  static Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$key');
  }

  // Clear a specific cache entry
  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
    await prefs.remove('$_tsPrefix$key');
  }

  // Clear all cache entries
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) { await prefs.remove(k); }
  }

  // Get cache age in minutes (returns null if no cache)
  static Future<int?> ageMinutes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ts    = prefs.getInt('$_tsPrefix$key');
    if (ts == null) return null;
    return ((DateTime.now().millisecondsSinceEpoch - ts) / 60000).round();
  }
}