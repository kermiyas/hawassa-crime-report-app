// lib/screens/account/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

const _kNavy    = Color(0xFF0D1B2A);
const _kNavyMid = Color(0xFF1A3A5C);
const _kGold    = Color(0xFFC9A84C);
const _kGreen   = Color(0xFF2E7D32);

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr   = context.watch<LanguageProvider>().tr;
    final t    = context.watch<ThemeProvider>().theme;
    final isAm = tr.isAmharic;
    final accent = t.isNight ? _kGold : _kNavyMid;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: Column(children: [

        // ── Navy gradient header ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.isNight
                  ? [const Color(0xFF1A2F4A), _kNavy]
                  : [_kNavy, _kNavyMid],
            ),
            boxShadow: [BoxShadow(color: _kNavy.withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tr.get('terms_privacy'),
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: Colors.white,
                          letterSpacing: 0.3))),
                ]),
              ),

              // Hero banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGold.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _kGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGold.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.shield_rounded, color: _kGold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAm
                            ? 'ውሎች፣ ደንቦች እና የግላዊነት ፖሊሲ'
                            : 'Terms, Conditions & Privacy Policy',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAm
                            ? 'መጨረሻ ጊዜ የተሻሻለው፦ መጋቢት 2026'
                            : 'Last updated: March 2026',
                        style: TextStyle(fontSize: 11,
                            color: Colors.white.withOpacity(0.65)),
                      ),
                    ],
                  )),
                ]),
              ),
            ]),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (isAm) ..._buildAmharic(t, accent)
                else      ..._buildEnglish(t, accent),

                const SizedBox(height: 8),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: t.isNight
                          ? [_kGreen.withOpacity(0.15), _kGreen.withOpacity(0.05)]
                          : [_kGreen.withOpacity(0.08), _kGreen.withOpacity(0.03)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGreen.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user_rounded,
                            color: _kGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        isAm
                            ? 'ይህ መተግበሪያ ለሀዋሳ ከተማ ፖሊስ ሪፖርት ዓላማ ብቻ ነው። ሁሉም ሪፖርቶች በምስጢር ይያዛሉ።'
                            : 'This app is operated for the Hawassa City Police reporting purposes only. All reports are handled confidentially.',
                        style: TextStyle(fontSize: 13,
                            color: t.isNight
                                ? const Color(0xFF6EE7B7)
                                : _kGreen,
                            height: 1.5, fontWeight: FontWeight.w600),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildEnglish(AppTheme t, Color accent) => [
    _section('1. Acceptance of Terms', Icons.handshake_outlined,
        'By downloading and using the Hawassa Crime Report application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.', t, accent),
    _section('2. Purpose of the App', Icons.info_outline_rounded,
        'This application is designed to allow citizens of Hawassa City to report crimes, view public safety alerts, and communicate with law enforcement. It is not an emergency response service. For emergencies, call 911 or Police line 8 immediately.', t, accent),
    _section('3. User Responsibilities', Icons.person_outline_rounded,
        'You agree to provide accurate and truthful information when submitting reports. Filing false reports is a criminal offense under Ethiopian law and may result in legal action. You must be at least 18 years old to create an account.', t, accent),
    _section('4. Account Security', Icons.lock_outline_rounded,
        'You are responsible for maintaining the confidentiality of your account credentials. Do not share your password with anyone. Notify us immediately if you suspect unauthorized access to your account.', t, accent),
    _section('5. Report Submission', Icons.assignment_outlined,
        'Reports submitted through this app are received by the Hawassa City Police. By submitting a report, you consent to your information being reviewed by authorized law enforcement personnel. Anonymous reporting is available but may limit the ability of police to follow up with you.', t, accent),
    _section('6. Evidence Uploads', Icons.upload_file_outlined,
        'You may upload photos, videos, and audio recordings as evidence. You must own the rights to any files you upload or have consent from all parties. Do not upload content that is illegal, defamatory, or violates the privacy of others.', t, accent),
    _section('7. Privacy Policy — Data We Collect', Icons.privacy_tip_outlined,
        'We collect the following information: full name, email address, phone number, profile photo (optional), location data when submitting reports, and evidence files you upload. We do not sell your personal data to third parties.', t, accent),
    _section('8. How We Use Your Data', Icons.manage_search_rounded,
        'Your data is used exclusively to facilitate crime reporting and communication between citizens and the Hawassa City Police. Report details and evidence are accessible only to authorized law enforcement officers. Your contact details are kept confidential from the public.', t, accent),
    _section('9. Data Storage & Security', Icons.storage_rounded,
        'All data is stored securely on servers operated by the Hawassa City Administration. We use industry-standard encryption to protect your information. We retain your data for as long as it is needed for law enforcement purposes or as required by law.', t, accent),
    _section('10. Notifications', Icons.notifications_outlined,
        'By using this app, you consent to receiving in-app notifications regarding your report status and important public safety alerts. You may manage notification preferences in your device settings.', t, accent),
    _section('11. Prohibited Uses', Icons.block_rounded,
        'You may not use this app to submit false reports, harass or defame individuals, share illegal content, attempt to access other users\' data, or interfere with the operation of the app or police services.', t, accent),
    _section('12. Limitation of Liability', Icons.gavel_rounded,
        'The Hawassa City Police and the app administrators are not liable for any loss or damage arising from your use of the app, delays in police response, or inaccuracies in public alert information. This app is provided "as is" without warranty of any kind.', t, accent),
    _section('13. Changes to Terms', Icons.edit_note_rounded,
        'We reserve the right to modify these terms at any time. Continued use of the app after changes are posted constitutes your acceptance of the new terms. We will notify users of significant changes via the app.', t, accent),
    _section('14. Contact', Icons.contact_support_outlined,
        'If you have questions about these terms or your privacy, please contact the Hawassa City Police digital services office or use the Contact Us option in the app.', t, accent),
  ];

  List<Widget> _buildAmharic(AppTheme t, Color accent) => [
    _section('1. ውሎችን መቀበል', Icons.handshake_outlined,
        'የሀዋሳ ወንጀል ሪፖርት መተግበሪያን በማውረድ እና በመጠቀም ይህንን ውሎች እና ደንቦች መቀበልዎን ያረጋግጣሉ። ካልተስማሙ፣ እባክዎ መተግበሪያውን አይጠቀሙ።', t, accent),
    _section('2. የመተግበሪያው ዓላማ', Icons.info_outline_rounded,
        'ይህ መተግበሪያ የሀዋሳ ከተማ ዜጎች ወንጀሎችን ሪፖርት እንዲያደርጉ፣ የህዝብ ደህንነት ማስጠንቀቂያዎችን እንዲያዩ እና ከፖሊስ ጋር ለመገናኘት የተዘጋጀ ነው። ይህ አስቸኳይ ምላሽ አገልግሎት አይደለም።', t, accent),
    _section('3. የተጠቃሚ ኃላፊነቶች', Icons.person_outline_rounded,
        'ሪፖርት ሲያስገቡ ትክክለኛ እና እውነተኛ መረጃ መስጠትዎን ይስማማሉ። ሐሰተኛ ሪፖርቶችን ማቅረብ በኢትዮጵያ ሕግ ወንጀል ሲሆን ሕጋዊ እርምጃ ሊያስከትል ይችላል።', t, accent),
    _section('4. የመለያ ደህንነት', Icons.lock_outline_rounded,
        'የመለያዎን ምስጢር መጠበቅ ኃላፊነትዎ ነው። የይለፍ ቃልዎን ለማንም አያጋሩ። ያልተፈቀደ ሰው ወደ መለያዎ ለመግባት ሞክሯል ብለው ካሰቡ ወዲያውኑ ያሳውቁን።', t, accent),
    _section('5. ሪፖርቶችን ማስገባት', Icons.assignment_outlined,
        'በዚህ መተግበሪያ የሚቀርቡ ሪፖርቶች የሀዋሳ ከተማ ፖሊስ ይቀበላቸዋል። ሪፖርት በማስገባት የእርስዎ መረጃ በፈቃደኛ ሕግ አስፈጻሚ ባለሙያዎች እንዲታይ ይፈቅዳሉ።', t, accent),
    _section('6. ማስረጃ መስቀል', Icons.upload_file_outlined,
        'ፎቶዎችን፣ ቪዲዮዎችን እና ድምጽ ቀረጻዎችን ማስረጃ ሆነው ሊሰቅሉ ይችላሉ። ሕገ ወጥ፣ ስም አጥፊ ወይም የሌሎችን ግላዊነት የሚጥስ ይዘት አይሰቅሉ።', t, accent),
    _section('7. የምንሰበሰበው ውሂብ', Icons.privacy_tip_outlined,
        'የሚከተሉትን መረጃዎች እንሰበስባለን፦ ሙሉ ስም፣ ኢሜይል አድራሻ፣ ስልክ ቁጥር፣ የፕሮፋይል ፎቶ (አማራጭ)፣ ሪፖርቶችን ሲያስገቡ የቦታ ውሂብ። የእርስዎን ውሂብ ለሶስተኛ ወገኖች አንሸጥም።', t, accent),
    _section('8. ውሂብዎን እንዴት እንጠቀምበታለን', Icons.manage_search_rounded,
        'ውሂብዎ ወንጀል ሪፖርት ማድረጉን እና በዜጎች እና የሀዋሳ ከተማ ፖሊስ መካከል ያለውን ግንኙነት ለማመቻቸት ብቻ ጥቅም ላይ ይውላል።', t, accent),
    _section('9. ውሂብ ማከማቸት እና ደህንነት', Icons.storage_rounded,
        'ሁሉም ውሂብ በሀዋሳ ከተማ አስተዳደር ሰርቨሮች ላይ ደህንነቱ ተጠብቆ ይቀመጣል። መረጃዎን ለመጠበቅ የኢንዱስትሪ ደረጃ ምስጠራ እንጠቀማለን።', t, accent),
    _section('10. ማሳወቂያዎች', Icons.notifications_outlined,
        'ይህን መተግበሪያ በመጠቀም ስለ ሪፖርትዎ ሁኔታ እና አስፈላጊ የህዝብ ደህንነት ማስጠንቀቂያዎች የመተግበሪያ ማሳወቂያዎችን ለመቀበል ይስማማሉ።', t, accent),
    _section('11. የተከለከሉ አጠቃቀሞች', Icons.block_rounded,
        'ሐሰተኛ ሪፖርቶችን ለማስገባት፣ ሰዎችን ለማሸማቀቅ፣ ሕገ ወጥ ይዘት ለማጋራት ወይም የፖሊስ አገልግሎቶችን ሥራ ለማስተጓጎል ይህን መተግበሪያ መጠቀም አይፈቀድም።', t, accent),
    _section('12. የኃላፊነት ገደብ', Icons.gavel_rounded,
        'የሀዋሳ ከተማ ፖሊስ እና የመተግበሪያ አስተዳዳሪዎች ከመተግበሪያው አጠቃቀም ለሚመጣ ማናቸውም ኪሳራ ተጠያቂ አይሆኑም።', t, accent),
    _section('13. ለውጦች', Icons.edit_note_rounded,
        'እነዚህን ውሎች በማንኛውም ጊዜ ማሻሻል የሚችሉበት መብት ይጠበቅልናል። ለውጦች ከተለጠፉ በኋላ መተግበሪያውን መቀጠል አዲሱን ውሎች እንደተቀበሉ ይቆጠራል።', t, accent),
    _section('14. አድራሻ', Icons.contact_support_outlined,
        'ስለ እነዚህ ውሎች ወይም ምስጢርዎ ጥያቄ ካለዎት፣ እባክዎ የሀዋሳ ከተማ ፖሊስ ዲጂታል አገልግሎቶች ቢሮን ያግኙ ወይም በመተግበሪያው ውስጥ ያለውን "ያግኙን" አማራጭ ይጠቀሙ።', t, accent),
  ];

  Widget _section(String title, IconData icon, String body,
      AppTheme t, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              border: Border(bottom: BorderSide(color: t.dividerColor)),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: accent))),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(body,
                style: TextStyle(fontSize: 13, color: t.primaryText,
                    height: 1.65)),
          ),
        ]),
      ),
    );
  }
}