// lib/screens/account/help_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr   = context.watch<LanguageProvider>().tr;
    final t    = context.watch<ThemeProvider>().theme;
    final isAm = tr.isAmharic;
    final steps = isAm ? _stepsAm : _stepsEn;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text(tr.get('help'),
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
                  Icon(Icons.menu_book_rounded,
                     color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                      size: 36),
                  const SizedBox(height: 12),
                  Text(
                    isAm ? 'መተግበሪያውን እንዴት መጠቀም እንደሚቻል' : 'How to Use the App',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                       color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAm
                        ? 'የሀዋሳ ወንጀል ሪፖርት መተግበሪያን ለመጠቀም ቀላል የደረጃ-ደረጃ መምሪያ።'
                        : 'A simple step-by-step guide to using the Hawassa Crime Report app.',
                    style: TextStyle(fontSize: 13, color: t.isNight ? const Color(0xFF1A3A5C).withOpacity(0.7) : Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Steps
            ...steps.asMap().entries.map((entry) {
              final i    = entry.key;
              final step = entry.value;
              return _StepCard(
                number: i + 1,
                title: step['title']!,
                description: step['description']!,
                icon: _icons[i % _icons.length],
                isLast: i == steps.length - 1,
                t: t,
                accentColor: accentColor,
              );
            }),

            const SizedBox(height: 24),

            // Emergency note — always red, works in both modes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.isNight
                    ? const Color(0xFF7F1D1D).withOpacity(0.3)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: t.isNight
                        ? const Color(0xFFDC2626).withOpacity(0.4)
                        : const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'አስቸኳይ ሁኔታ' : 'Emergency?',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAm
                              ? 'አስቸኳይ ሁኔታ ሲያጋጥምዎ ወዲያውኑ 907 ወይም የፖሊስ ቁጥር 991 ይደውሉ። ይህ መተግበሪያ ለአስቸኳይ ጊዜ ምላሽ አገልግሎት አይደለም።'
                              : 'In an emergency, call 907 or Police 991 immediately. This app is not an emergency response service.',
                          style: TextStyle(
                              fontSize: 13,
                              color: t.isNight
                                  ? const Color(0xFFDC2626).withOpacity(0.9)
                                  : const Color(0xFF7F1D1D),
                              height: 1.5),
                        ),
                      ],
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

  static const List<IconData> _icons = [
    Icons.app_registration,
    Icons.login,
    Icons.home_rounded,
    Icons.report_problem_outlined,
    Icons.location_on_outlined,
    Icons.attach_file,
    Icons.notifications_outlined,
    Icons.search,
    Icons.language,
    Icons.person_outline,
  ];

  static const List<Map<String, String>> _stepsEn = [
    {
      'title': 'Create an Account',
      'description':
          'Tap "Register" on the login screen. Enter your full name, email, phone number, and a strong password. Accept the terms and conditions, then tap Sign Up.',
    },
    {
      'title': 'Log In',
      'description':
          'Open the app and enter your email and password. Tap Sign In to access your account. You can also skip login to browse public alerts without an account.',
    },
    {
      'title': 'Navigate the Home Screen',
      'description':
          'The home screen shows quick-access cards: Report Incident, Wanted Persons, Missing Persons, Missing Items, and News Feed. Use the bottom navigation bar to switch between screens.',
    },
    {
      'title': 'Report an Incident',
      'description':
          'Tap "Report Incident" from the home screen or bottom bar. Select the crime type, pick the date and time, choose a location on the map, write a detailed description, and attach any evidence (photos, video, or audio).',
    },
    {
      'title': 'Add Your Location',
      'description':
          'On the report screen, tap the map area to open the map picker. Tap anywhere to drop a pin on the location where the incident happened. You can also tap "Get Current Location" to use your GPS position.',
    },
    {
      'title': 'Attach Evidence',
      'description':
          'Use the evidence buttons to take a photo, choose from gallery, record a video, or record audio. You can attach multiple files. Tap any file preview to view it before submitting.',
    },
    {
      'title': 'Track Your Reports',
      'description':
          'Go to "My Reports" from the bottom navigation bar. You can see all your submitted reports and their current status: Submitted, Under Review, In Progress, Resolved, or Rejected. Tap any report to see full details and officer notes.',
    },
    {
      'title': 'View Public Alerts',
      'description':
          'Tap "Wanted Persons", "Missing Persons", or "Missing Items" from the home screen to see active police alerts. Tap any alert to view full details. If you have information, tap "Report a Sighting" to help the police.',
    },
    {
      'title': 'Check Notifications',
      'description':
          'Tap the bell icon at the top of the home screen to view notifications. You will be notified when your report status changes or when the admin sends you a message. Unread notifications show a red badge.',
    },
    {
      'title': 'Change Language',
      'description':
          'Go to Account → Language and choose between English and Amharic (አማርኛ). The language change applies to all screens immediately and is saved permanently even after you log out.',
    },
  ];

  static const List<Map<String, String>> _stepsAm = [
    {
      'title': 'መለያ ፍጠር',
      'description':
          'በመግቢያ ማያ ገጽ ላይ "ተመዝገብ" ይንኩ። ሙሉ ስምዎን፣ ኢሜይልዎን፣ ስልክ ቁጥርዎን እና ጠንካራ የይለፍ ቃል ያስገቡ። ውሎቹን እና ደንቦቹን ይቀበሉ፣ ከዚያ ተመዝገብ ይንኩ።',
    },
    {
      'title': 'ወደ መለያዎ ይግቡ',
      'description':
          'መተግበሪያውን ከፍተው ኢሜይልዎን እና የይለፍ ቃልዎን ያስገቡ። ወደ መለያዎ ለመግባት "ግባ" ይንኩ። ያለ መለያ የህዝብ ማስጠንቀቂያዎችን ለማየትም ያለ ግባ ቢቀጥሉ ይቻላል።',
    },
    {
      'title': 'የቤት ማያ ገጹን ያስሱ',
      'description':
          'የቤት ማያ ገጹ ፈጣን የመዳረሻ ካርዶችን ያሳያል፦ ወንጀል ሪፖርት፣ የሚፈለጉ ሰዎች፣ የጠፉ ሰዎች፣ የጠፉ ዕቃዎች እና ዜና ፊድ። በታችኛው የናቪጌሽን አሞሌ ማያ ገጾችን ይቀያይሩ።',
    },
    {
      'title': 'ወንጀል ሪፖርት አድርጉ',
      'description':
          'ከቤት ማያ ገጽ ወይም ከታችኛው አሞሌ "ወንጀል ሪፖርት" ይንኩ። የወንጀሉን አይነት ምረጡ፣ ቀን እና ሰዓት ይምረጡ፣ ካርታ ላይ ቦታ ይምረጡ፣ ዝርዝር መግለጫ ይጻፉ፣ ማስረጃ (ፎቶ፣ ቪዲዮ ወይም ድምጽ) ያያይዙ።',
    },
    {
      'title': 'ቦታዎን ያስገቡ',
      'description':
          'በሪፖርት ማያ ገጽ ላይ ካርታውን ይንኩ። ወንጀሉ የተፈጸመበትን ቦታ ፒን ለማስቀመጥ ካርታ ላይ ይንኩ። "የአሁን ቦታ አግኝ" ቁልፍን ጠቅ ​​​​​​ቢያደርጉ GPS ቦታዎን ይጠቀማል።',
    },
    {
      'title': 'ማስረጃ ያያይዙ',
      'description':
          'ፎቶ ለማንሳት፣ ከጋለሪ ለመምረጥ፣ ቪዲዮ ለመቅዳት ወይም ድምጽ ለመቅዳት የማስረጃ ቁልፎቹን ይጠቀሙ። ብዙ ፋይሎች ማያያዝ ይቻላል። ከማስገባትዎ በፊት ፋይሎቹን ለማየት ቅድመ እይታቸውን ይንኩ።',
    },
    {
      'title': 'ሪፖርቶቼን ይከታተሉ',
      'description':
          'ከታችኛው ናቪጌሽን አሞሌ "ሪፖርቶቼ" ይሂዱ። ሁሉም ሪፖርቶቻቸው እና ሁኔታቸው ይታያሉ፦ ቀርቧል፣ በግምገማ ላይ፣ በሂደት ላይ፣ ተፈትቷል ወይም ተቀባይነት አልተሰጠም። ሙሉ ዝርዝር እና የፖሊስ ማስታወሻ ለማየት ሪፖርቱን ይንኩ።',
    },
    {
      'title': 'የህዝብ ማስጠንቀቂያዎችን ይመልከቱ',
      'description':
          'ንቁ የፖሊስ ማስጠንቀቂያዎችን ለማየት ከቤት ማያ ገጽ "የሚፈለጉ ሰዎች"፣ "የጠፉ ሰዎች" ወይም "የጠፉ ዕቃዎች"ን ይንኩ። ሙሉ ዝርዝር ለማየት ማስጠንቀቂያ ይንኩ። መረጃ ካለዎት ፖሊስን ለመርዳት "ሪፖርት አድርጉ" ይንኩ።',
    },
    {
      'title': 'ማሳወቂያዎችን ይፈትሹ',
      'description':
          'ማሳወቂያዎችን ለማየት በቤት ማያ ገጽ አናት ላይ ያለውን የደወል አዶ ይንኩ። የሪፖርትዎ ሁኔታ ሲቀየር ወይም አስተዳዳሪ መልዕክት ሲልክዎ ማሳወቂያ ይደርስዎታል። ያልተነበቡ ማሳወቂያዎች ቀይ ምልክት ያሳያሉ።',
    },
    {
      'title': 'ቋንቋ ይቀይሩ',
      'description':
          'ወደ መለያ → ቋንቋ ሂደው እንግሊዝኛ ወይም አማርኛ ይምረጡ። የቋንቋ ለውጥ ወዲያውኑ በሁሉም ማያ ገጾች ላይ ይሠራል እና ከወጡ በኋላም ቋሚ ሆኖ ይቀምጣል።',
    },
  ];
}

class _StepCard extends StatefulWidget {
  final int      number;
  final String   title;
  final String   description;
  final IconData icon;
  final bool     isLast;
  final AppTheme t;
  final Color    accentColor;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.isLast,
    required this.t,
    required this.accentColor,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t           = widget.t;
    final accentColor = widget.accentColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number + connecting line
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            child: Center(
              child: Text('${widget.number}',
                  style: TextStyle(
                      color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
          if (!widget.isLast)
            Container(width: 2, height: 20,
                color: accentColor.withOpacity(0.25)),
        ]),
        const SizedBox(width: 14),
        // Card
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _expanded ? accentColor : t.dividerColor,
                  width: _expanded ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.04),
                    blurRadius: 6, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(widget.icon, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: accentColor)),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: accentColor,
                    ),
                  ]),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    Divider(height: 1, color: t.dividerColor),
                    const SizedBox(height: 10),
                    Text(widget.description,
                        style: TextStyle(fontSize: 13, color: t.primaryText, height: 1.6)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}