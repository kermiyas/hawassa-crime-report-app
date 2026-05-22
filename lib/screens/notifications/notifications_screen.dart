// lib/screens/notifications/notifications_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
const _kNavy      = Color(0xFF0D1B2A);
const _kNavyMid   = Color(0xFF1A3A5C);
const _kGold      = Color(0xFFC9A84C);
const _kGoldLight = Color(0xFFE8D5A3);
const _kBlue      = Color(0xFF1565C0);
const _kRed       = Color(0xFFC62828);
const _kGreen     = Color(0xFF2E7D32);
const _kAmber     = Color(0xFFE65100);

class NotificationItem {
  final int id;
  final String title, message, type;
  bool isRead;
  final DateTime createdAt;
  final int? reportId;
  final int? sightingId;
  final String? senderName; // ← added
  final String? senderRole; // ← added

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.reportId,
    this.sightingId,
    this.senderName, // ← added
    this.senderRole, // ← added
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
        senderName: j['sender_name'], // ← added
        senderRole: j['sender_role'], // ← added
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
      HapticFeedback.lightImpact();
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
    if (isNight) return _kGold;
    switch (type) {
      case 'report_update':   return _kBlue;
      case 'alert':           return _kRed;
      case 'message':         return _kGreen;
      case 'new_alert':       return _kAmber;
      case 'sighting_update': return _kNavyMid;
      default:                return _kNavyMid;
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
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day       = DateTime(dt.year, dt.month, dt.day);
    if (day == today)     return tr.get('today');
    if (day == yesterday) return tr.get('yesterday');
    final diff = today.difference(day).inDays;
    if (diff < 7) return '$diff days ago';
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
      'missing_person': tr.get('missing_person_cat'),
      'suspicious activity': tr.get('suspicious_activity'),
      'suspicious_activity': tr.get('suspicious_activity'),
      'fraud': tr.get('fraud'), 'kidnapping': tr.get('kidnapping'), 'other': tr.get('other'),
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
    final tr     = context.watch<LanguageProvider>().tr;
    final t      = context.watch<ThemeProvider>().theme;
    final accent = t.isNight ? _kGold : _kNavyMid;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: Column(children: [
        _buildHeader(tr, t, accent),
        if (_isOffline) _offlineBanner(tr),
        if (_unreadCount > 0 && !_loading) _markAllBanner(tr, t, accent),
        Expanded(
          child: _loading
              ? _buildLoading(t)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_all, tr, t),
                    _buildList(_unread, tr, t),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _buildHeader(AppLocalizations tr, AppTheme t, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.isNight
              ? [const Color(0xFF1A2F4A), const Color(0xFF0D1B2A)]
              : [_kNavy, _kNavyMid],
        ),
        boxShadow: [
          BoxShadow(color: _kNavy.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr.get('notifications'),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 0.3)),
                  if (_unreadCount > 0)
                    Text('$_unreadCount unread',
                        style: TextStyle(fontSize: 12, color: _kGold.withOpacity(0.9),
                            fontWeight: FontWeight.w600)),
                ]),
              ),
              Stack(alignment: Alignment.topRight, children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$_unreadCount',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: t.isNight ? [_kGold, _kGoldLight] : [_kGold, const Color(0xFFE8C96A)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: _kGold.withOpacity(0.4), blurRadius: 8)],
                ),
                labelColor: _kNavy,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.list_rounded, size: 15),
                    const SizedBox(width: 5),
                    Text(tr.get('all')),
                  ])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.mark_email_unread_rounded, size: 15),
                    const SizedBox(width: 5),
                    Text(tr.get('unread')),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: _kRed, borderRadius: BorderRadius.circular(8)),
                        child: Text('$_unreadCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ],
                  ])),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _markAllBanner(AppLocalizations tr, AppTheme t, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: accent.withOpacity(0.1))),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.mark_email_read_rounded, size: 15, color: accent),
        ),
        const SizedBox(width: 10),
        Text('$_unreadCount ${tr.get('unread')} messages',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.primaryText)),
        const Spacer(),
        GestureDetector(
          onTap: _markingAll ? null : _markAllRead,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
            child: _markingAll
                ? SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: t.isNight ? _kNavy : Colors.white))
                : Text(tr.get('mark_all_read'),
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: t.isNight ? _kNavy : Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _offlineBanner(AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFBF360C)]),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 15),
        const SizedBox(width: 8),
        Expanded(child: Text(tr.get('offline_cached_data'),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(tr.get('retry'),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _buildLoading(AppTheme t) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(
            color: t.isNight ? _kGold : _kNavyMid,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 16),
        Text('Loading notifications...',
            style: TextStyle(fontSize: 13, color: t.secondaryText, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildList(List<NotificationItem> items, AppLocalizations tr, AppTheme t) {
    if (items.isEmpty) return _buildEmpty(tr, t);
    final groups = _group(items, tr);
    return RefreshIndicator(
      color: t.isNight ? _kGold : _kNavyMid,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30, top: 4),
        children: [
          for (final entry in groups.entries) ...[
            _buildDayDivider(entry.key, t),
            for (final n in entry.value) _buildCard(n, tr, t),
          ],
        ],
      ),
    );
  }

  Widget _buildDayDivider(String label, AppTheme t) {
    final accent = t.isNight ? _kGold : _kNavyMid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent,
                  letterSpacing: 0.3)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: t.dividerColor, height: 1)),
      ]),
    );
  }

  Widget _buildCard(NotificationItem n, AppLocalizations tr, AppTheme t) {
    final color      = _colorFor(n.type, isNight: t.isNight);
    final icon       = _iconFor(n.type);
    final isSighting = n.type == 'sighting_update' && n.sightingId != null;

    // ── Build sender label string ─────────────────────────────────────
    final hasSender = n.senderName != null || n.senderRole != null;
    final senderLabel = [
      if (n.senderName != null) n.senderName!,
      if (n.senderRole != null) n.senderRole!,
    ].join(' / ');

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: n.isRead
              ? t.cardColor
              : (t.isNight ? const Color(0xFF1A2F46) : const Color(0xFFF0F6FF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? t.dividerColor : color.withOpacity(0.35),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: n.isRead
                  ? Colors.black.withOpacity(0.03)
                  : color.withOpacity(0.08),
              blurRadius: n.isRead ? 4 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Icon circle ───────────────────────────────────────────
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Title row ─────────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(
                    _translateTitle(n.title, tr),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                      color: t.isNight ? _kGoldLight : _kNavy,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Row(children: [
                  Text(_timeAgo(n.createdAt, tr),
                      style: TextStyle(fontSize: 10, color: t.secondaryText)),
                  if (!n.isRead) ...[
                    const SizedBox(width: 5),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                  ],
                ]),
              ]),
              const SizedBox(height: 5),
              // ── Message ───────────────────────────────────────────
              Text(
                _translateMessage(n.message, tr),
                style: TextStyle(fontSize: 12.5, color: t.secondaryText, height: 1.45),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // ── Sender label ──────────────────────────────────────
              if (hasSender) ...[
                const SizedBox(height: 5),
                Row(children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 11,
                    color: t.secondaryText.withOpacity(0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    senderLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.secondaryText.withOpacity(0.75),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]),
              ],
              // ── View button ───────────────────────────────────────
              if (isSighting || n.reportId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isSighting ? Icons.reply_rounded : Icons.open_in_new_rounded,
                      size: 11, color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSighting ? 'View & reply' : tr.get('view_report'),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                    ),
                  ]),
                ),
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
      builder: (_) => _SightingDetailSheet(notification: n, theme: t, onReplySent: _load),
    );
  }

  void _showMessageDetail(NotificationItem n, AppLocalizations tr, AppTheme t) {
    final color = _colorFor(n.type, isNight: t.isNight);
    final icon  = _iconFor(n.type);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<LanguageProvider>(context, listen: false),
        child: Builder(builder: (ctx) {
          final tr2 = ctx.watch<LanguageProvider>().tr;
          return Container(
            margin: const EdgeInsets.only(top: 80),
            decoration: BoxDecoration(
              color: t.scaffoldBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: t.dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_translateTitle(n.title, tr2),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                        color: t.primaryText)),
              ),
              const SizedBox(height: 4),
              Text(_timeAgo(n.createdAt, tr2),
                  style: TextStyle(fontSize: 12, color: t.secondaryText)),
              // ── Sender in modal ──────────────────────────────────
              if (n.senderName != null || n.senderRole != null) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person_outline_rounded, size: 12,
                      color: t.secondaryText.withOpacity(0.65)),
                  const SizedBox(width: 4),
                  Text(
                    [
                      if (n.senderName != null) n.senderName!,
                      if (n.senderRole != null) n.senderRole!,
                    ].join(' / '),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.secondaryText.withOpacity(0.75),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 20),
              Divider(color: t.dividerColor, indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Text(_translateMessage(n.message, tr2),
                        style: TextStyle(fontSize: 14, color: t.primaryText, height: 1.6)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.isNight ? _kGold : _kNavyMid,
                        foregroundColor: t.isNight ? _kNavy : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(tr2.get('close'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }

  void _showReportDetail(NotificationItem n, AppTheme t) {
    final langCode = Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReportDetailSheet(
          reportId: n.reportId!, notification: n, languageCode: langCode, theme: t),
    );
  }

  Widget _buildEmpty(AppLocalizations tr, AppTheme t) {
    final accent = t.isNight ? _kGold : _kNavyMid;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.1), accent.withOpacity(0.03)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.2), width: 1.5),
          ),
          child: Icon(Icons.notifications_none_rounded, size: 42, color: accent.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
        Text(tr.get('no_notifications'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: t.primaryText)),
        const SizedBox(height: 8),
        Text(tr.get('all_caught_up'),
            style: TextStyle(fontSize: 13, color: t.secondaryText)),
      ]),
    );
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
  bool _sending = false, _sent = false;
  AppTheme get t => widget.theme;

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send. Please try again.'),
              backgroundColor: _kRed),
        );
      }
    } catch (_) {
      setState(() => _sending = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.'),
            backgroundColor: _kRed),
      );
    }
  }

  @override
  void dispose() { _replyController.dispose(); super.dispose(); }

  String _formatTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final n      = widget.notification;
    final accent = t.isNight ? _kGold : _kNavyMid;

    // ── Sender label for sighting sheet ──────────────────────────────
    final senderLabel = [
      if (n.senderName != null) n.senderName!,
      if (n.senderRole != null) n.senderRole!,
    ].join(' / ');
    final displaySender = senderLabel.isNotEmpty ? senderLabel : 'Police Admin';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: t.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: t.isNight
                    ? [const Color(0xFF2A4A6A), const Color(0xFF1A3A5C)]
                    : [_kNavy, _kNavyMid],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sighting Tip Update',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Admin bubble — uses real sender name
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.shield_rounded, color: accent, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // ── Show real sender name/role ─────────────────
                    Text(displaySender,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.isNight ? const Color(0xFF1A2F46) : const Color(0xFFF0F6FF),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: accent.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: accent.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Text(n.message,
                          style: TextStyle(fontSize: 14, color: t.primaryText, height: 1.6)),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatTime(n.createdAt),
                        style: TextStyle(fontSize: 10, color: t.secondaryText)),
                  ])),
                ]),

                const SizedBox(height: 24),

                if (_sent) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Expanded(child: Text(
                        'Your information has been sent to the police admin.',
                        style: TextStyle(fontSize: 13, color: Colors.white,
                            fontWeight: FontWeight.w700),
                      )),
                    ]),
                  ),
                ] else ...[
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.reply_rounded, size: 15, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Text('Send Additional Information',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                            color: t.primaryText)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Provide any additional details that may help the investigation.',
                      style: TextStyle(fontSize: 12, color: t.secondaryText)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
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
                        contentPadding: const EdgeInsets.all(16),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _sending ? 'Sending...' : 'Send to Police Admin',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.isNight ? _kGold : _kNavyMid,
                        foregroundColor: t.isNight ? _kNavy : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      case 'resolved':     return _kGreen;
      case 'active_case':  return _kBlue;
      case 'under_review': return _kAmber;
      case 'rejected':     return _kRed;
      default:             return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'resolved':     return Icons.check_circle_rounded;
      case 'active_case':  return Icons.local_police_rounded;
      case 'under_review': return Icons.hourglass_top_rounded;
      case 'rejected':     return Icons.cancel_rounded;
      default:             return Icons.pending_rounded;
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
    final tr     = AppLocalizations(widget.languageCode);
    final accent = t.isNight ? _kGold : _kNavyMid;
    final n      = widget.notification;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: t.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: t.isNight
                  ? [const Color(0xFF2A4A6A), const Color(0xFF1A3A5C)]
                  : [_kNavy, _kNavyMid],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(tr.get('report_details'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: Colors.white))),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white60),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),

        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(
                  color: t.isNight ? _kGold : _kNavyMid, strokeWidth: 2.5))
              : _report == null
                  ? Center(child: Text(tr.get('error'),
                      style: TextStyle(color: t.primaryText)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        // Status card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _statusColor(_report!['status']).withOpacity(0.15),
                                _statusColor(_report!['status']).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _statusColor(_report!['status']).withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: _statusColor(_report!['status']).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_statusIcon(_report!['status']),
                                  color: _statusColor(_report!['status']), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_statusLabel(_report!['status'], tr),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                                      color: _statusColor(_report!['status']))),
                              Text('Case Status',
                                  style: TextStyle(fontSize: 11, color: t.secondaryText)),
                            ])),
                          ]),
                        ),
                        const SizedBox(height: 12),

                        // Info card
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: t.cardColor, borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: t.dividerColor),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                                blurRadius: 8)],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(tr.translateCrimeType(_report!['title'] ?? '—'),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                                    color: t.isNight ? _kGoldLight : _kNavy)),
                            const SizedBox(height: 12),
                            _infoRow(Icons.category_outlined, tr.get('category'),
                                _translateCategory((_report!['category'] ?? '').toString(), tr),
                                accent),
                            _infoRow(Icons.calendar_today_outlined, tr.get('submitted_date'),
                                _formatDate(_report!['created_at']), accent),
                            if (_report!['address'] != null)
                              _infoRow(Icons.location_on_outlined, tr.get('location'),
                                  _report!['address'], accent),
                          ]),
                        ),
                        const SizedBox(height: 12),

                        _section(tr.get('description'), _report!['description'] ?? '—', t, accent),

                        if (_report!['admin_notes'] != null &&
                            (_report!['admin_notes'] as String).isNotEmpty)
                          _section(tr.get('officer_notes'), _report!['admin_notes'], t,
                              _kBlue, icon: Icons.shield_outlined),

                        // Notification message + sender
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBlue.withOpacity(0.2)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.info_outline_rounded, color: _kBlue, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                _translateNotifMessage(n.message, tr),
                                style: TextStyle(fontSize: 12.5, color: t.primaryText, height: 1.5),
                              )),
                            ]),
                            // ── Sender inside report detail modal ──
                            if (n.senderName != null || n.senderRole != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.person_outline_rounded, size: 12,
                                    color: t.secondaryText.withOpacity(0.65)),
                                const SizedBox(width: 4),
                                Text(
                                  [
                                    if (n.senderName != null) n.senderName!,
                                    if (n.senderRole != null) n.senderRole!,
                                  ].join(' / '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: t.secondaryText.withOpacity(0.75),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ]),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ]),
                    ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 7),
        Text('$label: ', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w700)),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, color: widget.theme.primaryText,
                fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _section(String title, String content, AppTheme t, Color accent,
      {IconData icon = Icons.description_outlined}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: accent), const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
        ]),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.5)),
      ]),
    );
  }
}