// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'notifications/notifications_screen.dart';
import 'reports/submit_report_screen.dart';
import 'account_screen.dart';
import 'news/news_feed_screen.dart';
import 'reports/my_reports_screen.dart';
import 'alerts/wanted_person_screen.dart';
import 'alerts/missing_person_screen.dart';
import 'alerts/missing_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName     = '';
  int    _unreadCount  = 0;
  int    _selectedIndex = 2;
  Timer? _badgeTimer;

  AnimationController? _heroController;
  Animation<double>?   _heroFade;
  Animation<Offset>?   _heroSlide;

  // ── Police color palette ─────────────────────────────────────────────────
  static const Color _navyDark  = Color(0xFF0D1B2A);
  static const Color _navy      = Color(0xFF1A3A5C);
  static const Color _navyMid   = Color(0xFF1E4D7B);
  static const Color _gold      = Color(0xFFC9A84C);
  static const Color _white     = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _heroController = ctrl;
    _heroFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn));
    _heroSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
    ctrl.forward();

    _loadProfile();
    _loadUnreadCount();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 30), (_) => _loadUnreadCount());
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
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
    await Navigator.push(context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(onRead: _loadUnreadCount)));
    _loadUnreadCount();
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _firstName() {
    if (_userName.isEmpty) return 'Citizen';
    return _userName.split(' ').first;
  }

  // ── Home body ─────────────────────────────────────────────────────────────
  Widget _buildHomeBody(AppTheme t) {
    final fade  = _heroFade  ?? const AlwaysStoppedAnimation(1.0);
    final slide = _heroSlide ?? const AlwaysStoppedAnimation(Offset.zero);
    final isNight = t.isNight;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero header ─────────────────────────────────────────────────
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
                    colors: isNight
                      ? [const Color(0xFF0F2440), const Color(0xFF112D4E)]
                      : [_navyDark, _navy, _navyMid],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20, right: -20,
                      child: Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _white.withOpacity(0.06), width: 1.5)),
                      ),
                    ),
                    Positioned(
                      bottom: -10, left: -10,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _gold.withOpacity(0.12), width: 1)),
                      ),
                    ),
                    Positioned(
                      top: 20, right: 60,
                      child: Container(width: 4, height: 4,
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.5),
                          shape: BoxShape.circle)),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greeting(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _gold,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                                  const SizedBox(height: 2),
                                  Text(_firstName(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: _white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3)),
                                ],
                              ),
                              // Logo badge
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _white.withOpacity(0.08),
                                  border: Border.all(
                                    color: _gold.withOpacity(0.4), width: 1.5)),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset('assets/logo.png',
                                      fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Safety tagline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _white.withOpacity(0.1), width: 1)),
                            child: Row(children: [
                              Icon(Icons.shield_outlined,
                                size: 15, color: _gold),
                              const SizedBox(width: 8),
                              Text(
                                'Hawassa Crime & Safety Reporting',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3)),
                            ]),
                          ),

                          const SizedBox(height: 16),

                          // Quick action — Report Incident
                          GestureDetector(
                            onTap: () => setState(() => _selectedIndex = 0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _gold.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: _navyDark.withOpacity(0.2),
                                    shape: BoxShape.circle),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    size: 20, color: _navyDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Report an Incident',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _navyDark)),
                                      Text('Submit crime or safety report',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _navyDark.withOpacity(0.65))),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: _navyDark),
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

          // ── Body content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Section title
                _buildSectionTitle('Public Alerts', Icons.warning_amber_rounded),
                const SizedBox(height: 12),

                // Alert cards row
                Row(children: [
                  _buildAlertCard(
                    icon: Icons.person_off_rounded,
                    label: 'Wanted\nPersons',
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEE2E2),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const WantedPersonScreen())),
                    t: t,
                  ),
                  const SizedBox(width: 12),
                  _buildAlertCard(
                    icon: Icons.person_search_rounded,
                    label: 'Missing\nPersons',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const MissingPersonScreen())),
                    t: t,
                  ),
                  const SizedBox(width: 12),
                  _buildAlertCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Missing\nItems',
                    color: const Color(0xFF1976D2),
                    bgColor: const Color(0xFFDBEAFE),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => const MissingItemScreen())),
                    t: t,
                  ),
                ]),

                const SizedBox(height: 24),

                // Section title
                _buildSectionTitle('My Activity', Icons.person_outline_rounded),
                const SizedBox(height: 12),

                // Activity cards
                Row(children: [
                  _buildActivityCard(
                    icon: Icons.description_outlined,
                    label: 'My Reports',
                    subtitle: 'Track your submissions',
                    color: _navy,
                    onTap: () => setState(() => _selectedIndex = 1),
                    t: t,
                  ),
                  const SizedBox(width: 12),
                  _buildActivityCard(
                    icon: Icons.dynamic_feed_outlined,
                    label: 'Police Feed',
                    subtitle: 'News & safety tips',
                    color: const Color(0xFF0369A1),
                    onTap: () => setState(() => _selectedIndex = 3),
                    t: t,
                  ),
                ]),

                const SizedBox(height: 24),

                // Emergency info card
                _buildEmergencyCard(t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: _navy.withOpacity(0.7)),
      const SizedBox(width: 6),
      Text(title,
        style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800,
          color: _navy, letterSpacing: 0.2)),
      const Spacer(),
      Text('View All',
        style: TextStyle(
          fontSize: 12, color: _navy.withOpacity(0.5),
          fontWeight: FontWeight.w600)),
      Icon(Icons.chevron_right_rounded,
        size: 16, color: _navy.withOpacity(0.4)),
    ]);
  }

  // ── Alert card ────────────────────────────────────────────────────────────
  Widget _buildAlertCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required AppTheme t,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: t.isNight ? t.cardColor : _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.06),
                blurRadius: 12, offset: const Offset(0, 4)),
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
                fontSize: 12, fontWeight: FontWeight.w700,
                color: t.isNight ? _white.withOpacity(0.85) : _navy,
                height: 1.3)),
          ]),
        ),
      ),
    );
  }

  // ── Activity card ─────────────────────────────────────────────────────────
  Widget _buildActivityCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required AppTheme t,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.isNight ? t.cardColor : _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.06),
                blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(t.isNight ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: t.isNight ? _white.withOpacity(0.9) : _navy)),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: t.isNight
                      ? _white.withOpacity(0.45)
                      : _navy.withOpacity(0.5))),
              ],
            )),
            Icon(Icons.chevron_right_rounded,
              size: 16,
              color: t.isNight
                ? _white.withOpacity(0.3)
                : _navy.withOpacity(0.3)),
          ]),
        ),
      ),
    );
  }

  // ── Emergency card ────────────────────────────────────────────────────────
  Widget _buildEmergencyCard(AppTheme t) {
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
          color: t.isNight
            ? _gold.withOpacity(0.2)
            : _gold.withOpacity(0.3),
          width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.15),
            shape: BoxShape.circle),
          child: const Icon(Icons.emergency_rounded,
            size: 22, color: Color(0xFFC9A84C)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Contacts',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: t.isNight ? _gold : const Color(0xFF92400E))),
            const SizedBox(height: 2),
            Text('Police: 991  •  Ambulance: 907  •  Fire: 939',
              style: TextStyle(
                fontSize: 11,
                color: t.isNight
                  ? _white.withOpacity(0.5)
                  : const Color(0xFF92400E).withOpacity(0.7),
                height: 1.4)),
          ],
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr            = context.watch<LanguageProvider>().tr;
    final themeProvider = context.watch<ThemeProvider>();
    final t             = themeProvider.theme;

    final List<Widget> pages = [
      const SubmitReportScreen(),
      const MyReportsScreen(),
      _buildHomeBody(t),
      const NewsFeedScreen(),
      const AccountScreen(),
    ];

    final List<String> titles = [
      'Report Incident',
      'My Reports',
      'Home',
      'Police Feed',
      'Account',
    ];

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: _selectedIndex != 2,
        title: _selectedIndex == 2
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: t.appBarFg.withOpacity(0.3), width: 1)),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset('assets/logo.png',
                      fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Hawassa Crime Report',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: t.appBarTextColor)),
            ])
          : Text(titles[_selectedIndex],
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: t.appBarTextColor)),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              themeProvider.isNight
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_outlined,
              color: t.navSelectedColor, size: 22),
            onPressed: themeProvider.toggle,
          ),
          // Notification bell
          Stack(children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                size: 26, color: t.navSelectedColor),
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
                    borderRadius: BorderRadius.circular(9)),
                  alignment: Alignment.center,
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: _white, fontSize: 10,
                      fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
          const SizedBox(width: 4),
        ],
      ),

      body: pages[_selectedIndex],

      // ── Bottom nav ───────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          backgroundColor: t.bottomNavBg,
          selectedItemColor: t.bottomNavSelected,
          unselectedItemColor: t.bottomNavUnselected,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
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
              icon: const Icon(Icons.home_outlined, size: 24),
              activeIcon: const Icon(Icons.home_rounded, size: 24),
              label: tr.get('nav_home')),
            BottomNavigationBarItem(
              icon: const Icon(Icons.dynamic_feed_outlined, size: 22),
              activeIcon: const Icon(Icons.dynamic_feed_rounded, size: 22),
              label: tr.get('nav_feed')),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined, size: 22),
              activeIcon: const Icon(Icons.account_circle_rounded, size: 22),
              label: tr.get('nav_account')),
          ],
        ),
      ),
    );
  }
}