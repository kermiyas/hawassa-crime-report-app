// lib/screens/account/terms_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: Text(tr.get('terms_privacy'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: t.appBarTextColor)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
              color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Icon(Icons.gavel_rounded,
    color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
    size: 36),
                  const SizedBox(height: 12),
                  Text(
                    isAm ? 'ውሎች፣ ደንቦች እና የግላዊነት ፖሊሲ'
                         : 'Terms, Conditions & Privacy Policy',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                       color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAm ? 'የሀዋሳ ወንጀል ሪፖርት መተግበሪያ — መጨረሻ ጊዜ የተሻሻለው፦ መጋቢት 2026'
                         : 'Hawassa Crime Report App — Last updated: March 2026',
                    style: TextStyle(fontSize: 12, color: t.isNight ? const Color(0xFF1A3A5C).withOpacity(0.7) : Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isAm) ..._buildAmharic(t, accentColor)
            else      ..._buildEnglish(t, accentColor),

            const SizedBox(height: 24),

            // Footer — always green (readable in both modes)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.isNight
                    ? const Color(0xFF065F46).withOpacity(0.2)
                    : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: t.isNight
                        ? const Color(0xFF065F46).withOpacity(0.4)
                        : const Color(0xFF86EFAC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: Color(0xFF065F46), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAm
                          ? 'ይህ መተግበሪያ ለሀዋሳ ከተማ ፖሊስ ሪፖርት ዓላማ ብቻ ነው። ሁሉም ሪፖርቶች በምስጢር ይያዛሉ።'
                          : 'This app is operated for the Hawassa City Police reporting purposes only. All reports are handled confidentially.',
                      style: TextStyle(
                          fontSize: 13,
                          color: t.isNight
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF065F46),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnglish(AppTheme t, Color accentColor) => [
    _section('1. Acceptance of Terms',
        'By downloading and using the Hawassa Crime Report application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.', t, accentColor),
    _section('2. Purpose of the App',
        'This application is designed to allow citizens of Hawassa City to report crimes, view public safety alerts, and communicate with law enforcement. It is not an emergency response service. For emergencies, call 911 or Police line 8 immediately.', t, accentColor),
    _section('3. User Responsibilities',
        'You agree to provide accurate and truthful information when submitting reports. Filing false reports is a criminal offense under Ethiopian law and may result in legal action. You must be at least 18 years old to create an account.', t, accentColor),
    _section('4. Account Security',
        'You are responsible for maintaining the confidentiality of your account credentials. Do not share your password with anyone. Notify us immediately if you suspect unauthorized access to your account.', t, accentColor),
    _section('5. Report Submission',
        'Reports submitted through this app are received by the Hawassa City Police. By submitting a report, you consent to your information being reviewed by authorized law enforcement personnel. Anonymous reporting is available but may limit the ability of police to follow up with you.', t, accentColor),
    _section('6. Evidence Uploads',
        'You may upload photos, videos, and audio recordings as evidence. You must own the rights to any files you upload or have consent from all parties. Do not upload content that is illegal, defamatory, or violates the privacy of others.', t, accentColor),
    _section('7. Privacy Policy — Data We Collect',
        'We collect the following information: full name, email address, phone number, profile photo (optional), location data when submitting reports, and evidence files you upload. We do not sell your personal data to third parties.', t, accentColor),
    _section('8. How We Use Your Data',
        'Your data is used exclusively to facilitate crime reporting and communication between citizens and the Hawassa City Police. Report details and evidence are accessible only to authorized law enforcement officers. Your contact details are kept confidential from the public.', t, accentColor),
    _section('9. Data Storage & Security',
        'All data is stored securely on servers operated by the Hawassa City Administration. We use industry-standard encryption to protect your information. We retain your data for as long as it is needed for law enforcement purposes or as required by law.', t, accentColor),
    _section('10. Notifications',
        'By using this app, you consent to receiving in-app notifications regarding your report status and important public safety alerts. You may manage notification preferences in your device settings.', t, accentColor),
    _section('11. Prohibited Uses',
        'You may not use this app to submit false reports, harass or defame individuals, share illegal content, attempt to access other users\' data, or interfere with the operation of the app or police services.', t, accentColor),
    _section('12. Limitation of Liability',
        'The Hawassa City Police and the app administrators are not liable for any loss or damage arising from your use of the app, delays in police response, or inaccuracies in public alert information. This app is provided "as is" without warranty of any kind.', t, accentColor),
    _section('13. Changes to Terms',
        'We reserve the right to modify these terms at any time. Continued use of the app after changes are posted constitutes your acceptance of the new terms. We will notify users of significant changes via the app.', t, accentColor),
    _section('14. Contact',
        'If you have questions about these terms or your privacy, please contact the Hawassa City Police digital services office or use the Contact Us option in the app.', t, accentColor),
  ];

  List<Widget> _buildAmharic(AppTheme t, Color accentColor) => [
    _section('1. ውሎችን መቀበል',
        'የሀዋሳ ወንጀል ሪፖርት መተግበሪያን በማውረድ እና በመጠቀም ይህንን ውሎች እና ደንቦች መቀበልዎን ያረጋግጣሉ። ካልተስማሙ፣ እባክዎ መተግበሪያውን አይጠቀሙ።', t, accentColor),
    _section('2. የመተግበሪያው ዓላማ',
        'ይህ መተግበሪያ የሀዋሳ ከተማ ዜጎች ወንጀሎችን ሪፖርት እንዲያደርጉ፣ የህዝብ ደህንነት ማስጠንቀቂያዎችን እንዲያዩ እና ከፖሊስ ጋር ለመገናኘት የተዘጋጀ ነው። ይህ አስቸኳይ ምላሽ አገልግሎት አይደለም። አስቸኳይ ሁኔታ ሲያጋጥምዎ ወዲያውኑ 911 ወይም ፖሊስ 8 ይደውሉ።', t, accentColor),
    _section('3. የተጠቃሚ ኃላፊነቶች',
        'ሪፖርት ሲያስገቡ ትክክለኛ እና እውነተኛ መረጃ መስጠትዎን ይስማማሉ። ሐሰተኛ ሪፖርቶችን ማቅረብ በኢትዮጵያ ሕግ ወንጀል ሲሆን ሕጋዊ እርምጃ ሊያስከትል ይችላል። መለያ ለመፍጠር ቢያንስ 18 ዓመት ሊሆንዎ ይገባል።', t, accentColor),
    _section('4. የመለያ ደህንነት',
        'የመለያዎን ምስጢር መጠበቅ ኃላፊነትዎ ነው። የይለፍ ቃልዎን ለማንም አያጋሩ። ያልተፈቀደ ሰው ወደ መለያዎ ለመግባት ሞክሯል ብለው ካሰቡ ወዲያውኑ ያሳውቁን።', t, accentColor),
    _section('5. ሪፖርቶችን ማስገባት',
        'በዚህ መተግበሪያ የሚቀርቡ ሪፖርቶች የሀዋሳ ከተማ ፖሊስ ይቀበላቸዋል። ሪፖርት በማስገባት የእርስዎ መረጃ በፈቃደኛ ሕግ አስፈጻሚ ባለሙያዎች እንዲታይ ይፈቅዳሉ። 익명 ሪፖርት ማድረግ ይቻላል ነገር ግን ፖሊስ ከእርስዎ ጋር የሚያደርጉትን ክትትል ሊወስን ይችላል።', t, accentColor),
    _section('6. ማስረጃ መስቀል',
        'ፎቶዎችን፣ ቪዲዮዎችን እና ድምጽ ቀረጻዎችን ማስረጃ ሆነው ሊሰቅሉ ይችላሉ። የሚሰቅሏቸው ፋይሎች ባለቤት መሆን ወይም ከሁሉም ወገኖች ፈቃድ ሊኖርዎ ይገባል። ሕገ ወጥ፣ ስም አጥፊ ወይም የሌሎችን ግላዊነት የሚጥስ ይዘት አይሰቅሉ።', t, accentColor),
    _section('7. የምንሰበሰበው ውሂብ',
        'የሚከተሉትን መረጃዎች እንሰበስባለን፦ ሙሉ ስም፣ ኢሜይል አድራሻ፣ ስልክ ቁጥር፣ የፕሮፋይል ፎቶ (አማራጭ)፣ ሪፖርቶችን ሲያስገቡ የቦታ ውሂብ እና የሚሰቅሏቸው ማስረጃ ፋይሎች። የእርስዎን ውሂብ ለሶስተኛ ወገኖች አንሸጥም።', t, accentColor),
    _section('8. ውሂብዎን እንዴት እንጠቀምበታለን',
        'ውሂብዎ ወንጀል ሪፖርት ማድረጉን እና በዜጎች እና የሀዋሳ ከተማ ፖሊስ መካከል ያለውን ግንኙነት ለማመቻቸት ብቻ ጥቅም ላይ ይውላል። የሪፖርት ዝርዝሮች እና ማስረጃዎች ለፈቃደኛ ሕግ አስፈጻሚ መኮንኖች ብቻ ተደራሽ ናቸው።', t, accentColor),
    _section('9. ውሂብ ማከማቸት እና ደህንነት',
        'ሁሉም ውሂብ በሀዋሳ ከተማ አስተዳደር ሰርቨሮች ላይ ደህንነቱ ተጠብቆ ይቀመጣል። መረጃዎን ለመጠበቅ የኢንዱስትሪ ደረጃ ምስጠራ እንጠቀማለን። ለሕግ አስፈጻሚ ዓላማዎች አስፈላጊ እስካለ ወይም ሕጉ እስካዘዘ ድረስ ውሂብዎን እናስቀምጣለን።', t, accentColor),
    _section('10. ማሳወቂያዎች',
        'ይህን መተግበሪያ በመጠቀም ስለ ሪፖርትዎ ሁኔታ እና አስፈላጊ የህዝብ ደህንነት ማስጠንቀቂያዎች የመተግበሪያ ማሳወቂያዎችን ለመቀበል ይስማማሉ።', t, accentColor),
    _section('11. የተከለከሉ አጠቃቀሞች',
        'ሐሰተኛ ሪፖርቶችን ለማስገባት፣ ሰዎችን ለማሸማቀቅ፣ ሕገ ወጥ ይዘት ለማጋራት፣ የሌሎች ተጠቃሚዎችን ውሂብ ለመድረስ ወይም የመተግበሪያ ወይም የፖሊስ አገልግሎቶችን ሥራ ለማስተጓጎል ይህን መተግበሪያ መጠቀም አይፈቀድም።', t, accentColor),
    _section('12. የኃላፊነት ገደብ',
        'የሀዋሳ ከተማ ፖሊስ እና የመተግበሪያ አስተዳዳሪዎች ከመተግበሪያው አጠቃቀም፣ ፖሊስ ዘግይቶ ምላሽ ከመስጠቱ ወይም በማስጠንቀቂያ መረጃ ውስጥ ካሉ ስህተቶች ለሚመጣ ማናቸውም ኪሳራ ተጠያቂ አይሆኑም።', t, accentColor),
    _section('13. ለውጦች',
        'እነዚህን ውሎች በማንኛውም ጊዜ ማሻሻል የሚችሉበት መብት ይጠበቅልናል። ለውጦች ከተለጠፉ በኋላ መተግበሪያውን መቀጠል አዲሱን ውሎች እንደተቀበሉ ይቆጠራል።', t, accentColor),
    _section('14. አድራሻ',
        'ስለ እነዚህ ውሎች ወይም ምስጢርዎ ጥያቄ ካለዎት፣ እባክዎ የሀዋሳ ከተማ ፖሊስ ዲጂታል አገልግሎቶች ቢሮን ያግኙ ወይም በመተግበሪያው ውስጥ ያለውን "ያግኙን" አማራጭ ይጠቀሙ።', t, accentColor),
  ];

  Widget _section(String title, String body, AppTheme t, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.04),
            blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: accentColor)),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(fontSize: 13, color: t.primaryText, height: 1.6)),
        ],
      ),
    );
  }
}