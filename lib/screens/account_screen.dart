// lib/screens/account_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
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
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _logout(AppLocalizations tr, AppTheme t) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr.get('logout'),
            style: TextStyle(fontWeight: FontWeight.w800, color: t.primaryText)),
        content: Text(tr.get('logout_confirm'), style: TextStyle(color: t.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.get('cancel'), style: TextStyle(color: t.primaryText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.postWithAuth('/logout', {});
              await ApiService.removeToken();
              if (mounted) Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            child: Text(tr.get('logout'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations tr, AppTheme t) {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: t.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(tr.get('select_language'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.primaryText)),
          const SizedBox(height: 16),
          _languageOption(
            flag: '🇬🇧', name: 'English', subtitle: 'English', code: 'en',
            selected: langProvider.languageCode == 'en', t: t,
            onTap: () async {
              await langProvider.setLanguage('en');
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _languageOption(
            flag: '🇪🇹', name: 'አማርኛ', subtitle: 'Amharic', code: 'am',
            selected: langProvider.languageCode == 'am', t: t,
            onTap: () async {
              await langProvider.setLanguage('am');
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _languageOption({
    required String flag, required String name, required String subtitle,
    required String code, required bool selected, required VoidCallback onTap, required AppTheme t,
  }) {
    // Night mode selected: golden bg with dark text
    // Day mode selected:   navy bg with white text
    // Unselected:          scaffoldBg with normal text
    final selectedBg      = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
final selectedBorder  = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    final selectedText    = t.isNight ? const Color(0xFF1A3A5C) : Colors.white;
    final selectedSubText = t.isNight ? const Color(0xFF1A3A5C).withOpacity(0.6) : Colors.white70;
    final checkColor      = t.isNight ? const Color(0xFF1A3A5C) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? selectedBg : t.scaffoldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? selectedBorder : t.dividerColor,
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: selected ? selectedText : t.primaryText)),
            Text(subtitle, style: TextStyle(
                fontSize: 12,
                color: selected ? selectedSubText : t.secondaryText)),
          ])),
          if (selected) Icon(Icons.check_circle_rounded, color: checkColor, size: 22),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr           = context.watch<LanguageProvider>().tr;
    final t            = context.watch<ThemeProvider>().theme;
    final langProvider = context.read<LanguageProvider>();

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: t.buttonColor))
          : SingleChildScrollView(
              child: Column(children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  color: t.scaffoldBg,
                  child: Row(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: t.buttonColor, width: 2)),
                      child: ClipOval(
                        child: _profilePhoto != null && _profilePhoto!.isNotEmpty
                            ? Image.network('${ApiConstants.storageUrl}/$_profilePhoto',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.person, size: 50, color: t.iconColor))
                            : Icon(Icons.person, size: 50, color: t.iconColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: t.primaryText)),
                      const SizedBox(height: 2),
                      if (_email.isNotEmpty)
                        Text(_email, style: TextStyle(fontSize: 12, color: t.secondaryText)),
                      const SizedBox(height: 2),
                      Text(_phone, style: TextStyle(fontSize: 14, color: t.secondaryText)),
                    ])),
                  ]),
                ),
                Divider(height: 1, thickness: 2, color: t.buttonColor),
                const SizedBox(height: 16),

                // Edit Profile
                _group([
                  _item(icon: Icons.edit_outlined, label: tr.get('edit_profile'), t: t,
                    onTap: () async {
                      final updated = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      if (updated == true) { setState(() => _isLoading = true); await _loadProfile(); }
                    }),
                ], t),
                const SizedBox(height: 12),

                // Help / Legal
                _group([
                  _item(icon: Icons.help_outline, label: tr.get('help'), t: t, divider: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HelpScreen()))),
                  _item(icon: Icons.lock_outline, label: tr.get('terms_privacy'), t: t, divider: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TermsScreen()))),
                  _item(icon: Icons.info_outline, label: tr.get('about_us'), t: t, divider: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()))),
                  _item(icon: Icons.chat_bubble_outline, label: tr.get('contact_us'), t: t, divider: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ContactScreen()))),
                  _item(icon: Icons.share_outlined, label: tr.get('share_app'), t: t,
                    onTap: () {
                      Share.share(
                        tr.isAmharic
                            ? 'የሀዋሳ ወንጀል ሪፖርት መተግበሪያን ያውርዱ!\nhttps://play.google.com/store/apps/details?id=com.example.crime_reporting_app'
                            : 'Download the Hawassa Crime Report App!\nhttps://play.google.com/store/apps/details?id=com.example.crime_reporting_app',
                        subject: tr.isAmharic ? 'የሀዋሳ ወንጀል ሪፖርት' : 'Hawassa Crime Report App',
                      );
                    }),
                ], t),
                const SizedBox(height: 12),

                // Language
                _group([
                  ListTile(
                    onTap: () => _showLanguagePicker(context, tr, t),
                    leading: Icon(Icons.language, color: t.iconColor),
                    title: Text(tr.get('language'),
                        style: TextStyle(color: t.primaryText,
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(langProvider.isAmharic ? '🇪🇹 አማርኛ' : '🇬🇧 English',
                          style: TextStyle(fontSize: 13, color: t.secondaryText)),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: t.iconColor),
                    ]),
                  ),
                ], t),
                const SizedBox(height: 12),

                // Logout
                _group([
                  ListTile(
                    onTap: () => _logout(tr, t),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(tr.get('logout'),
                        style: const TextStyle(color: Colors.red,
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ], t),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _group(List<Widget> children, AppTheme t) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(14)),
    child: Column(children: children),
  );

  Widget _item({required IconData icon, required String label,
      required VoidCallback onTap, required AppTheme t, bool divider = false}) {
    return Column(children: [
      ListTile(
        onTap: onTap,
        leading: Icon(icon, color: t.iconColor),
        title: Text(label, style: TextStyle(color: t.primaryText,
            fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Icon(Icons.chevron_right, color: t.iconColor),
      ),
      if (divider) Divider(height: 1, indent: 16, endIndent: 16, color: t.dividerColor),
    ]);
  }
}