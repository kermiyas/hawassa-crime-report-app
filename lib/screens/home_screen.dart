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

class _HomeScreenState extends State<HomeScreen> {
  String _userName   = '';
  int _unreadCount   = 0;
  int _selectedIndex = 2;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadCount();
    _badgeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnreadCount());
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationsScreen(onRead: _loadUnreadCount)),
    );
    _loadUnreadCount();
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  String _tabTitle(int index, tr) {
    switch (index) {
      case 0: return tr.get('report_incident');
      case 1: return tr.get('my_reports');
      case 2: return tr.get('app_name');
      case 3: return tr.get('news_feed');
      case 4: return tr.get('account');
      default: return tr.get('app_name');
    }
  }

  Widget _buildHomeBody(tr, AppTheme t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          _card(Icons.report_problem_outlined, tr.get('report_incident'), t,
              onTap: () => setState(() => _selectedIndex = 0)),
          const SizedBox(width: 16),
          _card(Icons.person_search_outlined, tr.get('wanted_person'), t,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WantedPersonScreen()))),
        ]),
        const SizedBox(height: 8),
        Divider(color: t.primaryText.withOpacity(0.3), thickness: 0.5),
        const SizedBox(height: 8),
        Row(children: [
          _card(Icons.search, tr.get('missing_person'), t,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MissingPersonScreen()))),
          const SizedBox(width: 16),
          _card(Icons.inventory_2_outlined, tr.get('missing_item'), t,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MissingItemScreen()))),
        ]),
        const SizedBox(height: 8),
        Divider(color: t.primaryText.withOpacity(0.3), thickness: 0.5),
        const SizedBox(height: 8),
        Row(children: [
          _card(Icons.feed_outlined, tr.get('news'), t,
              onTap: () => setState(() => _selectedIndex = 3)),
          const SizedBox(width: 16),
          _card(Icons.manage_accounts_outlined, tr.get('account'), t,
              onTap: () => setState(() => _selectedIndex = 4)),
        ]),
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
      _buildHomeBody(tr, t),
      const NewsFeedScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        automaticallyImplyLeading: false,
        centerTitle: _selectedIndex != 2,
        title: _selectedIndex == 2
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/logo.png', width: 32, height: 32),
                const SizedBox(width: 8),
                Text(tr.get('app_name'),
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: t.appBarTextColor)),
              ])
            : Text(_tabTitle(_selectedIndex, tr),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: t.appBarTextColor)),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isNight ? Icons.nightlight_round : Icons.wb_sunny,
              color: t.navSelectedColor,
            ),
            onPressed: () => themeProvider.toggle(),
          ),
          Stack(children: [
            IconButton(
              icon: Icon(Icons.notifications_none, size: 28, color: t.navSelectedColor),
              onPressed: _openNotifications,
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ]),
        ],
      ),
      body: pages[_selectedIndex],
bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        backgroundColor: t.bottomNavBg,
        selectedItemColor: t.bottomNavSelected,
        unselectedItemColor: t.bottomNavUnselected,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.campaign_outlined),
              label: tr.get('nav_report')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.description_outlined),
              label: tr.get('nav_my_reports')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: tr.get('nav_home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.dynamic_feed_outlined),
              label: tr.get('nav_feed')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined),
              label: tr.get('nav_account')),
        ],
      ),
    );
  }

  Widget _card(IconData icon, String label, AppTheme t,
      {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: t.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: t.scaffoldBg, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: t.iconColor),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}