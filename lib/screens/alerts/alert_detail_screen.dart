// lib/screens/alerts/alert_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert_post.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import 'report_sighting_screen.dart';

class AlertDetailScreen extends StatelessWidget {
  final AlertPost post;
  const AlertDetailScreen({super.key, required this.post});

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

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;
    final t  = context.watch<ThemeProvider>().theme;

    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    final badgeBg     = t.isNight ? const Color(0xFFD5C38B).withOpacity(0.15) : const Color(0xFFD6E4F0);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text(_categoryLabel(post.category, tr),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                color: t.appBarTextColor)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.mediaFiles.isNotEmpty)
              _ImageGallery(images: post.mediaFiles, accentColor: accentColor, t: t, tr: tr)
            else
              _NoPhotoPlaceholder(t: t, category: post.category, tr: tr),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_badgeIcon(post.category), size: 13, color: accentColor),
                        const SizedBox(width: 5),
                        Text(tr.get(_badgeKey(post.category)),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                                color: accentColor, letterSpacing: 1)),
                      ]),
                    ),
                    const Spacer(),
                    if (post.sightingsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: [
                          Icon(Icons.visibility, size: 13, color: t.secondaryText),
                          const SizedBox(width: 4),
                          Text('${post.sightingsCount} ${tr.get('sightings_count')}',
                              style: TextStyle(fontSize: 12, color: t.secondaryText)),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 12),

                  if (post.caseStatus != null && post.caseStatus != 'active')
                    _CaseStatusBanner(status: post.caseStatus!, tr: tr),

                  Text(
                    post.subjectName ?? post.itemDescription ?? post.title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                        color: accentColor),
                  ),
                  if (post.nickname != null)
                    Text('"${post.nickname}"',
                        style: TextStyle(fontSize: 14, color: t.secondaryText,
                            fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),

                  _InfoCard(t: t, children: [
                    if (post.committedCrime != null)
                      _InfoRow(icon: Icons.gavel, label: tr.get('charge'),
                          value: tr.translateCrimeType(post.committedCrime!), t: t),
                    if (post.riskLevel != null)
                      _RiskRow(riskLevel: post.riskLevel!, tr: tr, t: t),
                    if (post.height != null || post.weight != null)
                      _InfoRow(
                        icon: Icons.straighten,
                        label: tr.get('height_weight'),
                        value: '${post.height != null ? post.height! + "cm" : "—"} / ${post.weight != null ? post.weight! + "kg" : "—"}',
                        t: t,
                      ),
                    if (post.dateOfBirth != null)
                      _InfoRow(icon: Icons.cake, label: tr.get('date_of_birth'),
                          value: post.dateOfBirth!, t: t),
                    if (post.age != null)
                      _InfoRow(icon: Icons.person, label: tr.get('age'),
                          value: '${post.age} ${tr.get('years_old')}', t: t),
                    if (post.lastSeenLocation != null)
                      _InfoRow(icon: Icons.location_on, label: tr.get('last_seen'),
                          value: post.lastSeenLocation!, t: t),
                    if (post.lastSeenDate != null)
                      _InfoRow(icon: Icons.calendar_today, label: tr.get('last_seen_date'),
                          value: post.lastSeenDate!, t: t),
                    if (post.clothingDescription != null)
                      _InfoRow(icon: Icons.checkroom, label: tr.get('clothing'),
                          value: post.clothingDescription!, t: t),
                    if (post.locationLost != null)
                      _InfoRow(icon: Icons.location_searching, label: tr.get('location_lost'),
                          value: post.locationLost!, t: t),
                    if (post.contactNumber != null)
                      _InfoRow(icon: Icons.phone, label: tr.get('contact'),
                          value: post.contactNumber!, t: t),
                    if (post.rewardInfo != null)
                      _InfoRow(icon: Icons.monetization_on, label: tr.get('reward'),
                          value: post.rewardInfo!, valueColor: const Color(0xFFD97706), t: t),
                  ]),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.05),
                          blurRadius: 6)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr.get('image_details'),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                              color: accentColor)),
                      const SizedBox(height: 10),
                      Text(post.content,
                          style: TextStyle(fontSize: 14, color: t.primaryText, height: 1.6)),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  if (post.caseStatus == null || post.caseStatus == 'active')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => ReportSightingScreen(post: post))),
                        icon: const Icon(Icons.visibility, size: 20),
                        label: Text(
                          post.category == 'Missing Item'
                              ? tr.get('report_sighting_item')
                              : tr.get('report_sighting'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  if (post.caseStatus == null || post.caseStatus == 'active') ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        tr.get('info_confidential'),
                        style: TextStyle(fontSize: 12, color: t.secondaryText),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  final AppTheme t;
  final String   category;
  final dynamic  tr;
  const _NoPhotoPlaceholder({required this.t, required this.category, required this.tr});

  @override
  Widget build(BuildContext context) {
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    return Container(
      width: double.infinity, height: 200,
      color: t.isNight ? const Color(0xFF1A3A5C).withOpacity(0.4) : accentColor.withOpacity(0.08),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          category == 'Missing Item' ? Icons.inventory_2_outlined : Icons.person,
          size: 64,
          color: accentColor.withOpacity(0.4),
        ),
        const SizedBox(height: 8),
        Text(tr.get('no_photo'),
            style: TextStyle(fontSize: 13, color: accentColor.withOpacity(0.6))),
      ]),
    );
  }
}

class _CaseStatusBanner extends StatelessWidget {
  final String  status;
  final dynamic tr;
  const _CaseStatusBanner({required this.status, required this.tr});

  @override
  Widget build(BuildContext context) {
    final isArrested = status == 'arrested';
    final color   = isArrested ? const Color(0xFF065f46) : const Color(0xFF1e40af);
    final bgColor = isArrested ? const Color(0xFFd1fae5) : const Color(0xFFdbeafe);
    final icon    = isArrested ? Icons.gavel : Icons.check_circle;
    final label   = isArrested ? tr.get('arrested') : tr.get('found_resolved');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('${tr.get('case_status')}: $label',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  final List<AlertMedia> images;
  final Color    accentColor;
  final AppTheme t;
  final dynamic  tr;
  const _ImageGallery({required this.images, required this.accentColor, required this.t, required this.tr});
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
        height: 280,
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
                      color: widget.t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
              errorBuilder: (_, __, ___) => Container(
                color: widget.t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.broken_image, size: 48, color: widget.t.secondaryText),
                  const SizedBox(height: 8),
                  Text(widget.tr.get('image_unavailable'),
                      style: TextStyle(fontSize: 12, color: widget.t.secondaryText)),
                ]),
              ),
            ),
          ),
        ),
      ),
      if (widget.images.length > 1)
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _current == i ? widget.accentColor : Colors.white70,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ),
      if (widget.images.length > 1)
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Text('${_current + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      Positioned(
        bottom: widget.images.length > 1 ? 30 : 12,
        left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
          child: Text(widget.tr.get('tap_to_zoom'),
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ),
      ),
    ]);
  }

  void _openViewer(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ImageViewerScreen(images: widget.images, initial: index),
    ));
  }
}

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
        title: Text('${_current + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.5, maxScale: 4.0,
          child: Center(
            child: Image.network(widget.images[i].url,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 64, color: Colors.white30)),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final AppTheme     t;
  const _InfoCard({required this.children, required this.t});

  @override
  Widget build(BuildContext context) {
    final nonEmpty = children.where((w) => w is! SizedBox).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.05),
            blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final AppTheme t;
  const _InfoRow({required this.icon, required this.label, required this.value,
      required this.t, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: t.secondaryText),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: t.secondaryText,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: valueColor ?? (t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)))),
        ),
      ]),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String   riskLevel;
  final dynamic  tr;
  final AppTheme t;
  const _RiskRow({required this.riskLevel, required this.tr, required this.t});

  @override
  Widget build(BuildContext context) {
    final isHigh   = riskLevel == 'High Risk';
    final isMedium = riskLevel == 'Medium Risk';
    final color   = isHigh ? const Color(0xFFDC2626) : isMedium ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final bgColor = isHigh ? const Color(0xFFFEE2E2) : isMedium ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, size: 16, color: t.secondaryText),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(tr.get('risk_level'),
              style: TextStyle(fontSize: 13, color: t.secondaryText,
                  fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
          child: Text(tr.translateRiskLevel(riskLevel),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ),
      ]),
    );
  }
}