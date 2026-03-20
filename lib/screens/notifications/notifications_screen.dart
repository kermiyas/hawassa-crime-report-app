// lib/screens/notifications/notifications_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class NotificationItem {
  final int id;
  final String title, message, type;
  bool isRead;
  final DateTime createdAt;
  final int? reportId;
  final int? sightingId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.reportId,
    this.sightingId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
    id:         j['id'],
    title:      j['title'] ?? 'Notification',
    message:    j['message'] ?? '',
    type:       j['type'] ?? 'general',
    isRead:     j['is_read'] == true || j['is_read'] == 1,
    createdAt:  DateTime.tryParse(j['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
    reportId:   j['report_id'],
    sightingId: j['sighting_id'],
  );
}

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onRead;
  const NotificationsScreen({super.key, this.onRead});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<NotificationItem> _all = [];
  bool _loading = true, _markingAll = false, _isOffline = false;
  late TabController _tabController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cached = await CacheService.load('notifications');
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as List;
        if (mounted) setState(() {
          _all     = data.map((j) => NotificationItem.fromJson(j)).toList();
          _loading = false;
        });
      } catch (_) {}
    }

    try {
      final res = await ApiService.getWithAuth('/notifications');
      if (res.statusCode == 200) {
        await CacheService.save('notifications', res.body);
        final data = jsonDecode(res.body) as List;
        if (mounted) setState(() {
          _all       = data.map((j) => NotificationItem.fromJson(j)).toList();
          _loading   = false;
          _isOffline = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _loading   = false;
        _isOffline = _all.isNotEmpty;
      });
    }
  }

  Future<void> _markAsRead(NotificationItem n) async {
    if (n.isRead) return;
    try {
      await ApiService.postWithAuth('/notifications/${n.id}/read', {});
      setState(() => n.isRead = true);
      widget.onRead?.call();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ApiService.postWithAuth('/notifications/mark-all-read', {});
      setState(() { for (final n in _all) n.isRead = true; });
      widget.onRead?.call();
    } catch (_) {}
    setState(() => _markingAll = false);
  }

  int get _unreadCount => _all.where((n) => !n.isRead).length;
  List<NotificationItem> get _unread => _all.where((n) => !n.isRead).toList();

  IconData _iconFor(String type) {
    switch (type) {
      case 'report_update':   return Icons.assignment_turned_in_rounded;
      case 'alert':           return Icons.warning_amber_rounded;
      case 'message':         return Icons.message_rounded;
      case 'new_alert':       return Icons.campaign_rounded;
      case 'sighting_update': return Icons.visibility_rounded;
      default:                return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type, {bool isNight = false}) {
    if (isNight) return const Color(0xFFD5C38B);
    switch (type) {
      case 'report_update':   return const Color(0xFF1976D2);
      case 'alert':           return const Color(0xFFDC2626);
      case 'message':         return const Color(0xFF059669);
      case 'new_alert':       return const Color(0xFFD97706);
      case 'sighting_update': return const Color(0xFF486D99);
      default:                return const Color(0xFF486D99);
    }
  }

  String _timeAgo(DateTime dt, AppLocalizations tr) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return tr.get('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${tr.get('ago_minutes')}';
    if (diff.inHours < 24)   return '${diff.inHours}${tr.get('ago_hours')}';
    if (diff.inDays < 7)     return '${diff.inDays}${tr.get('ago_days')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _dayLabel(DateTime dt, AppLocalizations tr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today)     return tr.get('today');
    if (day == yesterday) return tr.get('yesterday');
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _translateTitle(String title, AppLocalizations tr) {
    const map = {
      'Report Submitted':      'report_submitted',
      'Report Status Updated': 'report_status_updated',
      'Status Updated':        'report_status_updated',
      'New Message':           'new_message',
      'New Alert':             'new_alert_notif',
    };
    final key = map[title];
    return key != null ? tr.get(key) : title;
  }

  String _translateMessage(String message, AppLocalizations tr) {
    final cleaned = message.replaceAll("'", '').replaceAll('"', '')
        .replaceAll('to: ', 'to ').replaceAll(RegExp(r'\.$'), '');
    final match = RegExp(r'Your report (.+?) has been updated to (.+)', caseSensitive: false)
        .firstMatch(cleaned);
    if (match != null) {
      final category = _categoryWord(match.group(1)!.trim(), tr);
      final status   = _statusWord(match.group(2)!.trim(), tr);
      return tr.get('notif_report_updated')
          .replaceAll('{category}', category)
          .replaceAll('{status}', status);
    }
    if (message.toLowerCase().contains('submitted successfully')) return tr.get('notif_submitted');
    return message;
  }

  String _categoryWord(String raw, AppLocalizations tr) {
    final map = {
      'theft': tr.get('theft'), 'assault': tr.get('assault'), 'robbery': tr.get('robbery'),
      'vandalism': tr.get('vandalism'), 'missing person': tr.get('missing_person_cat'),
      'missing_person': tr.get('missing_person_cat'), 'suspicious activity': tr.get('suspicious_activity'),
      'suspicious_activity': tr.get('suspicious_activity'), 'fraud': tr.get('fraud'),
      'kidnapping': tr.get('kidnapping'), 'other': tr.get('other'),
    };
    return map[raw.toLowerCase()] ?? raw;
  }

  String _statusWord(String raw, AppLocalizations tr) {
    final map = {
      'submitted': tr.get('submitted'), 'under_review': tr.get('under_review'),
      'under review': tr.get('under_review'), 'active_case': tr.get('active_case'),
      'active case': tr.get('active_case'), 'resolved': tr.get('resolved'),
      'rejected': tr.get('rejected'),
    };
    return map[raw.toLowerCase()] ?? raw;
  }

  Map<String, List<NotificationItem>> _group(List<NotificationItem> items, AppLocalizations tr) {
    final Map<String, List<NotificationItem>> groups = {};
    for (final n in items) groups.putIfAbsent(_dayLabel(n.createdAt, tr), () => []).add(n);
    return groups;
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
        elevation: 0,
        title: Text(tr.get('notifications'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.appBarTextColor)),
        actions: [
          Stack(alignment: Alignment.center, children: [
            Padding(padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.notifications_rounded, size: 26, color: t.appBarFg)),
            if (_unreadCount > 0)
              Positioned(top: 10, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                  child: Text('$_unreadCount',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                )),
          ]),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 38,
            decoration: BoxDecoration(
              color: t.isNight ? Colors.white.withOpacity(0.15) : t.scaffoldBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: t.isNight ? const Color(0xFF0F2440) : Colors.white,
              unselectedLabelColor: t.isNight ? Colors.white : const Color(0xFF486D99),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(tr.get('all'))])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(tr.get('unread')),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                      child: Text('$_unreadCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ])),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.buttonColor))
          : Column(children: [
              if (_isOffline) _offlineBanner(tr),
              if (_unreadCount > 0)
                Container(
                  color: t.buttonColor.withOpacity(0.06),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Text('$_unreadCount ${tr.get('unread')}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.primaryText)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _markingAll ? null : _markAllRead,
                      child: _markingAll
                          ? SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: t.buttonColor))
                          : Text(tr.get('mark_all_read'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [_buildList(_all, tr, t), _buildList(_unread, tr, t)],
              )),
            ]),
    );
  }

  Widget _offlineBanner(AppLocalizations tr) => Container(
    color: const Color(0xFFD97706),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
      const SizedBox(width: 8),
      Text(tr.get('offline_cached_data'),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      const Spacer(),
      GestureDetector(
        onTap: _load,
        child: Text(tr.get('retry'),
            style: const TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
      ),
    ]),
  );

  Widget _buildList(List<NotificationItem> items, AppLocalizations tr, AppTheme t) {
    if (items.isEmpty) return _buildEmpty(tr, t);
    final groups = _group(items, tr);
    return RefreshIndicator(
      color: t.buttonColor, onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(entry.key,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.primaryText)),
            ),
            for (final n in entry.value) _buildCard(n, tr, t),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(NotificationItem n, AppLocalizations tr, AppTheme t) {
    final color      = _colorFor(n.type, isNight: t.isNight);
    final icon       = _iconFor(n.type);
    final isSighting = n.type == 'sighting_update' && n.sightingId != null;
    final cardBg     = n.isRead
        ? t.cardColor
        : (t.isNight ? const Color(0xFF1E3A58) : const Color(0xFFEFF6FF));

    return GestureDetector(
      onTap: () {
        _markAsRead(n);
        if (isSighting) {
          _showSightingDetail(n, tr, t);
        } else if (n.reportId != null) {
          _showReportDetail(n, t);
        } else {
          _showMessageDetail(n, tr, t);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead ? t.dividerColor : color.withOpacity(0.3),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(_translateTitle(n.title, tr),
                    style: TextStyle(fontSize: 14,
                        fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)))),
                const SizedBox(width: 6),
                Row(children: [
                  Text(_timeAgo(n.createdAt, tr),
                      style: TextStyle(fontSize: 11, color: t.secondaryText)),
                  if (!n.isRead) ...[
                    const SizedBox(width: 5),
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ],
                ]),
              ]),
              const SizedBox(height: 4),
              Text(_translateMessage(n.message, tr),
                  style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (isSighting) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.reply_rounded, size: 13,
                      color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)),
                  const SizedBox(width: 4),
                  Text('Tap to view & send additional info',
                      style: TextStyle(fontSize: 11,
                          color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                          fontWeight: FontWeight.w600)),
                ]),
              ] else if (n.reportId != null) ...[
                const SizedBox(height: 6),
                Text(tr.get('view_report'),
                    style: TextStyle(fontSize: 11,
                        color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                        fontWeight: FontWeight.w600)),
              ],
            ])),
          ]),
        ),
      ),
    );
  }

  void _showSightingDetail(NotificationItem n, AppLocalizations tr, AppTheme t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SightingDetailSheet(
        notification: n,
        theme: t,
        onReplySent: _load,
      ),
    );
  }

  void _showMessageDetail(NotificationItem n, AppLocalizations tr, AppTheme t) {
    final color = _colorFor(n.type, isNight: t.isNight);
    final icon  = _iconFor(n.type);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<LanguageProvider>(context, listen: false),
        child: Builder(builder: (ctx) {
          final tr2 = ctx.watch<LanguageProvider>().tr;
          return Container(
            margin: const EdgeInsets.only(top: 80),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_translateTitle(n.title, tr2),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.primaryText)),
                    Text(_timeAgo(n.createdAt, tr2),
                        style: TextStyle(fontSize: 12, color: t.secondaryText)),
                  ])),
                ]),
                const SizedBox(height: 16),
                Divider(color: t.dividerColor),
                const SizedBox(height: 12),
                Text(_translateMessage(n.message, tr2),
                    style: TextStyle(fontSize: 15, color: t.primaryText, height: 1.6)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(tr2.get('close'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          );
        }),
      ),
    );
  }

  void _showReportDetail(NotificationItem n, AppTheme t) {
    final langCode = Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ReportDetailSheet(
          reportId: n.reportId!, notification: n, languageCode: langCode, theme: t),
    );
  }

  Widget _buildEmpty(AppLocalizations tr, AppTheme t) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80,
          decoration: BoxDecoration(color: t.buttonColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(Icons.notifications_off_rounded, size: 40, color: t.iconColor)),
      const SizedBox(height: 16),
      Text(tr.get('no_notifications'),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: t.primaryText)),
      const SizedBox(height: 6),
      Text(tr.get('all_caught_up'), style: TextStyle(fontSize: 13, color: t.secondaryText)),
    ]));
  }
}

// ── Sighting Detail + Reply Sheet ─────────────────────────────────────────────
class _SightingDetailSheet extends StatefulWidget {
  final NotificationItem notification;
  final AppTheme theme;
  final VoidCallback onReplySent;

  const _SightingDetailSheet({
    required this.notification,
    required this.theme,
    required this.onReplySent,
  });

  @override
  State<_SightingDetailSheet> createState() => _SightingDetailSheetState();
}

class _SightingDetailSheetState extends State<_SightingDetailSheet> {
  final _replyController = TextEditingController();
  bool _sending = false;
  bool _sent    = false;

  AppTheme get t => widget.theme;

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final res = await ApiService.postWithAuth(
        '/sightings/${widget.notification.sightingId}/reply',
        {'message': text},
      );
      if (res.statusCode == 200) {
        setState(() { _sent = true; _sending = false; });
        _replyController.clear();
        widget.onReplySent();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _sending = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send. Please try again.'),
                backgroundColor: Color(0xFFDC2626)),
          );
        }
      }
    } catch (_) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.'),
              backgroundColor: Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final n           = widget.notification;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: t.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: BoxDecoration(
              color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Icon(Icons.visibility_rounded,
                  color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text('Sighting Tip Update',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white))),
              IconButton(
                icon: Icon(Icons.close,
                    color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Admin message as chat bubble ─────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_rounded, color: accentColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Police Admin',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                                  color: accentColor)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: t.isNight
                                  ? const Color(0xFF1E3A58)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: const BorderRadius.only(
                                topRight:    Radius.circular(14),
                                bottomLeft:  Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              border: Border.all(color: accentColor.withOpacity(0.2)),
                            ),
                            child: Text(n.message,
                                style: TextStyle(fontSize: 14, color: t.primaryText, height: 1.6)),
                          ),
                          const SizedBox(height: 4),
                          Text(_formatTime(n.createdAt),
                              style: TextStyle(fontSize: 11, color: t.secondaryText)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Reply section ────────────────────────────────────────
                if (_sent) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'Your information has been sent to the police admin.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF065F46),
                            fontWeight: FontWeight.w600),
                      )),
                    ]),
                  ),
                ] else ...[
                  Text('Send Additional Information',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                          color: t.primaryText)),
                  const SizedBox(height: 4),
                  Text('Provide any additional details that may help the investigation.',
                      style: TextStyle(fontSize: 12, color: t.secondaryText)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _replyController,
                      maxLines: 4,
                      maxLength: 1000,
                      style: TextStyle(fontSize: 14, color: t.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Add additional info...',
                        hintStyle: TextStyle(fontSize: 13, color: t.secondaryText),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                        counterStyle: TextStyle(color: t.secondaryText, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _sendReply,
                      icon: _sending
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _sending ? 'Sending...' : 'Send to Police Admin',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.isNight
                            ? const Color(0xFFD5C38B)
                            : const Color(0xFF486D99),
                        foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Report Detail Sheet ───────────────────────────────────────────────────────
class _ReportDetailSheet extends StatefulWidget {
  final int reportId;
  final NotificationItem notification;
  final String languageCode;
  final AppTheme theme;
  const _ReportDetailSheet({required this.reportId, required this.notification,
      required this.languageCode, required this.theme});
  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  Map<String, dynamic>? _report;
  bool _loading = true;

  AppTheme get t => widget.theme;

  @override
  void initState() { super.initState(); _loadReport(); }

  Future<void> _loadReport() async {
    try {
      final res = await ApiService.getWithAuth('/reports/${widget.reportId}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _report = data['report'] ?? data; _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'resolved':     return const Color(0xFF059669);
      case 'active_case':  return const Color(0xFF1976D2);
      case 'under_review': return const Color(0xFFD97706);
      case 'rejected':     return const Color(0xFFDC2626);
      default:             return const Color(0xFF64748B);
    }
  }

  String _statusLabel(String? s, AppLocalizations tr) {
    switch (s) {
      case 'submitted':    return tr.get('submitted');
      case 'under_review': return tr.get('under_review');
      case 'active_case':  return tr.get('active_case');
      case 'resolved':     return tr.get('resolved');
      case 'rejected':     return tr.get('rejected');
      default:             return s ?? '—';
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return d; }
  }

  String _translateCategory(String raw, AppLocalizations tr) {
    final map = {
      'theft': tr.get('theft'), 'assault': tr.get('assault'), 'robbery': tr.get('robbery'),
      'vandalism': tr.get('vandalism'), 'missing_person': tr.get('missing_person_cat'),
      'suspicious_activity': tr.get('suspicious_activity'), 'fraud': tr.get('fraud'),
      'kidnapping': tr.get('kidnapping'), 'murder': tr.get('murder'), 'arson': tr.get('arson'),
      'drug_trafficking': tr.get('drug_trafficking'), 'sexual_assault': tr.get('sexual_assault'),
      'extortion': tr.get('extortion'), 'cybercrime': tr.get('cybercrime'),
      'harassment': tr.get('harassment'), 'burglary': tr.get('burglary'),
      'homicide': tr.get('homicide'), 'other': tr.get('other'),
      'missing person': tr.get('missing_person_cat'),
      'suspicious activity': tr.get('suspicious_activity'),
      'drug trafficking': tr.get('drug_trafficking'),
      'sexual assault': tr.get('sexual_assault'),
    };
    return map[raw.toLowerCase().trim()] ?? raw;
  }

  String _translateNotifMessage(String message, AppLocalizations tr) {
    final cleaned = message.replaceAll("'", '').replaceAll('"', '')
        .replaceAll('to: ', 'to ').replaceAll(RegExp(r'\.$'), '');
    final match = RegExp(r'Your report (.+?) has been updated to (.+)', caseSensitive: false)
        .firstMatch(cleaned);
    if (match != null) {
      final catMap = {
        'theft': tr.get('theft'), 'assault': tr.get('assault'), 'robbery': tr.get('robbery'),
        'vandalism': tr.get('vandalism'), 'missing person': tr.get('missing_person_cat'),
        'missing_person': tr.get('missing_person_cat'),
        'suspicious activity': tr.get('suspicious_activity'),
        'suspicious_activity': tr.get('suspicious_activity'),
        'fraud': tr.get('fraud'), 'kidnapping': tr.get('kidnapping'), 'other': tr.get('other'),
      };
      final statusMap = {
        'submitted': tr.get('submitted'), 'under_review': tr.get('under_review'),
        'under review': tr.get('under_review'), 'active_case': tr.get('active_case'),
        'active case': tr.get('active_case'), 'resolved': tr.get('resolved'),
        'rejected': tr.get('rejected'),
      };
      final category = catMap[match.group(1)!.trim().toLowerCase()] ?? match.group(1)!.trim();
      final status   = statusMap[match.group(2)!.trim().toLowerCase()] ?? match.group(2)!.trim();
      return tr.get('notif_report_updated')
          .replaceAll('{category}', category)
          .replaceAll('{status}', status);
    }
    if (message.toLowerCase().contains('submitted successfully')) return tr.get('notif_submitted');
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations(widget.languageCode);

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: t.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Icon(Icons.description_rounded,
                color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(tr.get('report_details'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white))),
            IconButton(
              icon: Icon(Icons.close,
                  color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: t.buttonColor))
              : _report == null
                  ? Center(child: Text(tr.get('error'), style: TextStyle(color: t.primaryText)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: t.cardColor, borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(tr.translateCrimeType(_report!['title'] ?? '—'),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                                      color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(_report!['status']).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_statusLabel(_report!['status'], tr),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                        color: _statusColor(_report!['status']))),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            _row(Icons.category_outlined, tr.get('category'),
                                _translateCategory((_report!['category'] ?? '').toString(), tr)),
                            _row(Icons.calendar_today_outlined, tr.get('submitted_date'),
                                _formatDate(_report!['created_at'])),
                            if (_report!['address'] != null)
                              _row(Icons.location_on_outlined, tr.get('location'), _report!['address']),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _section(tr.get('description'), _report!['description'] ?? '—'),
                        if (_report!['admin_notes'] != null &&
                            (_report!['admin_notes'] as String).isNotEmpty)
                          _section(tr.get('officer_notes'), _report!['admin_notes'],
                              icon: Icons.shield_outlined, color: const Color(0xFF1976D2)),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: t.isNight ? const Color(0xFF1E3A58) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.2)),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              _translateNotifMessage(widget.notification.message, tr),
                              style: TextStyle(fontSize: 13, color: t.primaryText, height: 1.5),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ]),
                    ),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    final accent = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 7),
        Text('$label: ', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, color: t.primaryText, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _section(String title, String content,
      {IconData icon = Icons.description_outlined, Color color = const Color(0xFF486D99)}) {
    final headerColor = t.isNight ? const Color(0xFFD5C38B) : color;
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardColor, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: headerColor), const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: headerColor)),
        ]),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.5)),
      ]),
    );
  }
}