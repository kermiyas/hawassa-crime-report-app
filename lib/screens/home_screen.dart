// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/badge_provider.dart';          // ← new
import '../widgets/auth_gate.dart';
import 'notifications/notifications_screen.dart';
import 'reports/submit_report_screen.dart';
import 'account_screen.dart';
import 'news/news_feed_screen.dart';
import 'reports/my_reports_screen.dart';
import 'alerts/wanted_person_screen.dart';
import 'alerts/missing_person_screen.dart';
import 'alerts/missing_item_screen.dart';
import 'stations/police_station_detail_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  String _userName    = '';
  int    _unreadCount = 0;
  int    _selectedIndex = 0;

  Timer? _badgeTimer;
  Timer? _notifTimer;

  AnimationController? _heroController;
  Animation<double>?   _heroFade;
  Animation<Offset>?   _heroSlide;

  final Color _navyDark = const Color(0xFF0D1B2A);
  final Color _navy     = const Color(0xFF1A3A5C);
  final Color _gold     = const Color(0xFFC9A84C);

  static const List<Map<String, dynamic>> _stations = [
    {
      'name':      'Hawassa City Police Department',
      'address':   '2FVG+RG5, Unnamed Road, Hawassa, Ethiopia',
      'district':  'City Center',
      'phone':     '+251 46 220 0991',
      'latitude':  7.0621,
      'longitude': 38.4766,
      'type':      'headquarters',
    },
    {
      'name':      'Misrak Subcity Police Station',
      'address':   '3F2R+297, Hawassa, Ethiopia',
      'district':  'Misrak Subcity',
      'phone':     null,
      'latitude':  7.0758,
      'longitude': 38.4921,
      'type':      'subcity',
    },
    {
      'name':      'Police Station',
      'address':   '3F2C+J54, Hawassa, Ethiopia',
      'district':  'Hawassa',
      'phone':     null,
      'latitude':  7.0712,
      'longitude': 38.4834,
      'type':      'local',
    },
    {
      'name':      'Adisu Menariya Police Station',
      'address':   'Adisu Menariya Area, Hawassa, Ethiopia',
      'district':  'Adisu Menariya',
      'phone':     null,
      'latitude':  7.0550,
      'longitude': 38.4700,
      'type':      'local',
    },
    {
      'name':      'Hayek Dar Subcity Police Office',
      'address':   'Hayek Dar Subcity, Hawassa, Ethiopia',
      'district':  'Hayek Dar',
      'phone':     null,
      'latitude':  7.0480,
      'longitude': 38.4650,
      'type':      'subcity',
    },
    {
      'name':      'Tabor Subcity Police Office',
      'address':   'Tabor Subcity, Hawassa, Ethiopia',
      'district':  'Tabor',
      'phone':     null,
      'latitude':  7.0830,
      'longitude': 38.4600,
      'type':      'subcity',
    },
  ];

  @override
  void initState() {
    super.initState();
  _selectedIndex = widget.initialIndex;
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _heroController = ctrl;
    _heroFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeIn));
    _heroSlide = Tween<Offset>(
        begin: const Offset(0, -0.15), end: Offset.zero).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
    ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth   = context.read<AuthProvider>();
      final badges = context.read<BadgeProvider>();

      // Always refresh alert + news badges (guests can see alerts & feed)
      badges.refresh();
      _badgeTimer = Timer.periodic(
          const Duration(seconds: 30), (_) => badges.refresh());

      if (auth.isAuthenticated) {
        _loadProfile();
        _loadUnreadCount();
        _notifTimer = Timer.periodic(
            const Duration(seconds: 30), (_) => _loadUnreadCount());
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _notifTimer?.cancel();
    _heroController?.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiService.getWithAuth('/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'] ?? data;
        if (mounted) setState(() => _userName = user['full_name'] ?? '');
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiService.getWithAuth('/notifications/unread-count');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _unreadCount = data['unread_count'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    if (!AuthGate.require(context, featureName: 'view notifications')) return;
    await Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => NotificationsScreen(onRead: _loadUnreadCount)));
    _loadUnreadCount();
  }

  void _onNavTap(int index, {required bool isGuest}) {
    // When tapping the Feed tab, mark news as seen
    if (!isGuest && index == 3) {
      context.read<BadgeProvider>().markNewsSeen();
    }
    if (isGuest && index == 1) {
      context.read<BadgeProvider>().markNewsSeen();
    }
    setState(() => _selectedIndex = index);
  }

 String _greeting(AppLocalizations tr) {
  final h = DateTime.now().hour;
  if (h < 12) return tr.get('good_morning');
  if (h < 17) return tr.get('good_afternoon');
  return tr.get('good_evening');
}

  String _firstName(AppLocalizations tr) {
  if (_userName.isEmpty) return tr.get('citizen');
  return _userName.split(' ').first;
}

  // ── Small red badge dot/count widget ────────────────────────────────────
  Widget _buildBadge(int count, {double top = 0, double right = 0}) {
    if (count <= 0) return const SizedBox.shrink();
    return Positioned(
      top:   top,
      right: right,
      child: Container(
        height: 18,
        constraints: const BoxConstraints(minWidth: 18),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1),
        ),
      ),
    );
  }

  // ── Nav-item badge dot (smaller, for bottom nav) ─────────────────────────
  Widget _navIcon(IconData icon, {bool active = false, int badge = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        if (badge > 0)
          Positioned(
            top: -4, right: -6,
            child: Container(
              height: 15,
              constraints: const BoxConstraints(minWidth: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF0F2440), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1),
              ),
            ),
          ),
      ],
    );
  }

  // ── Home body ────────────────────────────────────────────────────────────
  Widget _buildHomeBody(AppTheme t, bool isGuest) {
     final tr = context.read<LanguageProvider>().tr;
    final fade   = _heroFade  ?? const AlwaysStoppedAnimation(1.0);
    final slide  = _heroSlide ?? const AlwaysStoppedAnimation(Offset.zero);
    final badges = context.watch<BadgeProvider>();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (isGuest) _buildGuestBanner(t, tr),

          // ── Hero header ────────────────────────────────────────────
          SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fade,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: t.isNight
                        ? [const Color(0xFF0A1628), const Color(0xFF112D4E)]
                        : [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C),
                           const Color(0xFF1E4D7B)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -25, right: -25,
                      child: Container(width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1.5)))),
                    Positioned(bottom: -15, left: -15,
                      child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC9A84C).withOpacity(0.1),
                            width: 1)))),
                    Positioned(top: 22, right: 70,
                      child: Container(width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.5),
                          shape: BoxShape.circle))),
                    Positioned(top: 50, left: 40,
                      child: Container(width: 3, height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle))),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greeting(tr),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFC9A84C),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5)),
                                  const SizedBox(height: 3),
                                  Text(isGuest ? tr.get('guest') : _firstName(tr),
                                      style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3)),
                                ],
                              ),
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: const Color(0xFFC9A84C)
                                        .withOpacity(0.45),
                                    width: 2)),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: Image.asset('assets/logo.png',
                                        fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1)),
                            child: Row(children: [
                              const Icon(Icons.shield_outlined,
                                  size: 14, color: Color(0xFFC9A84C)),
                              const SizedBox(width: 8),
                              Text(tr.get('app_subtitle'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.75),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3)),
                            ]),
                          ),

                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: () {
                              if (isGuest) {
                                AuthGate.require(context,
                                    featureName: 'submit a report');
                              } else {
                                setState(() => _selectedIndex = 0);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC9A84C),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC9A84C)
                                        .withOpacity(0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7)),
                                ],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1B2A)
                                        .withOpacity(0.18),
                                    shape: BoxShape.circle),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    size: 20,
                                    color: Color(0xFF0D1B2A)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr.get('report_incident'),
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0D1B2A))),
                                    Text(
                                     isGuest
    ? tr.get('sign_in_to_report')
    : tr.get('submit_crime_report'),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xFF0D1B2A)
                                              .withOpacity(0.6))),
                                  ],
                                )),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: Color(0xFF0D1B2A)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Container(
            color: t.isNight
                ? const Color(0xFF112D4E)
                : const Color(0xFFF0F4F8),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Public Alerts ──────────────────────────────────
              _buildSectionTitle(tr.get('public_alerts'), Icons.warning_amber_rounded, t),
               
                Row(children: [
                  _buildAlertCard(
    icon: Icons.person_off_rounded,
    label: tr.get('wanted_persons'),
    color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEE2E2),
                      badge: badges.newWanted,
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const WantedPersonScreen()));
                        // Mark seen after returning
                        if (mounted) {
                          context.read<BadgeProvider>().markWantedSeen();
                        }
                      },
                      t: t),
                  const SizedBox(width: 12),
                  _buildAlertCard(
                      icon: Icons.person_search_rounded,
                      label: tr.get('missing_persons'),
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      badge: badges.newMissingPerson,
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => MissingPersonScreen()));
                        if (mounted) {
                          context.read<BadgeProvider>().markMissingPersonSeen();
                        }
                      },
                      t: t),
                  const SizedBox(width: 12),
                  _buildAlertCard(
                      icon: Icons.inventory_2_rounded,
                     label: tr.get('missing_items'),
                      color: const Color(0xFF1976D2),
                      bgColor: const Color(0xFFDBEAFE),
                      badge: badges.newMissingItem,
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MissingItemScreen()));
                        if (mounted) {
                          context.read<BadgeProvider>().markMissingItemSeen();
                        }
                      },
                      t: t),
                ]),

                const SizedBox(height: 24),

                _buildSectionTitle(tr.get('police_stations'), Icons.account_balance_rounded, t),
                const SizedBox(height: 12),
                _buildPoliceStationsList(t),

                const SizedBox(height: 24),

                _buildEmergencyCard(t, tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Guest banner ─────────────────────────────────────────────────────────
  Widget _buildGuestBanner(AppTheme t, AppLocalizations tr) {
    return GestureDetector(
      onTap: () => AuthGate.require(context, featureName: 'access all features'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFC9A84C).withOpacity(0.9),
              const Color(0xFFD4A855),
            ],
          ),
        ),
        child: Row(children: [
          const Icon(Icons.info_rounded,
              size: 16, color: Color(0xFF0D1B2A)),
          const SizedBox(width: 8),
          Expanded(
  child: Text(
    tr.get('guest_banner_text'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1B2A)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(tr.get('sign_in'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B2A))),
          ),
        ]),
      ),
    );
  }

  // ── Section title ────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon, AppTheme t) {
    final color = t.isNight
        ? Colors.white.withOpacity(0.85)
        : const Color(0xFF1A3A5C);
    return Row(children: [
      Icon(icon, size: 16, color: color.withOpacity(0.7)),
      const SizedBox(width: 6),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2)),
      const Spacer(),
    ]);
  }

  // ── Alert card — now accepts badge count ─────────────────────────────────
  Widget _buildAlertCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required AppTheme t,
    int badge = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
              decoration: BoxDecoration(
                color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: t.isNight ? color.withOpacity(0.15) : bgColor,
                    shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 10),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.isNight
                            ? Colors.white.withOpacity(0.85)
                            : const Color(0xFF1A3A5C),
                        height: 1.3)),
              ]),
            ),
            // Badge overlay on top-right corner of the card
            _buildBadge(badge, top: 4, right: 4),
          ],
        ),
      ),
    );
  }

  // ── Police stations list ─────────────────────────────────────────────────
  Widget _buildPoliceStationsList(AppTheme t) {
    final cardBg = t.isNight ? const Color(0xFF1A3A5C) : Colors.white;

    return Column(
      children: _stations.asMap().entries.map((entry) {
        final i       = entry.key;
        final station = entry.value;
        final type    = station['type'] as String;
        final accent  = _stationAccent(type);
        final icon    = _stationIcon(type);
        final isLast  = i == _stations.length - 1;

        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) =>
                      PoliceStationDetailScreen(station: station))),
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(t.isNight ? 0.12 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(t.isNight ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withOpacity(0.25), width: 1.5)),
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station['name'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.isNight
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF1A3A5C),
                            height: 1.3)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.location_on_rounded,
                          size: 11,
                          color: t.isNight
                              ? Colors.white38
                              : const Color(0xFF7A90B0)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(station['district'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: t.isNight
                                    ? Colors.white38
                                    : const Color(0xFF7A90B0))),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(t.isNight ? 0.12 : 0.07),
                  shape: BoxShape.circle),
                child: Icon(Icons.chevron_right_rounded,
                    size: 16, color: accent.withOpacity(0.7)),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Emergency card ───────────────────────────────────────────────────────
 Widget _buildEmergencyCard(AppTheme t, AppLocalizations tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.isNight
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC9A84C)
              .withOpacity(t.isNight ? 0.2 : 0.35),
          width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C).withOpacity(0.15),
            shape: BoxShape.circle),
          child: const Icon(Icons.emergency_rounded,
              size: 22, color: Color(0xFFC9A84C)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.get('emergency_contacts'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: t.isNight
                        ? const Color(0xFFC9A84C)
                        : const Color(0xFF92400E))),
            const SizedBox(height: 3),
            Text(tr.get('emergency_numbers'),
                style: TextStyle(
                    fontSize: 11,
                    color: t.isNight
                        ? Colors.white.withOpacity(0.5)
                        : const Color(0xFF92400E).withOpacity(0.7),
                    height: 1.4)),
          ],
        )),
      ]),
    );
  }

  // ── Station helpers ──────────────────────────────────────────────────────
  Color _stationAccent(String type) {
    switch (type) {
      case 'headquarters': return const Color(0xFFDC2626);
      case 'regional':     return const Color(0xFF7C3AED);
      case 'subcity':      return const Color(0xFF1976D2);
      case 'traffic':      return const Color(0xFFD97706);
      case 'special':      return const Color(0xFF059669);
      default:             return const Color(0xFF1A3A5C);
    }
  }

  IconData _stationIcon(String type) {
    switch (type) {
      case 'headquarters': return Icons.account_balance_rounded;
      case 'regional':     return Icons.corporate_fare_rounded;
      case 'subcity':      return Icons.location_city_rounded;
      case 'traffic':      return Icons.traffic_rounded;
      case 'special':      return Icons.shield_rounded;
      default:             return Icons.account_balance_rounded;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tr            = context.watch<LanguageProvider>().tr;
    final themeProvider = context.watch<ThemeProvider>();
    final t             = themeProvider.theme;
    final auth          = context.watch<AuthProvider>();
    final badges        = context.watch<BadgeProvider>();
    final isGuest       = auth.isGuest;

    // ── Guest layout ──────────────────────────────────────────────────────
    if (isGuest) {
      final guestIndex = _selectedIndex.clamp(0, 1);

      final List<Widget> guestPages = [
        _buildHomeBody(t, true),
        const NewsFeedScreen(),
      ];

      final appBarBg  = t.isNight
          ? const Color(0xFF0F2440)
          : const Color(0xFF1A3A5C);
      final iconColor = t.isNight
          ? const Color(0xFFC9A84C)
          : Colors.white;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: t.isNight
              ? const Color(0xFF112D4E)
              : const Color(0xFFF0F4F8),

          appBar: _buildAppBar(t, tr, isGuest: true,
              title: guestIndex == 0 ? null : tr.get('news_feed'),
              iconColor: iconColor),

          body: guestPages[guestIndex],

          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4)),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: guestIndex,
              onTap: (i) => _onNavTap(i, isGuest: true),
              backgroundColor: t.isNight
                  ? const Color(0xFF0F2440)
                  : const Color(0xFF1A3A5C),
              selectedItemColor: t.isNight
                  ? const Color(0xFFC9A84C)
                  : Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.45),
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined, size: 26),
                    activeIcon: const Icon(Icons.home_rounded, size: 26),
                    label: tr.get('nav_home')),
                BottomNavigationBarItem(
                    icon: _navIcon(Icons.dynamic_feed_outlined,
                        badge: badges.newNews),
                    activeIcon: _navIcon(Icons.dynamic_feed_rounded,
                        active: true, badge: badges.newNews),
                    label: tr.get('nav_feed')),
              ],
            ),
          ),
        ),
      );
    }

    // ── Authenticated layout ──────────────────────────────────────────────
    final List<Widget> pages = [
      const SubmitReportScreen(),
      const MyReportsScreen(),
      _buildHomeBody(t, false),
      const NewsFeedScreen(),
      const AccountScreen(),
    ];

    final List<String> titles = [
      tr.get('report_incident'),
      tr.get('my_reports'),
      tr.get('home'),
      tr.get('news_feed'),
      tr.get('account'),
    ];

    final iconColor = t.isNight
        ? const Color(0xFFC9A84C)
        : Colors.white;

    final authIndex = _selectedIndex.clamp(0, 4);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: t.isNight
            ? const Color(0xFF112D4E)
            : const Color(0xFFF0F4F8),

        appBar: _buildAppBar(t, tr, isGuest: false,
            title: authIndex != 2 ? titles[authIndex] : null,
            iconColor: iconColor),

        body: pages[authIndex],

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -4)),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: authIndex,
            onTap: (i) => _onNavTap(i, isGuest: false),
            backgroundColor: t.isNight
                ? const Color(0xFF0F2440)
                : const Color(0xFF1A3A5C),
            selectedItemColor: t.isNight
                ? const Color(0xFFC9A84C)
                : Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.45),
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.campaign_outlined, size: 22),
                  activeIcon: const Icon(Icons.campaign_rounded, size: 22),
                  label: tr.get('nav_report')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.description_outlined, size: 22),
                  activeIcon: const Icon(Icons.description_rounded, size: 22),
                  label: tr.get('nav_my_reports')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined, size: 26),
                  activeIcon: const Icon(Icons.home_rounded, size: 26),
                  label: tr.get('nav_home')),
              // Feed tab — badge shows unseen news count
              BottomNavigationBarItem(
                  icon: _navIcon(Icons.dynamic_feed_outlined,
                      badge: badges.newNews),
                  activeIcon: _navIcon(Icons.dynamic_feed_rounded,
                      active: true, badge: badges.newNews),
                  label: tr.get('nav_feed')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.account_circle_outlined, size: 22),
                  activeIcon: const Icon(Icons.account_circle_rounded, size: 22),
                  label: tr.get('nav_account')),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared AppBar ─────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
  AppTheme t,
  AppLocalizations tr, {
  required bool isGuest,
  required Color iconColor,
  String? title,
}) {
    final appBarBg = t.isNight
        ? const Color(0xFF0F2440)
        : const Color(0xFF1A3A5C);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: t.isNight
                ? [const Color(0xFF1A2F4A), const Color(0xFF0D1B2A)]
                : [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)],
          ),
        ),
      ),
      centerTitle: title != null,
      systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light),
      title: title == null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFFC9A84C).withOpacity(0.5),
                    width: 1.5)),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/logo.png',
                        fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hawassa',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFC9A84C),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          height: 1)),
                  Text('Crime Report',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
                ],
              ),
            ])
          : Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
      actions: [
        if (!isGuest)
          Stack(children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                  size: 26, color: iconColor),
              onPressed: _openNotifications,
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: appBarBg, width: 1.5)),
                  alignment: Alignment.center,
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
                ),
              ),
          ]),
        if (isGuest)
          TextButton(
            onPressed: () =>
                AuthGate.require(context, featureName: 'access all features'),
            child: Text(tr.get('sign_in'),
                style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}