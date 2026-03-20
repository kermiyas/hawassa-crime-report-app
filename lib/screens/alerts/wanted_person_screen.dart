// lib/screens/alerts/wanted_person_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/alert_post.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import 'alert_detail_screen.dart';

class WantedPersonScreen extends StatefulWidget {
  const WantedPersonScreen({super.key});
  @override
  State<WantedPersonScreen> createState() => _WantedPersonScreenState();
}

class _WantedPersonScreenState extends State<WantedPersonScreen> {
  List<AlertPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/alerts?category=Wanted+Person'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _posts = data.map((j) => AlertPost.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'failed_to_load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'network_error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;
    final t  = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Row(
          children: [
            Icon(Icons.person_off, size: 20, color: t.appBarTextColor),
            const SizedBox(width: 8),
            Text(tr.get('wanted_persons'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: t.appBarTextColor)),
          ],
        ),
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(
              color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: t.iconColor),
                      const SizedBox(height: 12),
                      Text(tr.get(_error!), style: TextStyle(color: t.secondaryText)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                          foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                        ),
                        child: Text(tr.get('retry')),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 64, color: t.secondaryText),
                          const SizedBox(height: 12),
                          Text(tr.get('no_wanted_persons'),
                              style: TextStyle(color: t.secondaryText, fontSize: 15)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length,
                        itemBuilder: (_, i) => _WantedCard(
                          post: _posts[i],
                          tr: tr,
                          t: t,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlertDetailScreen(post: _posts[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }
}

class _WantedCard extends StatelessWidget {
  final AlertPost    post;
  final VoidCallback onTap;
  final dynamic      tr;
  final AppTheme     t;
  const _WantedCard({required this.post, required this.onTap, required this.tr, required this.t});

  @override
  Widget build(BuildContext context) {
    final hasPhoto  = post.mediaFiles.isNotEmpty;
    final riskColor = post.riskLevel == 'High Risk'
        ? const Color(0xFFDC2626)
        : post.riskLevel == 'Medium Risk'
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);

    final badgeBg = t.isNight
        ? const Color(0xFFD5C38B).withOpacity(0.15)
        : const Color(0xFFD6E4F0);
    final badgeFg = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.07),
              blurRadius: 8, offset: const Offset(0, 2))],
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasPhoto
                    ? Image.network(
                        post.mediaFiles.first.url,
                        width: 80, height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(t),
                      )
                    : _photoPlaceholder(t),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: badgeFg),
                          const SizedBox(width: 4),
                          Text(tr.get('wanted_badge'),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                                  color: badgeFg, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.subjectName ?? post.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                          color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)),
                    ),
                    if (post.nickname != null)
                      Text('"${post.nickname}"',
                          style: TextStyle(fontSize: 12, color: t.secondaryText,
                              fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    if (post.committedCrime != null)
                      Text('${tr.get('charge')}: ${tr.translateCrimeType(post.committedCrime!)}',
                          style: TextStyle(fontSize: 12, color: t.primaryText)),
                    if (post.height != null || post.weight != null)
                      Text(
                        '${post.height != null ? post.height! + "cm" : ""}${post.height != null && post.weight != null ? " / " : ""}${post.weight != null ? post.weight! + "kg" : ""}',
                        style: TextStyle(fontSize: 12, color: t.primaryText),
                      ),
                    const SizedBox(height: 8),
                    if (post.riskLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: riskColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          tr.translateRiskLevel(post.riskLevel!),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: riskColor),
                        ),
                      ),
                    if (post.caseStatus != null && post.caseStatus != 'active') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(tr.get('found_resolved'),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Color(0xFF065F46))),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.iconColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(AppTheme t) => Container(
    width: 80, height: 90,
    decoration: BoxDecoration(
      color: t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Icon(Icons.person, size: 36,
        color: t.isNight ? const Color(0xFFD5C38B).withOpacity(0.4) : const Color(0xFF94A3B8)),
  );
}