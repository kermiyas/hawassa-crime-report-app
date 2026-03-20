// lib/screens/account/about_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr          = context.watch<LanguageProvider>().tr;
    final t           = context.watch<ThemeProvider>().theme;
    final isAm        = tr.isAmharic;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    final iconBg      = t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFD6E4F0);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text(tr.get('about_us'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: t.appBarTextColor)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── App logo + version ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: t.isNight
                        ? const Color(0xFF1A3A5C).withOpacity(0.15)
                        : Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_rounded,
                      color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                      size: 46),
                ),
                const SizedBox(height: 16),
                Text(
                  isAm ? 'የሀዋሳ ወንጀል ሪፖርት' : 'Hawassa Crime Report',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.isNight
                        ? const Color(0xFF1A3A5C).withOpacity(0.15)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Version 1.0.0',
                      style: TextStyle(
                          color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                          fontSize: 13)),
                ),
                const SizedBox(height: 12),
                Text(
                  isAm ? 'ሀዋሳ ከተማ ፖሊስ ይፋዊ መተግበሪያ'
                       : 'Official App of Hawassa City Police',
                  style: TextStyle(
                      color: t.isNight
                          ? const Color(0xFF1A3A5C).withOpacity(0.7)
                          : Colors.white70,
                      fontSize: 13),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Description ─────────────────────────────────────────────
            _card(
              icon: Icons.info_outline,
              title: isAm ? 'ስለ መተግበሪያው' : 'About the App',
              body: isAm
                  ? 'የሀዋሳ ወንጀል ሪፖርት መተግበሪያ የሀዋሳ ዜጎችን ከፖሊስ ጋር የሚያገናኝ ዘመናዊ ዲጂታል መድረክ ነው። ዜጎች ወንጀሎችን ሪፖርት ማድረግ፣ ሪፖርቶቻቸውን መከታተል፣ የፖሊስ ማስጠንቀቂያዎችን ማየት እና ከፖሊስ ቀጥታ ግንኙነት ማድረግ ይችላሉ። መተግበሪያው ሁሉም ሪፖርቶችን ሚስጥራዊ ሆኖ እንዲቆዩ ያደርጋል።'
                  : 'The Hawassa Crime Report app is a modern digital platform connecting Hawassa citizens with the police. Citizens can report crimes, track their reports, view police alerts for wanted and missing persons, and receive direct updates from law enforcement. All reports are handled with strict confidentiality.',
              t: t, accentColor: accentColor, iconBg: iconBg,
            ),
            const SizedBox(height: 12),

            // ── Mission ──────────────────────────────────────────────────
            _card(
              icon: Icons.flag_outlined,
              title: isAm ? 'ተልዕኮአችን' : 'Our Mission',
              body: isAm
                  ? 'ዜጎችን በቀላሉ ወንጀልን ሪፖርት እንዲያደርጉ፣ ፖሊስ ደግሞ ፈጣን እርምጃ እንዲወስድ በማስቻል የሀዋሳ ከተማን ደህንነት ማሳደግ። ቴክኖሎጂን በመጠቀም ዜጎችን ከፖሊስ ጋር ቅርብ ለማድረግ እና ለሁሉም ዜጎች ደህንነቱ የተጠበቀ ከተማ ለመፍጠር ቁርጠኛ ነን።'
                  : 'To enhance public safety in Hawassa City by empowering citizens to easily report crimes and enabling police to respond swiftly. We are committed to bridging the gap between citizens and law enforcement through technology, creating a safer city for everyone.',
              t: t, accentColor: accentColor, iconBg: iconBg,
            ),
            const SizedBox(height: 20),

            // ── Police contact ───────────────────────────────────────────
            _sectionTitle(
                isAm ? 'የፖሊስ አድራሻ' : 'Police Contact Information',
                Icons.local_police_outlined, accentColor),
            const SizedBox(height: 12),
            _contactCard(Icons.location_on_outlined,
                isAm ? 'ዋና መ/ቤት' : 'Headquarters',
                isAm ? 'ሀዋሳ ከተማ ፖሊስ ኮሚሽን\nሀዋሳ፣ ሲዳማ ክልል፣ ኢትዮጵያ'
                     : 'Hawassa City Police Commission\nHawassa, Sidama Region, Ethiopia',
                t, accentColor, iconBg),
            const SizedBox(height: 10),
            _contactCard(Icons.phone_outlined,
                isAm ? 'አስቸኳይ ስልክ' : 'Emergency Line', '907',
                t, accentColor, iconBg),
            const SizedBox(height: 10),
            _contactCard(Icons.phone_in_talk_outlined,
                isAm ? 'የፖሊስ ስልክ' : 'Police Line', '991',
                t, accentColor, iconBg),
            const SizedBox(height: 10),
            _contactCard(Icons.access_time_outlined,
                isAm ? 'አገልግሎት ሰዓት' : 'Service Hours',
                isAm ? '24 ሰዓት / 7 ቀን' : '24 Hours / 7 Days a Week',
                t, accentColor, iconBg),
            const SizedBox(height: 20),

            // ── Developer ────────────────────────────────────────────────
            _sectionTitle(
                isAm ? 'ስለ ገንቢው ቡድን' : 'Developer & Team',
                Icons.code_outlined, accentColor),
            const SizedBox(height: 12),
            _card(
              icon: Icons.developer_mode_outlined,
              title: isAm ? 'ቴክኒካዊ ቡድን' : 'Technical Team',
              body: isAm
                  ? 'ይህ መተግበሪያ ለሀዋሳ ከተማ ፖሊስ ኮሚሽን በሶፍትዌር ምህንድስና ቡድን የተገነባ ነው። Flutter (ሞባይል) እና Laravel (ባክ ኤንድ) ቴክኖሎጂዎችን በመጠቀም ተሰርቷል።'
                  : 'This application was developed for the Hawassa City Police Commission by a dedicated software engineering team. Built using Flutter for the mobile frontend and Laravel for the backend API.',
              t: t, accentColor: accentColor, iconBg: iconBg,
            ),
            const SizedBox(height: 10),
            _card(
              icon: Icons.bug_report_outlined,
              title: isAm ? 'ችግር ሪፖርት' : 'Report a Bug',
              body: isAm
                  ? 'ቴክኒካዊ ችግር ካጋጥምዎ ወይም አስተያየት ካለዎ፣ እባክዎ ወደ "ያግኙን" ክፍል ሄደው ያሳውቁን። ሪፖርቶዎ መተግበሪያውን ለሁሉም ያሻሽለዋል።'
                  : 'If you encounter any technical issues or have feedback, please use the Contact Us section to let us know. Your reports help us improve the app for everyone.',
              t: t, accentColor: accentColor, iconBg: iconBg,
            ),
            const SizedBox(height: 20),

            // ── Footer ───────────────────────────────────────────────────
            Center(
              child: Column(children: [
                Icon(Icons.shield_rounded, color: accentColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  isAm ? '© 2026 የሀዋሳ ከተማ ፖሊስ ኮሚሽን'
                       : '© 2026 Hawassa City Police Commission',
                  style: TextStyle(fontSize: 12, color: t.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  isAm ? 'ሁሉም መብቶች የተጠበቁ ናቸው።' : 'All rights reserved.',
                  style: TextStyle(fontSize: 11, color: t.secondaryText),
                ),
              ]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color accentColor) =>
      Row(children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: accentColor)),
      ]);

  Widget _card({
    required IconData icon,
    required String title,
    required String body,
    required AppTheme t,
    required Color accentColor,
    required Color iconBg,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.04),
              blurRadius: 6)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: accentColor)),
            const SizedBox(height: 6),
            Text(body, style: TextStyle(
                fontSize: 13, color: t.primaryText, height: 1.6)),
          ])),
        ]),
      );

  Widget _contactCard(IconData icon, String label, String value,
      AppTheme t, Color accentColor, Color iconBg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.04),
              blurRadius: 6)],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
                fontSize: 12, color: t.secondaryText, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(
                fontSize: 14, color: accentColor, fontWeight: FontWeight.w700)),
          ])),
        ]),
      );
}