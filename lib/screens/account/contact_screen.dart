// lib/screens/account/contact_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _sendMessage() async {
    final tr = context.read<LanguageProvider>().tr;
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.isAmharic ? 'ርዕስ እና መልዕክት ያስፈልጋል' : 'Subject and message are required')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final response = await ApiService.postWithAuth('/contact', {
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      });
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _subjectCtrl.clear();
        _messageCtrl.clear();
        if (mounted) {
          final t           = context.read<ThemeProvider>().theme;
          final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: t.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Color(0xFF065F46), size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  tr.isAmharic ? 'መልዕክቱ ተልኳል!' : 'Message Sent!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accentColor),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.isAmharic
                      ? 'መልዕክትዎ ለፖሊስ ቡድን ተልኳል። በቅርቡ ምላሽ ይሰጥዎታል።'
                      : 'Your message has been sent to the police team. You will receive a response shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.5),
                ),
              ]),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(tr.get('done'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        _showError(body['message'] ?? (tr.isAmharic ? 'ስህተት ተፈጥሯል' : 'Failed to send message'));
      }
    } catch (e) {
      _showError(tr.isAmharic ? 'የኔትወርክ ስህተት' : 'Network error. Please try again.');
    }
    if (mounted) setState(() => _sending = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr          = context.watch<LanguageProvider>().tr;
    final t           = context.watch<ThemeProvider>().theme;
    final isAm        = tr.isAmharic;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text(tr.get('contact_us'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: t.appBarTextColor)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(Icons.headset_mic_rounded,
                    color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                    size: 36),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isAm ? 'እናግዝዎ?' : 'How can we help?',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAm ? 'ከፖሊስ ቡድናችን ጋር ይገናኙ' : 'Get in touch with our police team',
                    style: TextStyle(
                        fontSize: 13,
                        color: t.isNight
                            ? const Color(0xFF1A3A5C).withOpacity(0.7)
                            : Colors.white70),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Quick contact buttons ─────────────────────────────────────
            Text(isAm ? 'ፈጣን አድራሻ' : 'Quick Contact',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: accentColor)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _quickButton(
                icon: Icons.phone_rounded,
                label: isAm ? 'ስልክ' : 'Call',
                subtitle: '907',
                color: const Color(0xFF16A34A),
                onTap: () => _launch('tel:907'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickButton(
                icon: Icons.local_police_rounded,
                label: isAm ? 'ፖሊስ' : 'Police',
                subtitle: isAm ? 'ስልክ 991' : 'Line 991',
                color: t.isNight ? const Color(0xFF1E4268) : const Color(0xFF486D99),
                onTap: () => _launch('tel:991'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickButton(
                icon: Icons.email_rounded,
                label: isAm ? 'ኢሜይል' : 'Email',
                subtitle: isAm ? 'ላክ' : 'Send',
                color: const Color(0xFFD97706),
                onTap: () => _launch('mailto:info@hawassapolice.gov.et'),
              )),
            ]),
            const SizedBox(height: 20),

            // ── Contact form ──────────────────────────────────────────────
            Text(isAm ? 'መልዕክት ላክ' : 'Send Us a Message',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: accentColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.04),
                    blurRadius: 6)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAm ? 'ርዕስ *' : 'Subject *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: accentColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectCtrl,
                  style: TextStyle(color: t.primaryText),
                  decoration: _inputDeco(
                      isAm ? 'ለምሳሌ፦ አስተያየት፣ ጥያቄ...' : 'e.g. Feedback, Question...',
                      t, accentColor),
                ),
                const SizedBox(height: 14),
                Text(isAm ? 'መልዕክት *' : 'Message *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: accentColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  style: TextStyle(color: t.primaryText),
                  decoration: _inputDeco(
                      isAm ? 'መልዕክትዎን እዚህ ይጻፉ...' : 'Write your message here...',
                      t, accentColor),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: accentColor.withOpacity(0.5),
                    ),
                    icon: _sending
                        ? SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white))
                        : const Icon(Icons.send),
                    label: Text(
                      _sending
                          ? (isAm ? 'እየተላከ...' : 'Sending...')
                          : (isAm ? 'መልዕክት ላክ' : 'Send Message'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _quickButton({
    required IconData icon, required String label,
    required String subtitle, required Color color, required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      );

  InputDecoration _inputDeco(String hint, AppTheme t, Color accentColor) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: t.secondaryText),
    filled: true,
    fillColor: t.scaffoldBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: t.isNight ? const Color(0xFF2A5080) : const Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: t.isNight ? const Color(0xFF2A5080) : const Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accentColor, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}