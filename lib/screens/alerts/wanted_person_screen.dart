// lib/screens/alerts/wanted_person_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/alert_post.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import 'alert_detail_screen.dart';
import '../../providers/badge_provider.dart';

const _kNavy    = Color(0xFF0D1B2A);
const _kNavyMid = Color(0xFF1A3A5C);
const _kGold    = Color(0xFFC9A84C);
const _kRed     = Color(0xFFC62828);
const _kAmber   = Color(0xFFE65100);
const _kGreen   = Color(0xFF2E7D32);

class WantedPersonScreen extends StatefulWidget {
  const WantedPersonScreen({super.key});
  @override
  State<WantedPersonScreen> createState() => _WantedPersonScreenState();
}

class _WantedPersonScreenState extends State<WantedPersonScreen>
    with SingleTickerProviderStateMixin {
  List<AlertPost> _posts = [];
  bool _loading = true;
  String? _error;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _load();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/alerts?category=Wanted+Person'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _posts   = data.map((j) => AlertPost.fromJson(j)).toList();
          _loading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() { _error = 'failed_to_load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'network_error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr     = context.watch<LanguageProvider>().tr;
    final t      = context.watch<ThemeProvider>().theme;
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
            boxShadow: [
              BoxShadow(color: _kNavy.withOpacity(0.4), blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
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
                    child: const Icon(Icons.person_off_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.get('wanted_persons'),
                          style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.w900, color: Colors.white,
                              letterSpacing: 0.3)),
                      if (!_loading)
                        Text('${_posts.length} active record${_posts.length == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12,
                                color: _kGold.withOpacity(0.9),
                                fontWeight: FontWeight.w600)),
                    ],
                  )),
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),

              // Gold warning strip
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: _kGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Do NOT approach. Call police if you see this person.',
                    style: TextStyle(fontSize: 11,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600),
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kGold.withOpacity(0.4)),
                    ),
                    child: const Text('991',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                            color: _kGold)),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(
                  color: t.isNight ? _kGold : _kNavyMid, strokeWidth: 2.5))
              : _error != null
                  ? _buildError(tr, t, accent)
                  : _posts.isEmpty
                      ? _buildEmpty(tr, t, accent)
                      : RefreshIndicator(
                          color: t.isNight ? _kGold : _kNavyMid,
                          onRefresh: _load,
                          child: ListView.builder(
                            
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                            itemCount: _posts.length,
                            itemBuilder: (_, i) {
                              final delay = i * 0.08;
                              return AnimatedBuilder(
                                animation: _animController,
                                builder: (_, child) {
                                  final v = Curves.easeOutCubic.transform(
                                    ((_animController.value - delay)
                                            .clamp(0.0, 1.0 - delay) /
                                        (1.0 - delay))
                                        .clamp(0.0, 1.0),
                                  );
                                  return Opacity(
                                    opacity: v,
                                    child: Transform.translate(
                                        offset: Offset(0, 18 * (1 - v)),
                                        child: child),
                                  );
                                },
                              child: _WantedCard(
  post: _posts[i], tr: tr, t: t,
  isUnseen: _posts[i].id > context.read<BadgeProvider>().seenWantedId,
  onTap: () {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => AlertDetailScreen(post: _posts[i])));
  },
  onDetailTap: () {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => AlertDetailScreen(post: _posts[i])));
    context.read<BadgeProvider>().markWantedSeen();
  },
),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildError(dynamic tr, AppTheme t, Color accent) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Icon(Icons.wifi_off_rounded, size: 36,
              color: accent.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        Text(tr.get(_error!),
            style: TextStyle(fontSize: 15, color: t.primaryText,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(tr.get('retry'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: t.isNight ? _kGold : _kNavyMid,
            foregroundColor: t.isNight ? _kNavy : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildEmpty(dynamic tr, AppTheme t, Color accent) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.07),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withOpacity(0.15), width: 1.5),
        ),
        child: Icon(Icons.person_search_rounded, size: 42,
            color: accent.withOpacity(0.45)),
      ),
      const SizedBox(height: 20),
      Text(tr.get('no_wanted_persons'),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
              color: t.primaryText)),
      const SizedBox(height: 8),
      Text('No active records at this time',
          style: TextStyle(fontSize: 13, color: t.secondaryText)),
    ]),
  );
}

// ── Wanted Card ──────────────────────────────────────────────────────────────
class _WantedCard extends StatelessWidget {
  final AlertPost    post;
  final VoidCallback onTap;
  final dynamic      tr;
  final AppTheme     t;
  final bool isUnseen;
  final VoidCallback onDetailTap;
 
 const _WantedCard(
    {required this.post, required this.onTap, required this.onDetailTap, required this.tr, required this.t, required this.isUnseen});

  Color get _riskColor => post.riskLevel == 'High Risk'
      ? _kRed
      : post.riskLevel == 'Medium Risk'
          ? _kAmber
          : _kGreen;

  @override
  Widget build(BuildContext context) {
    final hasPhoto   = post.mediaFiles.isNotEmpty;
    final isResolved = post.caseStatus != null && post.caseStatus != 'active';
    final accent     = t.isNight ? _kGold : _kNavyMid;

   return GestureDetector(
  onTap: onTap,
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.dividerColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: [

            // Thin accent top bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
  colors: isResolved
                      ? [_kGreen, const Color(0xFF43A047)]
                      : [accent, accent.withOpacity(0.4)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Photo
                Stack(children: [
                  Container(
                    width: 80, height: 94,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.dividerColor, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: hasPhoto
                          ? Image.network(post.mediaFiles.first.url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _photoPlaceholder())
                          : _photoPlaceholder(),
                    ),
                  ),
                  // Risk dot — only small colored element
                  if (post.riskLevel != null)
                    Positioned(
                      top: 5, right: 5,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _riskColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [BoxShadow(
                              color: _riskColor.withOpacity(0.4), blurRadius: 4)],
                        ),
                      ),
                    ),
                ]),
                const SizedBox(width: 14),

                // Info
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? _kGreen.withOpacity(0.1)
                              : accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isResolved
                                ? _kGreen.withOpacity(0.25)
                                : accent.withOpacity(0.25),
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            isResolved
                                ? Icons.check_circle_outline_rounded
                                : Icons.warning_amber_rounded,
                            size: 10,
                            color: isResolved ? _kGreen : accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isResolved ? 'RESOLVED' : tr.get('wanted_badge'),
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w900,
                              color: isResolved ? _kGreen : accent,
                              letterSpacing: 1,
                            ),
                          ),
                        ]),
                      ),
                      if (post.riskLevel != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _riskColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _riskColor.withOpacity(0.2)),
                          ),
                          child: Text(tr.translateRiskLevel(post.riskLevel!),
                              style: TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _riskColor)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 7),

                    // Name
                    Text(post.subjectName ?? post.title,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900,
                          color: t.isNight ? _kGold : _kNavy,
                          height: 1.2,
                        )),
                    if (post.nickname != null) ...[
                      const SizedBox(height: 2),
                      Text('"${post.nickname}"',
                          style: TextStyle(fontSize: 12,
                              color: t.secondaryText,
                              fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 8),

                    if (post.committedCrime != null)
                      _row(Icons.gavel_rounded,
                          '${tr.get('charge')}: ${tr.translateCrimeType(post.committedCrime!)}',
                          t, accent),
                    if (post.height != null || post.weight != null)
                      _row(Icons.straighten_rounded,
                          [
                            if (post.height != null) '${post.height}cm',
                            if (post.weight != null) '${post.weight}kg',
                          ].join(' · '),
                          t, accent),
                    if (post.lastSeenLocation != null)
                      _row(Icons.location_on_outlined,
                          post.lastSeenLocation!, t, accent),
                  ],
                )),

                // Arrow
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      color: accent.withOpacity(0.6), size: 20),
                ),
              ]),
            ),

            // Footer
            // Footer
GestureDetector(
  onTap: onDetailTap,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.04),
      border: Border(top: BorderSide(color: t.dividerColor)),
    ),
    child: Row(children: [
      Icon(Icons.visibility_outlined, size: 12,
          color: accent.withOpacity(0.5)),
      const SizedBox(width: 6),
      Expanded(child: Text(
        'Tap to view details & submit a sighting tip',
        style: TextStyle(fontSize: 11, color: t.secondaryText,
            fontWeight: FontWeight.w500),
      )),
      Icon(Icons.arrow_forward_rounded, size: 12,
          color: accent.withOpacity(0.4)),
    ]),
  ),
),
          ]),
        ),
      ),
      if (isUnseen)
        Positioned(
          top: 8, right: 8,
          child: _FlashingDot(),
        ),
   ],
  ),
);
  }

  Widget _row(IconData icon, String text, AppTheme t, Color accent) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 12, color: accent.withOpacity(0.7)),
          const SizedBox(width: 5),
          Expanded(child: Text(text,
              style: TextStyle(fontSize: 11.5, color: t.secondaryText,
                  height: 1.4),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _photoPlaceholder() => Container(
    color: t.isNight ? const Color(0xFF1A2F46) : const Color(0xFFF4F6FA),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.person_rounded, size: 32,
          color: t.isNight
              ? _kGold.withOpacity(0.25)
              : _kNavyMid.withOpacity(0.2)),
      const SizedBox(height: 4),
      Text('No Photo',
          style: TextStyle(fontSize: 9, color: t.secondaryText,
              fontWeight: FontWeight.w600)),
    ]),
  );
}
class _FlashingDot extends StatefulWidget {
  @override
  State<_FlashingDot> createState() => _FlashingDotState();
}

class _FlashingDotState extends State<_FlashingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.5),
            blurRadius: 6)],
      ),
    ),
  );
}