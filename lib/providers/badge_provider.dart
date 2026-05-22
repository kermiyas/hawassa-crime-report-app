// lib/providers/badge_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class BadgeProvider extends ChangeNotifier {
  int _newWanted       = 0;
  int _newMissingPerson = 0;
  int _newMissingItem  = 0;
  int _newNews         = 0;

int _seenWantedId       = 0;
int _seenMissingPersonId = 0;
int _seenMissingItemId  = 0;

int get seenWantedId        => _seenWantedId;
int get seenMissingPersonId => _seenMissingPersonId;
int get seenMissingItemId   => _seenMissingItemId;
  int get newWanted        => _newWanted;
  int get newMissingPerson => _newMissingPerson;
  int get newMissingItem   => _newMissingItem;
  int get newNews          => _newNews;

  bool get hasAnyAlertBadge =>
      _newWanted > 0 || _newMissingPerson > 0 || _newMissingItem > 0;

  // ── Fetch & compute badges ───────────────────────────────────────────────
  Future<void> refresh() async {
    await Future.wait([
      _checkAlerts('Wanted+Person',  'badge_wanted_id',        (v) => _newWanted = v),
      _checkAlerts('Missing+Person', 'badge_missing_person_id', (v) => _newMissingPerson = v),
      _checkAlerts('Missing+Item',   'badge_missing_item_id',   (v) => _newMissingItem = v),
      _checkNews(),
    ]);
    notifyListeners();
  }

  Future<void> _checkAlerts(
    String category,
    String prefKey,
    void Function(int) setter,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/alerts?category=$category'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final list = jsonDecode(res.body)['data'] as List;
      if (list.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final seenId = prefs.getInt(prefKey) ?? 0;

      if (prefKey == 'badge_wanted_id')          _seenWantedId = seenId;
      if (prefKey == 'badge_missing_person_id')  _seenMissingPersonId = seenId;
      if (prefKey == 'badge_missing_item_id')    _seenMissingItemId = seenId;

      setter(list.where((e) => (e['id'] as int) > seenId).length);
    } catch (_) {}
  }

  Future<void> _checkNews() async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/news'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final list = jsonDecode(res.body)['posts'] as List;
      if (list.isEmpty) return;

      final prefs  = await SharedPreferences.getInstance();
      final seenId = prefs.getInt('badge_news_id') ?? 0;

      _newNews = list.where((e) => (e['id'] as int) > seenId).length;
    } catch (_) {}
  }

  // ── Mark-as-seen helpers (call when user opens that section) ─────────────
  Future<void> markWantedSeen() async {
  await _markSeen('Wanted+Person', 'badge_wanted_id');
  _newWanted = 0;
  notifyListeners();
}

  Future<void> markMissingPersonSeen() async {
    await _markSeen('Missing+Person', 'badge_missing_person_id');
    _newMissingPerson = 0;
    notifyListeners();
  }

  Future<void> markMissingItemSeen() async {
    await _markSeen('Missing+Item', 'badge_missing_item_id');
    _newMissingItem = 0;
    notifyListeners();
  }

  Future<void> markNewsSeen() async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/news'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['posts'] as List;
        if (list.isNotEmpty) {
          final maxId = list
              .map((e) => e['id'] as int)
              .reduce((a, b) => a > b ? a : b);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('badge_news_id', maxId);
        }
      }
    } catch (_) {}
    _newNews = 0;
    notifyListeners();
  }

Future<void> markSingleAlertSeen(String prefKey, int id) async {
  final prefs = await SharedPreferences.getInstance();
  final seenId = prefs.getInt(prefKey) ?? 0;
  if (id > seenId) {
    await prefs.setInt(prefKey, id);
  }
}
  Future<void> _markSeen(String category, String prefKey) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/alerts?category=$category'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List;
        if (list.isNotEmpty) {
          final maxId = list
              .map((e) => e['id'] as int)
              .reduce((a, b) => a > b ? a : b);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(prefKey, maxId);
        }
      }
    } catch (_) {}
  }
}