// lib/screens/account/help_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // Which step is expanded (-1 = none)
  int _expandedIndex = -1;

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
    super.dispose();
  }

  static const List<IconData> _icons = [
    Icons.app_registration_rounded,
    Icons.login_rounded,
    Icons.home_rounded,
    Icons.report_problem_outlined,
    Icons.location_on_outlined,
    Icons.attach_file_rounded,
    Icons.track_changes_rounded,
    Icons.notifications_outlined,
    Icons.search_rounded,
    Icons.language_rounded,
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
      'title': 'Check Notifications',
      'description':
          'Tap the bell icon at the top of the home screen to view notifications. You will be notified when your report status changes or when the admin sends you a message. Unread notifications show a red badge.',
    },
    {
      'title': 'View Public Alerts',
      'description':
          'Tap "Wanted Persons", "Missing Persons", or "Missing Items" from the home screen to see active police alerts. Tap any alert to view full details. If you have information, tap "Report a Sighting" to help the police.',
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
      'title': 'ማሳወቂያዎችን ይፈትሹ',
      'description':
          'ማሳወቂያዎችን ለማየት በቤት ማያ ገጽ አናት ላይ ያለውን የደወል አዶ ይንኩ። የሪፖርትዎ ሁኔታ ሲቀየር ወይም አስተዳዳሪ መልዕክት ሲልክዎ ማሳወቂያ ይደርስዎታል። ያልተነበቡ ማሳወቂያዎች ቀይ ምልክት ያሳያሉ።',
    },
    {
      'title': 'የህዝብ ማስጠንቀቂያዎችን ይመልከቱ',
      'description':
          'ንቁ የፖሊስ ማስጠንቀቂያዎችን ለማየት ከቤት ማያ ገጽ "የሚፈለጉ ሰዎች"፣ "የጠፉ ሰዎች" ወይም "የጠፉ ዕቃዎች"ን ይንኩ። ሙሉ ዝርዝር ለማየት ማስጠንቀቂያ ይንኩ። መረጃ ካለዎት ፖሊስን ለመርዳት "ሪፖርት አድርጉ" ይንኩ።',
    },
    {
      'title': 'ቋንቋ ይቀይሩ',
      'description':
          'ወደ መለያ → ቋንቋ ሂደው እንግሊዝኛ ወይም አማርኛ ይምረጡ። የቋንቋ ለውጥ ወዲያውኑ በሁሉም ማያ ገጾች ላይ ይሠራል እና ከወጡ በኋላም ቋሚ ሆኖ ይቀምጣል።',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final tr    = context.watch<LanguageProvider>().tr;
    final t     = context.watch<ThemeProvider>().theme;
    final isAm  = tr.isAmharic;
    final gold  = const Color(0xFFD5C38B);
    final navy  = const Color(0xFF1A3A5C);
    final accent = t.isNight ? gold : navy;
    final steps  = isAm ? _stepsAm : _stepsEn;

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
          Text(
            tr.get('help'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            isAm ? 'የተጠቃሚ መምሪያ' : 'User Guide',
            style: TextStyle(
              fontSize: 11,
              color: gold.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
        actions: [
          // Step counter badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withOpacity(0.3)),
            ),
            child: Text(
              '${steps.length} ${isAm ? 'ደረጃዎች' : 'steps'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: gold,
              ),
            ),
          ),
        ],
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

                // ── Hero banner ───────────────────────────────────────────
                _HelpHero(isAm: isAm, gold: gold, navy: navy, t: t),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Progress overview row ─────────────────────────────
                      _ProgressRow(
                        total: steps.length,
                        expanded: _expandedIndex,
                        accent: accent,
                        t: t,
                        isAm: isAm,
                      ),

                      const SizedBox(height: 20),

                      // ── Section label ─────────────────────────────────────
                      _SectionLabel(
                        icon: Icons.format_list_numbered_rounded,
                        label: isAm ? 'ደረጃ-ደረጃ መምሪያ' : 'Step-by-Step Guide',
                        accent: accent,
                      ),

                      const SizedBox(height: 16),

                      // ── Steps ─────────────────────────────────────────────
                      ...steps.asMap().entries.map((entry) {
                        final i    = entry.key;
                        final step = entry.value;
                        return _StepCard(
                          number: i + 1,
                          title: step['title']!,
                          description: step['description']!,
                          icon: _icons[i % _icons.length],
                          isLast: i == steps.length - 1,
                          isExpanded: _expandedIndex == i,
                          onTap: () => setState(() =>
                              _expandedIndex = _expandedIndex == i ? -1 : i),
                          t: t,
                          accent: accent,
                          gold: gold,
                          navy: navy,
                        );
                      }),

                      const SizedBox(height: 24),

                      // ── Emergency notice ──────────────────────────────────
                      _EmergencyNotice(isAm: isAm, t: t),

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

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HelpHero extends StatelessWidget {
  final bool isAm;
  final Color gold, navy;
  final AppTheme t;
  const _HelpHero(
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
          right: -20,
          bottom: -20,
          child: Icon(Icons.menu_book_rounded,
              size: 130, color: Colors.white.withOpacity(0.04)),
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
              child: Icon(Icons.menu_book_rounded, color: gold, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  isAm
                      ? 'መተግበሪያውን እንዴት\nመጠቀም እንደሚቻል'
                      : 'How to Use\nthe App',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAm
                      ? 'ቀላል ደረጃ-ደረጃ መምሪያ'
                      : 'A simple step-by-step guide',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6)),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Progress Row ─────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final int total, expanded;
  final Color accent;
  final AppTheme t;
  final bool isAm;
  const _ProgressRow({
    required this.total,
    required this.expanded,
    required this.accent,
    required this.t,
    required this.isAm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.12), width: 1),
      ),
      child: Row(children: [
        Icon(Icons.auto_stories_outlined, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isAm
                ? 'ሁሉንም ደረጃዎች ለማየት ይንኩ'
                : 'Tap any step to expand its guide',
            style: TextStyle(
              fontSize: 12,
              color: t.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Mini step dots
        Row(
          children: List.generate(
            total > 6 ? 6 : total,
            (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == expanded
                    ? accent
                    : accent.withOpacity(0.2),
              ),
            ),
          ),
        ),
        if (total > 6) ...[
          const SizedBox(width: 3),
          Text('…',
              style: TextStyle(
                  color: accent.withOpacity(0.4), fontSize: 12)),
        ],
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

// ─── Step Card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int number;
  final String title, description;
  final IconData icon;
  final bool isLast, isExpanded;
  final VoidCallback onTap;
  final AppTheme t;
  final Color accent, gold, navy;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.isLast,
    required this.isExpanded,
    required this.onTap,
    required this.t,
    required this.accent,
    required this.gold,
    required this.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline column ───────────────────────────────────────────
        SizedBox(
          width: 44,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isExpanded ? accent : accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: isExpanded
                      ? [
                          BoxShadow(
                              color: accent.withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 1)
                        ]
                      : [],
                ),
                child: Center(
                  child: isExpanded
                      ? Icon(
                          icon,
                          size: 16,
                          color: t.isNight ? navy : Colors.white,
                        )
                      : Text(
                          '$number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 2,
                  height: isExpanded ? 0 : 16,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),

        // ── Card ─────────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isExpanded
                      ? accent
                      : accent.withOpacity(0.1),
                  width: isExpanded ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isExpanded
                        ? accent.withOpacity(0.08)
                        : Colors.black
                            .withOpacity(t.isNight ? 0.15 : 0.04),
                    blurRadius: isExpanded ? 12 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(children: [
                      // Step number / icon badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? accent.withOpacity(0.12)
                              : accent.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon,
                            color: accent,
                            size: 17),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                            'Step $number',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent.withOpacity(0.5),
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ]),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ),
                      ),
                    ]),
                  ),

                  // Expanded content
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              accent.withOpacity(0.2),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: t.primaryText,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Done indicator
                              Row(children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 13,
                                    color: accent.withOpacity(0.5)),
                                const SizedBox(width: 5),
                                Text(
                                  'Tap again to collapse',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: accent.withOpacity(0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Emergency Notice ─────────────────────────────────────────────────────────

class _EmergencyNotice extends StatelessWidget {
  final bool isAm;
  final AppTheme t;
  const _EmergencyNotice({required this.isAm, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.isNight
            ? const Color(0xFF7F1D1D).withOpacity(0.2)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.isNight
              ? const Color(0xFFDC2626).withOpacity(0.35)
              : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFDC2626), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isAm ? 'አስቸኳይ ሁኔታ?' : 'In an Emergency?',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAm
                  ? 'አስቸኳይ ሁኔታ ሲያጋጥምዎ ወዲያውኑ 907 ወይም የፖሊስ ቁጥር 991 ይደውሉ። ይህ መተግበሪያ ለአስቸኳይ ጊዜ ምላሽ አገልግሎት አይደለም።'
                  : 'Call 907 or Police 991 immediately. This app is not an emergency response service — always call in a crisis.',
              style: TextStyle(
                fontSize: 13,
                color: t.isNight
                    ? const Color(0xFFDC2626).withOpacity(0.85)
                    : const Color(0xFF7F1D1D),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _NumberPill(number: '907', label: isAm ? 'አስቸኳይ' : 'Emergency'),
              const SizedBox(width: 8),
              _NumberPill(number: '991', label: isAm ? 'ፖሊስ' : 'Police'),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _NumberPill extends StatelessWidget {
  final String number, label;
  const _NumberPill({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.3), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.phone_rounded,
            size: 12, color: Color(0xFFDC2626)),
        const SizedBox(width: 4),
        Text(
          '$number · $label',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFFDC2626),
          ),
        ),
      ]),
    );
  }
}