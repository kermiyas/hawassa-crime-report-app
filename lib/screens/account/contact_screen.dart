// lib/screens/account/contact_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending      = false;
  int  _activeField  = -1;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final tr = context.read<LanguageProvider>().tr;
    if (!_formKey.currentState!.validate()) return;
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
        if (mounted) _showSuccess();
      } else {
        _showError(body['message'] ??
            (tr.isAmharic ? 'ስህተት ተፈጥሯል' : 'Failed to send message'));
      }
    } catch (e) {
      _showError(
          tr.isAmharic ? 'የኔትወርክ ስህተት' : 'Network error. Please try again.');
    }
    if (mounted) setState(() => _sending = false);
  }

  void _showSuccess() {
    final tr   = context.read<LanguageProvider>().tr;
    final t    = context.read<ThemeProvider>().theme;
    final gold = const Color(0xFFD5C38B);
    final navy = const Color(0xFF1A3A5C);
    final accent = t.isNight ? gold : navy;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: const Color(0xFF065F46).withOpacity(0.35),
                  blurRadius: 18, spreadRadius: 2)],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            tr.isAmharic ? 'መልዕክቱ ተልኳል!' : 'Message Sent!',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: accent,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr.isAmharic
                ? 'መልዕክትዎ ለፖሊስ ቡድን ተልኳል። በቅርቡ ምላሽ ይሰጥዎታል።'
                : 'Your message has been sent to the police team. You will receive a response shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule_rounded, size: 13, color: accent),
              const SizedBox(width: 6),
              Text(
                tr.isAmharic ? 'ምላሽ በ 24 ሰዓት ውስጥ' : 'Response within 24 hours',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: accent),
              ),
            ]),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: t.isNight ? navy : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(tr.get('done'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    final t = context.read<ThemeProvider>().theme;
    final accent = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF1A3A5C);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('$text copied'),
        ]),
        backgroundColor: accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr    = context.watch<LanguageProvider>().tr;
    final t     = context.watch<ThemeProvider>().theme;
    final isAm  = tr.isAmharic;
    final gold  = const Color(0xFFD5C38B);
    final navy  = const Color(0xFF1A3A5C);
    final accent = t.isNight ? gold : navy;
    final iconBg = t.isNight
        ? const Color(0xFF1E3A5C)
        : const Color(0xFFD6E4F0);

    return Scaffold(
      backgroundColor: t.scaffoldBg,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor:
            t.isNight ? const Color(0xFF0F2744) : const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr.get('contact_us'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2)),
          Text(
            isAm ? 'ሀዋሳ ከተማ ፖሊስ ኮሚሽን' : 'Hawassa City Police Commission',
            style: TextStyle(
                fontSize: 11,
                color: gold.withOpacity(0.8),
                fontWeight: FontWeight.w500),
          ),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                gold.withOpacity(0.6),
                gold,
                gold.withOpacity(0.6),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Hero header ───────────────────────────────────────────
                _ContactHero(isAm: isAm, gold: gold, navy: navy, t: t),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Emergency numbers ─────────────────────────────────
                      _SectionLabel(
                        icon: Icons.emergency_rounded,
                        label: isAm ? 'አስቸኳይ ስልኮች' : 'Emergency Numbers',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _EmergencyTile(
                            number: '907',
                            label: isAm ? 'አስቸኳይ' : 'Emergency',
                            icon: Icons.emergency_outlined,
                            color: const Color(0xFFDC2626),
                            onCall: () => _launch('tel:907'),
                            onCopy: () => _copyToClipboard('907'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _EmergencyTile(
                            number: '991',
                            label: isAm ? 'ፖሊስ' : 'Police Line',
                            icon: Icons.local_police_outlined,
                            color: accent,
                            onCall: () => _launch('tel:991'),
                            onCopy: () => _copyToClipboard('991'),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Quick actions ─────────────────────────────────────
                      _SectionLabel(
                        icon: Icons.bolt_rounded,
                        label: isAm ? 'ፈጣን አድራሻ' : 'Quick Contact',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.email_outlined,
                            label: isAm ? 'ኢሜይል' : 'Email Us',
                            value: 'info@hawassapolice.gov.et',
                            color: const Color(0xFFD97706),
                            onTap: () => _launch(
                                'mailto:info@hawassapolice.gov.et'),
                            t: t,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.access_time_rounded,
                            label: isAm ? 'አገልግሎት ሰዓት' : 'Hours',
                            value: isAm ? '24 ሰዓት / 7 ቀን' : '24/7 Available',
                            color: const Color(0xFF059669),
                            onTap: null,
                            t: t,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Message form ──────────────────────────────────────
                      _SectionLabel(
                        icon: Icons.message_outlined,
                        label: isAm ? 'መልዕክት ላክ' : 'Send a Message',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),

                      Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: t.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: accent.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    t.isNight ? 0.15 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject
                              _FieldLabel(
                                  label: isAm ? 'ርዕስ' : 'Subject',
                                  required: true,
                                  accent: accent),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _subjectCtrl,
                                style: TextStyle(
                                    color: t.primaryText, fontSize: 14),
                                onTap: () =>
                                    setState(() => _activeField = 0),
                                decoration: _inputDeco(
                                  hint: isAm
                                      ? 'ለምሳሌ፦ አስተያየት፣ ጥያቄ...'
                                      : 'e.g. Feedback, Question...',
                                  t: t,
                                  accent: accent,
                                  icon: Icons.subject_rounded,
                                  isActive: _activeField == 0,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? (isAm ? 'ርዕስ ያስፈልጋል' : 'Subject is required')
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Message
                              _FieldLabel(
                                  label: isAm ? 'መልዕክት' : 'Message',
                                  required: true,
                                  accent: accent),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _messageCtrl,
                                maxLines: 5,
                                style: TextStyle(
                                    color: t.primaryText, fontSize: 14),
                                onTap: () =>
                                    setState(() => _activeField = 1),
                                decoration: _inputDeco(
                                  hint: isAm
                                      ? 'መልዕክትዎን እዚህ ይጻፉ...'
                                      : 'Write your message here...',
                                  t: t,
                                  accent: accent,
                                  icon: Icons.edit_note_rounded,
                                  isActive: _activeField == 1,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? (isAm ? 'መልዕክት ያስፈልጋል' : 'Message is required')
                                        : null,
                              ),
                              const SizedBox(height: 8),

                              // Char counter hint
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${_messageCtrl.text.length} chars',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: t.secondaryText
                                          .withOpacity(0.5)),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Privacy note
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: accent.withOpacity(0.12)),
                                ),
                                child: Row(children: [
                                  Icon(Icons.lock_outline_rounded,
                                      size: 14, color: accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isAm
                                          ? 'መልዕክትዎ ሚስጥራዊ ሆኖ ይቆያል'
                                          : 'Your message is kept strictly confidential',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: t.secondaryText,
                                          height: 1.4),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 18),

                              // Submit button
                              _SendButton(
                                sending: _sending,
                                onPressed: _sendMessage,
                                isAm: isAm,
                                t: t,
                                gold: gold,
                                navy: navy,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Office location ───────────────────────────────────
                      _SectionLabel(
                        icon: Icons.location_on_outlined,
                        label: isAm ? 'አድራሻ' : 'Our Location',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _LocationCard(
                          isAm: isAm, t: t, accent: accent, iconBg: iconBg),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required AppTheme t,
    required Color accent,
    required IconData icon,
    required bool isActive,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13, color: t.secondaryText.withOpacity(0.6)),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon,
              size: 18,
              color: isActive ? accent : accent.withOpacity(0.4)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: t.scaffoldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: t.isNight
                    ? const Color(0xFF2A5080)
                    : const Color(0xFFE2E8F0),
                width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: t.isNight
                    ? const Color(0xFF2A5080)
                    : const Color(0xFFE2E8F0),
                width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFFDC2626), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFDC2626), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _ContactHero extends StatelessWidget {
  final bool isAm;
  final Color gold, navy;
  final AppTheme t;
  const _ContactHero(
      {required this.isAm,
      required this.gold,
      required this.navy,
      required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.isNight
              ? [const Color(0xFF0F2744), const Color(0xFF1A3A5C)]
              : [const Color(0xFF1A3A5C), const Color(0xFF243B55)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -24,
          top: -24,
          child: Icon(Icons.headset_mic_rounded,
              size: 140, color: Colors.white.withOpacity(0.04)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Row(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.12),
                border: Border.all(color: gold.withOpacity(0.35), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: gold.withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 1)
                ],
              ),
              child: Icon(Icons.headset_mic_rounded, color: gold, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  isAm ? 'እናግዝዎ?' : 'How can we help?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isAm
                      ? 'ከፖሊስ ቡድናችን ጋር ይገናኙ'
                      : 'Get in touch with our police team',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: gold.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    isAm ? 'ምላሽ በ 24 ሰዓት ውስጥ' : 'Response within 24 hours',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: gold,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _SectionLabel(
      {required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: accent, size: 17),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: -0.2,
          )),
    ]);
  }
}

// ─── Emergency Tile ───────────────────────────────────────────────────────────

class _EmergencyTile extends StatelessWidget {
  final String number, label;
  final IconData icon;
  final Color color;
  final VoidCallback onCall, onCopy;
  const _EmergencyTile({
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
    required this.onCall,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(children: [
        // Top: call button
        GestureDetector(
          onTap: onCall,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 1)
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                number,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
        // Bottom: action row
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color.withOpacity(0.2))),
          ),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onCall,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.phone_rounded, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text('Call',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ]),
                ),
              ),
            ),
            Container(width: 1, height: 20, color: color.withOpacity(0.2)),
            Expanded(
              child: GestureDetector(
                onTap: onCopy,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.copy_rounded,
                        size: 14, color: color.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text('Copy',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color.withOpacity(0.7))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback? onTap;
  final AppTheme t;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.04),
                blurRadius: 6)
          ],
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: t.secondaryText,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (onTap != null)
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: color.withOpacity(0.5)),
        ]),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  final Color accent;
  const _FieldLabel(
      {required this.label,
      this.required = false,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent)),
      if (required) ...[
        const SizedBox(width: 3),
        Text('*',
            style: TextStyle(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w900,
                fontSize: 14)),
      ],
    ]);
  }
}

// ─── Send Button ──────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool sending, isAm;
  final VoidCallback onPressed;
  final AppTheme t;
  final Color gold, navy;
  const _SendButton({
    required this.sending,
    required this.isAm,
    required this.onPressed,
    required this.t,
    required this.gold,
    required this.navy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = t.isNight ? gold : navy;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: sending ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
          elevation: sending ? 0 : 3,
          shadowColor: navy.withOpacity(0.35),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled))
              return accent.withOpacity(0.4);
            return Colors.transparent;
          }),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: sending
                ? null
                : LinearGradient(
                    colors: t.isNight
                        ? [
                            const Color(0xFFD5C38B),
                            const Color(0xFFC4AE6A)
                          ]
                        : [
                            const Color(0xFF1A3A5C),
                            const Color(0xFF243B55)
                          ],
                  ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Container(
            alignment: Alignment.center,
            child: sending
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: t.isNight ? navy : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(Icons.send_rounded,
                            size: 14,
                            color:
                                t.isNight ? navy : Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAm ? 'መልዕክት ላክ' : 'Send Message',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: t.isNight ? navy : Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Location Card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final bool isAm;
  final AppTheme t;
  final Color accent, iconBg;
  const _LocationCard(
      {required this.isAm,
      required this.t,
      required this.accent,
      required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
              color:
                  Colors.black.withOpacity(t.isNight ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.location_on_rounded, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              isAm ? 'ዋና መ/ቤት' : 'Headquarters',
              style: TextStyle(
                  fontSize: 12,
                  color: t.secondaryText,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              isAm
                  ? 'ሀዋሳ ከተማ ፖሊስ ኮሚሽን\nሀዋሳ፣ ሲዳማ ክልል፣ ኢትዮጵያ'
                  : 'Hawassa City Police Commission\nHawassa, Sidama Region, Ethiopia',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  height: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: accent.withOpacity(0.15), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.map_outlined, size: 13, color: accent),
                const SizedBox(width: 5),
                Text(
                  isAm ? 'ካርታ ላይ ይመልከቱ' : 'View on Map',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}