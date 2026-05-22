// lib/screens/account_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';       // ← new
import 'auth/login_screen.dart';
import 'account/edit_profile_screen.dart';
import 'account/help_screen.dart';
import 'account/terms_screen.dart';
import 'account/about_screen.dart';
import 'account/contact_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String  _fullName     = '';
  String  _email        = '';
  String  _phone        = '';
  String? _profilePhoto;
  bool    _isLoading    = true;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyMid  = Color(0xFF1E4D7B);
  static const Color _gold     = Color(0xFFC9A84C);
  static const Color _white    = Color(0xFFFFFFFF);

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.getWithAuth('/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] ?? data;
        setState(() {
          _fullName     = user['full_name']     ?? '';
          _email        = user['email']         ?? '';
          _phone        = user['phone']         ?? '';
          _profilePhoto = user['profile_photo'];
          _isLoading    = false;
        });
      } else { setState(() => _isLoading = false); }
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _logout(AppTheme t) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.isNight ? const Color(0xFF1A3A5C) : _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle),
            child: const Icon(Icons.logout_rounded,
                color: Colors.red, size: 18)),
          const SizedBox(width: 12),
          Text('Sign Out',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: t.isNight ? _white : _navy,
                  fontSize: 17)),
        ]),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
              color: t.isNight
                  ? _white.withOpacity(0.6)
                  : _navy.withOpacity(0.6),
              fontSize: 14,
              height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: t.isNight ? _white.withOpacity(0.6) : _navy,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // ── Use ApiService for server-side logout, then AuthProvider ──
              try {
                await ApiService.postWithAuth('/logout', {});
              } catch (_) {}
              // AuthProvider clears token + sets guest state
              if (mounted) await context.read<AuthProvider>().logout();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const LoginScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (r) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppTheme t) {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: t.isNight ? const Color(0xFF0F2440) : _white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: t.isNight
                    ? _white.withOpacity(0.2)
                    : _navy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Select Language',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.isNight ? _white : _navy)),
            const SizedBox(height: 16),
            _languageOption(
              flag: '🇬🇧', name: 'English', subtitle: 'English',
              code: 'en',
              selected: langProvider.languageCode == 'en', t: t,
              onTap: () async {
                await langProvider.setLanguage('en');
                if (context.mounted) Navigator.pop(context);
              }),
            const SizedBox(height: 10),
            _languageOption(
              flag: '🇪🇹', name: 'አማርኛ', subtitle: 'Amharic',
              code: 'am',
              selected: langProvider.languageCode == 'am', t: t,
              onTap: () async {
                await langProvider.setLanguage('am');
                if (context.mounted) Navigator.pop(context);
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _languageOption({
    required String flag, required String name,
    required String subtitle, required String code,
    required bool selected, required VoidCallback onTap,
    required AppTheme t,
  }) {
    final selBg   = t.isNight ? _gold : _navy;
    final selText = t.isNight ? _navyDark : _white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? selBg
              : (t.isNight
                  ? _white.withOpacity(0.06)
                  : const Color(0xFFF5F8FC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? selBg
                : (t.isNight
                    ? _white.withOpacity(0.1)
                    : const Color(0xFFDDE6F0)),
            width: selected ? 0 : 1.5)),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? selText
                          : (t.isNight ? _white : _navy))),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? selText.withOpacity(0.7)
                          : (t.isNight
                              ? _white.withOpacity(0.45)
                              : _navy.withOpacity(0.5)))),
            ],
          )),
          if (selected)
            Icon(Icons.check_circle_rounded,
                color: selText, size: 22),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr           = context.watch<LanguageProvider>().tr;
    final t            = context.watch<ThemeProvider>().theme;
    final langProvider = context.read<LanguageProvider>();
    final bgColor      = t.isNight
        ? const Color(0xFF112D4E)
        : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              color: t.isNight ? _gold : _navy))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(children: [

                // ── Profile hero ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: t.isNight
                          ? [const Color(0xFF0A1628),
                             const Color(0xFF112D4E)]
                          : [_navyDark, _navy, _navyMid],
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(top: -20, right: -20,
                      child: Container(width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _white.withOpacity(0.05),
                            width: 1.5)))),
                    Positioned(top: 20, right: 20,
                      child: Container(width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _gold.withOpacity(0.2),
                            width: 1)))),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Stack(children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _gold.withOpacity(0.6),
                                  width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _gold.withOpacity(0.2),
                                    blurRadius: 16,
                                    spreadRadius: 2),
                                ]),
                              child: ClipOval(
                                child: _profilePhoto != null &&
                                    _profilePhoto!.isNotEmpty
                                    ? Image.network(
                                        '${ApiConstants.storageUrl}/$_profilePhoto',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                              color: _navy,
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 44,
                                                color: _white.withOpacity(0.5))))
                                    : Container(
                                        color: _navy.withOpacity(0.5),
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 44,
                                          color: _white.withOpacity(0.5))),
                              ),
                            ),
                          ]),

                          const SizedBox(width: 18),

                          // User info
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_fullName.isNotEmpty
                                  ? _fullName : 'Welcome',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _white,
                                      letterSpacing: 0.3)),
                              const SizedBox(height: 4),
                              if (_email.isNotEmpty)
                                Row(children: [
                                  Icon(Icons.email_outlined,
                                      size: 12,
                                      color: _white.withOpacity(0.5)),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(_email,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _white.withOpacity(0.6)),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              const SizedBox(height: 3),
                              if (_phone.isNotEmpty)
                                Row(children: [
                                  Icon(Icons.phone_outlined,
                                      size: 12,
                                      color: _white.withOpacity(0.5)),
                                  const SizedBox(width: 5),
                                  Text(_phone,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _white.withOpacity(0.6))),
                                ]),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () async {
                                  final updated = await Navigator.push(
                                    context, MaterialPageRoute(
                                      builder: (_) =>
                                          const EditProfileScreen()));
                                  if (updated == true) {
                                    setState(() => _isLoading = true);
                                    await _loadProfile();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _gold,
                                    borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          size: 13, color: _navyDark),
                                      const SizedBox(width: 5),
                                      Text(tr.get('edit_profile'),
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _navyDark)),
                                    ]),
                                ),
                              ),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Menu sections ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [

                    _buildSectionLabel('Support', t),
                    const SizedBox(height: 8),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: tr.get('help'),
                        color: const Color(0xFF1976D2),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const HelpScreen()))),
                      _MenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: tr.get('contact_us'),
                        color: const Color(0xFF059669),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ContactScreen()))),
                      _MenuItem(
                        icon: Icons.share_outlined,
                        label: tr.get('share_app'),
                        color: const Color(0xFF7C3AED),
                        onTap: () => Share.share(
                          'Download the Hawassa Crime Report App!\n'
                          'https://play.google.com/store/apps/details?'
                          'id=com.example.crime_reporting_app',
                          subject: 'Hawassa Crime Report App')),
                    ], t),

                    const SizedBox(height: 16),

                    _buildSectionLabel('Legal', t),
                    const SizedBox(height: 8),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: tr.get('terms_privacy'),
                        color: const Color(0xFFD97706),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const TermsScreen()))),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        label: tr.get('about_us'),
                        color: const Color(0xFF0369A1),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen()))),
                    ], t),

                    const SizedBox(height: 16),

                    _buildSectionLabel('Preferences', t),
                    const SizedBox(height: 8),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.language_rounded,
                        label: tr.get('language'),
                        color: const Color(0xFF1A3A5C),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (t.isNight ? _gold : _navy)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            langProvider.isAmharic
                                ? '🇪🇹 አማርኛ' : '🇬🇧 English',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: t.isNight ? _gold : _navy))),
                        onTap: () => _showLanguagePicker(context, t)),
                    ], t),

                    const SizedBox(height: 20),

                    // Logout button
                    GestureDetector(
                      onTap: () => _logout(t),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                            width: 1.5)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Text(tr.get('logout'),
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ]),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('Hawassa Crime Report  ·  v1.0.0',
                        style: TextStyle(
                            fontSize: 11,
                            color: t.isNight
                                ? _white.withOpacity(0.25)
                                : _navy.withOpacity(0.3))),

                    const SizedBox(height: 16),
                  ]),
                ),
              ]),
            ),
    );
  }

  Widget _buildSectionLabel(String label, AppTheme t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: t.isNight
                  ? _white.withOpacity(0.35)
                  : _navy.withOpacity(0.4),
              letterSpacing: 1.2)),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items, AppTheme t) {
    final cardBg = t.isNight ? const Color(0xFF1A3A5C) : _white;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                t.isNight ? 0.15 : 0.06),
            blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;

          return Column(children: [
            InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.vertical(
                top: i == 0
                    ? const Radius.circular(18) : Radius.zero,
                bottom: isLast
                    ? const Radius.circular(18) : Radius.zero),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(
                          t.isNight ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.icon,
                        size: 19, color: item.color)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.isNight
                              ? _white.withOpacity(0.9)
                              : _navy))),
                  if (item.trailing != null)
                    item.trailing!
                  else
                    Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: t.isNight
                            ? _white.withOpacity(0.25)
                            : _navy.withOpacity(0.3)),
                ]),
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                indent: 68,
                color: t.isNight
                    ? _white.withOpacity(0.07)
                    : const Color(0xFFDDE6F0)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData     icon;
  final String       label;
  final Color        color;
  final Widget?      trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });
}