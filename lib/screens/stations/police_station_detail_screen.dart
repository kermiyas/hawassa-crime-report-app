// lib/screens/stations/police_station_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import '../reports/submit_report_screen.dart';

// ── Converted to StatefulWidget so provider reads are always live ─────────
class PoliceStationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> station;
  const PoliceStationDetailScreen({super.key, required this.station});

  @override
  State<PoliceStationDetailScreen> createState() =>
      _PoliceStationDetailScreenState();
}

class _PoliceStationDetailScreenState
    extends State<PoliceStationDetailScreen> {

  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _gold     = Color(0xFFC9A84C);

  // ── Map ───────────────────────────────────────────────────────────────────
  Future<void> _openMap() async {
    final lat  = widget.station['latitude'];
    final lng  = widget.station['longitude'];
    final name =
        Uri.encodeComponent(widget.station['name'] ?? 'Police Station');

    final uris = [
      Uri.parse('google.navigation:q=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)'),
      Uri.parse('https://maps.google.com/?q=$lat,$lng'),
      Uri.parse(
          'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=16'),
    ];

    for (final uri in uris) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        continue;
      }
    }

    try {
      await launchUrl(
        Uri.parse('https://maps.google.com/?q=$lat,$lng'),
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps')),
        );
      }
    }
  }

  Future<void> _callStation() async {
    final phone = widget.station['phone'];
    if (phone == null || (phone as String).isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Auth-gated report ─────────────────────────────────────────────────────
  void _reportIncident() {
    final auth = context.read<AuthProvider>();

    if (auth.isGuest) {
      AuthGate.require(context, featureName: 'report an incident');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitReportScreen(
          preselectedStationId: widget.station['id'] as int? ??
              _stationIdFromName(
                  widget.station['name'] as String? ?? ''),
          preselectedStationName:
              widget.station['name'] as String? ?? '',
          preselectedStationAddress:
              widget.station['address'] as String? ?? '',
        ),
      ),
    );
  }

  int _stationIdFromName(String name) => name.hashCode.abs();

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<AuthProvider>().isGuest;

    const bool isNight = false;
    const bg      = Color(0xFFF0F4F8);
    const cardBg  = Colors.white;
    const textClr = _navy;
    const subClr  = Color(0xFF7A90B0);

    final hasPhone =
        (widget.station['phone'] as String?)?.isNotEmpty ?? false;
    final hasCoords = widget.station['latitude'] != null &&
        widget.station['longitude'] != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          slivers: [

            // ── Hero app bar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: _navyDark,
              leading: IconButton(
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D1B2A),
                        Color(0xFF1A3A5C),
                        Color(0xFF1E4D7B),
                      ],
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(top: -30, right: -30,
                      child: Container(width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 2)))),
                    Positioned(bottom: -20, left: -20,
                      child: Container(width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _gold.withOpacity(0.1),
                            width: 1.5)))),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _gold.withOpacity(0.5),
                                width: 2.5)),
                            child: const Icon(
                                Icons.account_balance_rounded,
                                size: 38, color: _gold),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40),
                            child: Text(
                              widget.station['name'] ?? 'Police Station',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if ((widget.station['district'] as String?)
                                  ?.isNotEmpty ??
                              false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _gold.withOpacity(0.4))),
                              child: Text(
                                widget.station['district'],
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _infoCard(cardBg, textClr, subClr),
                    const SizedBox(height: 16),

                    if (hasCoords) _mapCard(cardBg),
                    if (hasCoords) const SizedBox(height: 16),

                    Row(children: [
                      if (hasCoords) ...[
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.map_rounded,
                            label: 'Open in Maps',
                            color: _navy,
                            onTap: _openMap,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.phone_rounded,
                          label: hasPhone ? 'Call Station' : 'No Phone',
                          color: hasPhone
                              ? const Color(0xFF27AE60)
                              : Colors.grey,
                          onTap: hasPhone ? _callStation : null,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ── Report button — locked for guests ─────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _reportIncident,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isGuest ? _gold.withOpacity(0.75) : _gold,
                          foregroundColor: _navyDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          isGuest
                              ? Icons.lock_rounded
                              : Icons.campaign_rounded,
                          size: 20),
                        label: Text(
                          isGuest
                              ? 'Sign In to Report an Incident'
                              : 'Report an Incident Here',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3)),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────
  Widget _infoCard(Color cardBg, Color textClr, Color subClr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.location_on_rounded,
              widget.station['address'] ?? 'Address not available',
              textClr),
          if ((widget.station['phone'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 14),
            _infoRow(Icons.phone_rounded,
                widget.station['phone'], textClr),
          ],
          if ((widget.station['district'] as String?)?.isNotEmpty ??
              false) ...[
            const SizedBox(height: 14),
            _infoRow(Icons.map_outlined,
                'District: ${widget.station['district']}', textClr),
          ],
          const SizedBox(height: 14),
          _infoRow(Icons.schedule_rounded,
              'Available 24/7 for emergency reports', textClr),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color textClr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: _navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: textClr,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
          ),
        ),
      ],
    );
  }

  // ── Map card ──────────────────────────────────────────────────────────────
  Widget _mapCard(Color cardBg) {
    final lat = widget.station['latitude'];
    final lng = widget.station['longitude'];

    return GestureDetector(
      onTap: _openMap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          Image.network(
            'https://staticmap.openstreetmap.de/staticmap.php'
            '?center=$lat,$lng&zoom=15&size=400x160'
            '&markers=$lat,$lng,red-pushpin',
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE8F0FA),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 36, color: _navy.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text('Tap to view on Maps',
                        style: TextStyle(
                            color: _navy.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(Icons.open_in_new_rounded,
                    size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('Open Maps',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withOpacity(0.3), width: 1.5)),
        child: Column(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      ),
    );
  }
}