// lib/screens/alerts/alert_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/alert_post.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import 'report_sighting_screen.dart';
import '../../widgets/auth_gate.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertPost post;
  const AlertDetailScreen({super.key, required this.post});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Theme helpers ──────────────────────────────────────────────
  static const Color _navyDark  = Color(0xFF0D2137);
  static const Color _navyMid   = Color(0xFF1A3A5C);
  static const Color _gold      = Color(0xFFD5B45A);
  static const Color _goldLight = Color(0xFFF0D98C);

  String _badgeKey(String category) {
    if (category == 'Wanted Person')  return 'wanted_badge';
    if (category == 'Missing Person') return 'missing_badge';
    return 'missing_item_badge';
  }

  IconData _badgeIcon(String category) {
    if (category == 'Wanted Person')  return Icons.warning_amber_rounded;
    if (category == 'Missing Person') return Icons.person_off;
    return Icons.inventory_2_outlined;
  }

  String _categoryLabel(String category, dynamic tr) {
    if (category == 'Wanted Person')  return tr.get('wanted_person');
    if (category == 'Missing Person') return tr.get('missing_person');
    return tr.get('missing_item');
  }

  Color _categoryAccent(String category) {
    if (category == 'Wanted Person')  return const Color(0xFFDC2626);
    if (category == 'Missing Person') return const Color(0xFFD97706);
    return _navyMid;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;
    final t  = context.watch<ThemeProvider>().theme;

    final accentColor    = t.isNight ? _gold : _navyMid;
    final catAccent      = _categoryAccent(widget.post.category);
    final isActive       = widget.post.caseStatus == null || widget.post.caseStatus == 'active';

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with image / gradient ──────────────────
          SliverAppBar(
            expandedHeight: widget.post.mediaFiles.isNotEmpty ? 300 : 180,
            pinned: true,
            stretch: true,
            backgroundColor: _navyDark,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: _circleBack(context),
            actions: [
              if (widget.post.sightingsCount > 0)
                _sightingsBadge(widget.post.sightingsCount, tr),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: widget.post.mediaFiles.isNotEmpty
                  ? _ImageGallery(
                      images: widget.post.mediaFiles,
                      accentColor: accentColor,
                      t: t,
                      tr: tr,
                    )
                  : _HeroPlaceholder(
                      category: widget.post.category,
                      t: t,
                      catAccent: catAccent,
                    ),
            ),
          ),

          // ── Category strip ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _CategoryStrip(
              category: widget.post.category,
              catAccent: catAccent,
              badgeKey: _badgeKey(widget.post.category),
              badgeIcon: _badgeIcon(widget.post.category),
              label: _categoryLabel(widget.post.category, tr),
              t: t,
              tr: tr,
            ),
          ),

          // ── Body content ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // Case status banner
                      if (!isActive)
                        _CaseStatusBanner(
                            status: widget.post.caseStatus!, tr: tr),

                      // Subject name
                      Text(
                        widget.post.subjectName ??
                            widget.post.itemDescription ??
                            widget.post.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          height: 1.2,
                        ),
                      ),
                      if (widget.post.nickname != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.format_quote,
                              size: 14, color: t.secondaryText),
                          const SizedBox(width: 2),
                          Text(
                            widget.post.nickname!,
                            style: TextStyle(
                              fontSize: 14,
                              color: t.secondaryText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Icon(Icons.format_quote,
                              size: 14, color: t.secondaryText),
                        ]),
                      ],

                      const SizedBox(height: 18),

                      // Details card
                      _DetailsCard(post: widget.post, t: t, tr: tr, accentColor: accentColor),

                      const SizedBox(height: 14),

                      // Description card
                      _DescriptionCard(
                          content: widget.post.content, t: t, accentColor: accentColor, tr: tr),

                      const SizedBox(height: 24),

                      // CTA button
                      if (isActive) ...[
                        _ReportSightingButton(
                          post: widget.post,
                          tr: tr,
                          t: t,
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 13, color: t.secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                tr.get('info_confidential'),
                                style: TextStyle(
                                    fontSize: 12, color: t.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBack(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _sightingsBadge(int count, dynamic tr) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.visibility, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            '$count ${tr.get('sightings_count')}',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }
}

// ── Hero Placeholder ───────────────────────────────────────────────────────────

class _HeroPlaceholder extends StatelessWidget {
  final String   category;
  final AppTheme t;
  final Color    catAccent;
  const _HeroPlaceholder(
      {required this.category, required this.t, required this.catAccent});

  static const Color _navyDark = Color(0xFF0D2137);
  static const Color _navyMid  = Color(0xFF1A3A5C);
  static const Color _gold     = Color(0xFFD5B45A);

  @override
  Widget build(BuildContext context) {
    IconData icon = category == 'Missing Item'
        ? Icons.inventory_2_outlined
        : category == 'Wanted Person'
            ? Icons.person_search
            : Icons.person_off;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDark, _navyMid],
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6),
                itemBuilder: (_, __) =>
                    const Icon(Icons.shield, color: Colors.white, size: 20),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                        color: _gold.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(icon, size: 40, color: _gold.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text(
                    'HAWASSA POLICE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Strip ─────────────────────────────────────────────────────────────

class _CategoryStrip extends StatelessWidget {
  final String   category;
  final Color    catAccent;
  final String   badgeKey;
  final IconData badgeIcon;
  final String   label;
  final AppTheme t;
  final dynamic  tr;
  const _CategoryStrip({
    required this.category,
    required this.catAccent,
    required this.badgeKey,
    required this.badgeIcon,
    required this.label,
    required this.t,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: catAccent.withOpacity(t.isNight ? 0.15 : 0.08),
        border: Border(
          left: BorderSide(color: catAccent, width: 4),
        ),
      ),
      child: Row(children: [
        Icon(badgeIcon, size: 16, color: catAccent),
        const SizedBox(width: 8),
        Text(
          tr.get(badgeKey),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: catAccent,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: catAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: catAccent.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: catAccent,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Case Status Banner ─────────────────────────────────────────────────────────

class _CaseStatusBanner extends StatelessWidget {
  final String  status;
  final dynamic tr;
  const _CaseStatusBanner({required this.status, required this.tr});

  @override
  Widget build(BuildContext context) {
    final isArrested = status == 'arrested';
    final color   = isArrested ? const Color(0xFF065f46) : const Color(0xFF1e40af);
    final bgColor = isArrested ? const Color(0xFFd1fae5) : const Color(0xFFdbeafe);
    final icon    = isArrested ? Icons.gavel : Icons.check_circle_outline;
    final label   = isArrested ? tr.get('arrested') : tr.get('found_resolved');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            tr.get('case_status'),
            style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ]),
      ]),
    );
  }
}

// ── Details Card ───────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final AlertPost post;
  final AppTheme  t;
  final dynamic   tr;
  final Color     accentColor;
  const _DetailsCard(
      {required this.post, required this.t, required this.tr, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    void add(IconData icon, String labelKey, String? value,
        {Color? valueColor}) {
      if (value == null) return;
      rows.add(_InfoRow(
        icon: icon,
        label: tr.get(labelKey),
        value: value,
        t: t,
        valueColor: valueColor,
      ));
    }

    if (post.committedCrime != null) {
      rows.add(_InfoRow(
        icon: Icons.gavel,
        label: tr.get('charge'),
        value: tr.translateCrimeType(post.committedCrime!),
        t: t,
      ));
    }
    if (post.riskLevel != null) {
      rows.add(_RiskRow(riskLevel: post.riskLevel!, tr: tr, t: t));
    }
    if (post.height != null || post.weight != null) {
      rows.add(_InfoRow(
        icon: Icons.straighten,
        label: tr.get('height_weight'),
        value:
            '${post.height != null ? post.height! + "cm" : "—"} / ${post.weight != null ? post.weight! + "kg" : "—"}',
        t: t,
      ));
    }
    add(Icons.cake, 'date_of_birth', post.dateOfBirth);
    if (post.age != null) {
      rows.add(_InfoRow(
        icon: Icons.person,
        label: tr.get('age'),
        value: '${post.age} ${tr.get('years_old')}',
        t: t,
      ));
    }
    add(Icons.location_on, 'last_seen', post.lastSeenLocation);
    add(Icons.calendar_today, 'last_seen_date', post.lastSeenDate);
    add(Icons.checkroom, 'clothing', post.clothingDescription);
    add(Icons.location_searching, 'location_lost', post.locationLost);
    add(Icons.phone, 'contact', post.contactNumber);
    if (post.rewardInfo != null) {
      rows.add(_InfoRow(
        icon: Icons.monetization_on,
        label: tr.get('reward'),
        value: post.rewardInfo!,
        t: t,
        valueColor: const Color(0xFFD97706),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isNight ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                    color: accentColor.withOpacity(0.12), width: 1),
              ),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                tr.get('case_details'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

// ── Description Card ───────────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  final String   content;
  final AppTheme t;
  final Color    accentColor;
  final dynamic  tr;
  const _DescriptionCard(
      {required this.content, required this.t, required this.accentColor, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isNight ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              bottom:
                  BorderSide(color: accentColor.withOpacity(0.12), width: 1),
            ),
          ),
          child: Row(children: [
            Icon(Icons.description_outlined, size: 16, color: accentColor),
            const SizedBox(width: 8),
            Text(
              tr.get('description'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: t.primaryText,
              height: 1.7,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Report Sighting Button ─────────────────────────────────────────────────────

class _ReportSightingButton extends StatelessWidget {
  final AlertPost post;
  final dynamic   tr;
  final AppTheme  t;
  const _ReportSightingButton(
      {required this.post, required this.tr, required this.t});

  static const Color _navyDark  = Color(0xFF0D2137);
  static const Color _navyMid   = Color(0xFF1A3A5C);
  static const Color _gold      = Color(0xFFD5B45A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
  if (!AuthGate.require(context, featureName: 'report a sighting')) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ReportSightingScreen(post: post)),
  );
},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_navyDark, _navyMid],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _navyDark.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.visibility, color: _gold, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              post.category == 'Missing Item'
                  ? tr.get('report_sighting_item')
                  : tr.get('report_sighting'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: _gold, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Image Gallery ──────────────────────────────────────────────────────────────

class _ImageGallery extends StatefulWidget {
  final List<AlertMedia> images;
  final Color    accentColor;
  final AppTheme t;
  final dynamic  tr;
  const _ImageGallery(
      {required this.images, required this.accentColor, required this.t, required this.tr});
  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;
  final PageController _ctrl = PageController();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SizedBox(
        height: 300,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _openViewer(i),
            child: Image.network(
              widget.images[i].url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      color: const Color(0xFF0D2137),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFFD5B45A),
                        ),
                      ),
                    ),
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF0D2137),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 48, color: widget.t.secondaryText),
                      const SizedBox(height: 8),
                      Text(widget.tr.get('image_unavailable'),
                          style: TextStyle(
                              fontSize: 12, color: widget.t.secondaryText)),
                    ]),
              ),
            ),
          ),
        ),
      ),

      // Gradient overlay at bottom
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ),

      // Page indicators
      if (widget.images.length > 1)
        Positioned(
          bottom: 14, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _current == i
                      ? const Color(0xFFD5B45A)
                      : Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),

      // Counter pill
      if (widget.images.length > 1)
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${_current + 1} / ${widget.images.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),

      // Tap hint
      Positioned(
        bottom: widget.images.length > 1 ? 32 : 14,
        left: 12,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.zoom_in, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              widget.tr.get('tap_to_zoom'),
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ]),
        ),
      ),
    ]);
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ImageViewerScreen(images: widget.images, initial: index),
      ),
    );
  }
}

// ── Full-screen Image Viewer ───────────────────────────────────────────────────

class _ImageViewerScreen extends StatefulWidget {
  final List<AlertMedia> images;
  final int initial;
  const _ImageViewerScreen({required this.images, required this.initial});
  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _ctrl = PageController(initialPage: widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              widget.images[i].url,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.white30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final AppTheme t;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.t,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = t.isNight ? const Color(0xFFD5B45A) : const Color(0xFF1A3A5C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: accent.withOpacity(0.7)),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 105,
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: t.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? (t.isNight ? const Color(0xFFD5B45A) : const Color(0xFF1A3A5C)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String   riskLevel;
  final dynamic  tr;
  final AppTheme t;
  const _RiskRow(
      {required this.riskLevel, required this.tr, required this.t});

  @override
  Widget build(BuildContext context) {
    final isHigh   = riskLevel == 'High Risk';
    final isMedium = riskLevel == 'Medium Risk';
    final color   = isHigh
        ? const Color(0xFFDC2626)
        : isMedium
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);
    final bgColor = isHigh
        ? const Color(0xFFFEE2E2)
        : isMedium
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFD1FAE5);

    final accent = t.isNight ? const Color(0xFFD5B45A) : const Color(0xFF1A3A5C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.warning_amber_rounded,
              size: 15, color: accent.withOpacity(0.7)),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 105,
          child: Text(
            tr.get('risk_level'),
            style: TextStyle(
              fontSize: 12,
              color: t.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              tr.translateRiskLevel(riskLevel),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
          ]),
        ),
      ]),
    );
  }
}