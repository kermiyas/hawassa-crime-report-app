// lib/screens/account/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr     = context.watch<LanguageProvider>().tr;
    final t      = context.watch<ThemeProvider>().theme;
    final isAm   = tr.isAmharic;
    final gold   = const Color(0xFFD5C38B);
    final navy   = const Color(0xFF1A3A5C);
    final accent = t.isNight ? gold : navy;
    final iconBg = t.isNight ? const Color(0xFF1E3A5C) : const Color(0xFFD6E4F0);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      // ── AppBar ──────────────────────────────────────────────────────────
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
        title: Text(
          tr.get('about_us'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
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

                // ── Hero Banner ──────────────────────────────────────────
                _HeroBanner(isAm: isAm, gold: gold, navy: navy, t: t),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── About & Mission ──────────────────────────────────
                      _SectionTitle(
                        icon: Icons.info_outline_rounded,
                        label: isAm ? 'ስለ መተግበሪያው' : 'About the App',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.shield_outlined,
                        title: isAm ? 'ምንድን ነው?' : 'What is this app?',
                        body: isAm
                            ? 'የሀዋሳ ወንጀል ሪፖርት መተግበሪያ ዜጎችን ከፖሊስ ጋር የሚያገናኝ ዘመናዊ ዲጂታል መድረክ ነው። ዜጎች ወንጀሎችን ሪፖርት ማድረግ፣ ሪፖርቶቻቸውን መከታተል፣ የፖሊስ ማስጠንቀቂያዎችን ማየት እና ቀጥታ ግንኙነት ማድረግ ይችላሉ።'
                            : 'A modern digital platform connecting Hawassa citizens with the police. Citizens can report crimes, track their reports, view police alerts for wanted and missing persons, and receive direct updates from law enforcement.',
                        t: t, accent: accent, iconBg: iconBg,
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.flag_outlined,
                        title: isAm ? 'ተልዕኮአችን' : 'Our Mission',
                        body: isAm
                            ? 'ዜጎችን በቀላሉ ወንጀልን ሪፖርት እንዲያደርጉ፣ ፖሊስ ደግሞ ፈጣን እርምጃ እንዲወስድ በማስቻል የሀዋሳ ከተማን ደህንነት ማሳደግ። ቴክኖሎጂን በመጠቀም ዜጎችን ከፖሊስ ጋር ቅርብ ለማድረግ ቁርጠኛ ነን።'
                            : 'To enhance public safety in Hawassa City by empowering citizens to easily report crimes and enabling police to respond swiftly. We are committed to bridging the gap between citizens and law enforcement through technology.',
                        t: t, accent: accent, iconBg: iconBg,
                      ),

                      const SizedBox(height: 24),

                      // ── Feature highlights ───────────────────────────────
                      _SectionTitle(
                        icon: Icons.star_outline_rounded,
                        label: isAm ? 'ዋና ባህሪያት' : 'Key Features',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _FeaturesGrid(isAm: isAm, t: t, accent: accent, gold: gold, navy: navy),

                      const SizedBox(height: 24),

                      // ── Police Contact ───────────────────────────────────
                      _SectionTitle(
                        icon: Icons.local_police_outlined,
                        label: isAm ? 'የፖሊስ አድራሻ' : 'Police Contact',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _ContactCard(
                        icon: Icons.location_on_outlined,
                        label: isAm ? 'ዋና መ/ቤት' : 'Headquarters',
                        value: isAm
                            ? 'ሀዋሳ ከተማ ፖሊስ ኮሚሽን\nሀዋሳ፣ ሲዳማ ክልል፣ ኢትዮጵያ'
                            : 'Hawassa City Police Commission\nHawassa, Sidama Region, Ethiopia',
                        t: t, accent: accent, iconBg: iconBg,
                        copyable: false,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: _ContactCard(
                            icon: Icons.emergency_outlined,
                            label: isAm ? 'አስቸኳይ' : 'Emergency',
                            value: '907',
                            t: t, accent: const Color(0xFFDC2626),
                            iconBg: const Color(0xFFDC2626).withOpacity(0.1),
                            copyable: true,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ContactCard(
                            icon: Icons.phone_in_talk_outlined,
                            label: isAm ? 'የፖሊስ ስልክ' : 'Police Line',
                            value: '991',
                            t: t, accent: accent, iconBg: iconBg,
                            copyable: true,
                            compact: true,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      _ContactCard(
                        icon: Icons.access_time_rounded,
                        label: isAm ? 'አገልግሎት ሰዓት' : 'Service Hours',
                        value: isAm ? '24 ሰዓት / 7 ቀን' : '24 Hours / 7 Days a Week',
                        t: t, accent: accent, iconBg: iconBg,
                        copyable: false,
                      ),

                      const SizedBox(height: 24),

                      // ── Developer ────────────────────────────────────────
                      _SectionTitle(
                        icon: Icons.code_rounded,
                        label: isAm ? 'ስለ ገንቢው ቡድን' : 'Developer & Team',
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.developer_mode_outlined,
                        title: isAm ? 'ቴክኒካዊ ቡድን' : 'Technical Team',
                        body: isAm
                            ? 'ይህ መተግበሪያ ለሀዋሳ ከተማ ፖሊስ ኮሚሽን በሶፍትዌር ምህንድስና ቡድን የተገነባ ነው። Flutter (ሞባይል) እና Laravel (ባክ ኤንድ) ቴክኖሎጂዎችን በመጠቀም ተሰርቷል።'
                            : 'Built for the Hawassa City Police Commission by a dedicated software engineering team using Flutter for the mobile frontend and Laravel 12 for the backend REST API.',
                        t: t, accent: accent, iconBg: iconBg,
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.bug_report_outlined,
                        title: isAm ? 'ችግር ሪፖርት' : 'Report a Bug',
                        body: isAm
                            ? 'ቴክኒካዊ ችግር ካጋጥምዎ ወይም አስተያየት ካለዎ፣ እባክዎ ወደ "ያግኙን" ክፍል ሄደው ያሳውቁን።'
                            : 'If you encounter any technical issues or have feedback, please use the Contact Us section. Your reports help us improve the app for everyone.',
                        t: t, accent: accent, iconBg: iconBg,
                      ),

                      const SizedBox(height: 28),


                      const SizedBox(height: 24),

                      // ── Footer ───────────────────────────────────────────
                      _Footer(isAm: isAm, t: t, accent: accent, gold: gold),

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
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final bool isAm;
  final Color gold, navy;
  final AppTheme t;
  const _HeroBanner(
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
        // Background pattern — subtle shield watermark
        Positioned(
          right: -20,
          top: -20,
          child: Icon(Icons.shield_rounded,
              size: 160,
              color: Colors.white.withOpacity(0.04)),
        ),
        Positioned(
          left: -30,
          bottom: -30,
          child: Icon(Icons.shield_rounded,
              size: 120,
              color: Colors.white.withOpacity(0.03)),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(children: [
            // Badge
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  gold.withOpacity(0.25),
                  gold.withOpacity(0.08),
                ]),
                border: Border.all(color: gold.withOpacity(0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.shield_rounded, color: gold, size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              isAm ? 'የሀዋሳ ወንጀል ሪፖርት' : 'Hawassa Crime Report',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isAm ? 'ሀዋሳ ከተማ ፖሊስ ኮሚሽን ይፋዊ መተግበሪያ'
                   : 'Official App — Hawassa City Police Commission',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Version + build
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Pill(label: 'v1.0.0', gold: gold, navy: navy),
              const SizedBox(width: 8),
              
              _Pill(label: '2026', gold: gold, navy: navy),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color gold, navy;
  const _Pill({required this.label, required this.gold, required this.navy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: gold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _SectionTitle(
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
      Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: accent,
          letterSpacing: -0.2,
        ),
      ),
    ]);
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final AppTheme t;
  final Color accent, iconBg;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.t,
    required this.accent,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accent.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                )),
            const SizedBox(height: 6),
            Text(body,
                style: TextStyle(
                  fontSize: 13,
                  color: t.primaryText,
                  height: 1.6,
                )),
          ]),
        ),
      ]),
    );
  }
}

// ─── Contact Card ─────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final AppTheme t;
  final Color accent, iconBg;
  final bool copyable, compact;
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.t,
    required this.accent,
    required this.iconBg,
    this.copyable = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.copy_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('$value copied'),
                  ]),
                  backgroundColor: accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      child: Container(
        padding: compact
            ? const EdgeInsets.all(14)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.secondaryText,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Row(children: [
                  Text(value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: -0.5,
                      )),
                  const Spacer(),
                  if (copyable)
                    Icon(Icons.copy_rounded,
                        size: 14,
                        color: accent.withOpacity(0.5)),
                ]),
              ])
            : Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: TextStyle(
                          fontSize: 11,
                          color: t.secondaryText,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                          fontSize: 14,
                          color: accent,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        )),
                  ]),
                ),
                if (copyable)
                  Icon(Icons.copy_rounded,
                      size: 16, color: accent.withOpacity(0.4)),
              ]),
      ),
    );
  }
}

// ─── Features Grid ────────────────────────────────────────────────────────────

class _FeaturesGrid extends StatelessWidget {
  final bool isAm;
  final AppTheme t;
  final Color accent, gold, navy;
  const _FeaturesGrid(
      {required this.isAm,
      required this.t,
      required this.accent,
      required this.gold,
      required this.navy});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.report_outlined,
          isAm ? 'ወንጀል ሪፖርት' : 'Crime Reports',
          isAm ? 'ስም ሳይገለጽ ሪፖርት' : 'Anonymous reporting'),
      (Icons.notifications_outlined,
          isAm ? 'ማስጠንቀቂያዎች' : 'Live Alerts',
          isAm ? 'የፖሊስ ማስጠንቀቂያ' : 'Wanted & missing'),
      (Icons.track_changes_outlined,
          isAm ? 'ሪፖርት ክትትል' : 'Track Reports',
          isAm ? 'ሁናቴ ክትትል' : 'Real-time status'),
      (Icons.lock_outline_rounded,
          isAm ? 'ሚስጥራዊነት' : 'Confidential',
          isAm ? 'ሙሉ ጥበቃ' : 'Full privacy'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: features
          .map((f) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: accent.withOpacity(0.1), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(t.isNight ? 0.15 : 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(f.$1, color: accent, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(f.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          )),
                      const SizedBox(height: 2),
                      Text(f.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: t.secondaryText,
                            height: 1.4,
                          )),
                    ]),
                  ),
                ]),
              ))
          .toList(),
    );
  }
}



// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isAm;
  final AppTheme t;
  final Color accent, gold;
  const _Footer(
      {required this.isAm,
      required this.t,
      required this.accent,
      required this.gold});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.2), width: 1.5),
          ),
          child: Icon(Icons.shield_rounded, color: accent, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          isAm
              ? '© 2026 የሀዋሳ ከተማ ፖሊስ ኮሚሽን'
              : '© 2026 Hawassa City Police Commission',
          style: TextStyle(
            fontSize: 12,
            color: t.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAm ? 'ሁሉም መብቶች የተጠበቁ ናቸው።' : 'All rights reserved.',
          style: TextStyle(fontSize: 11, color: t.secondaryText),
        ),
        const SizedBox(height: 8),
        // Decorative divider
        Container(
          height: 1,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              accent.withOpacity(0.3),
              Colors.transparent,
            ]),
          ),
        ),
      ]),
    );
  }
}