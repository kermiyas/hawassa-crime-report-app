// lib/screens/reports/my_reports_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../constants/api_constants.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class MyReport {
  final int id;
  final String title, category, description, status, createdAt;
  final String? locationAddress, areaName, adminNotes, reporterType, incidentDate, incidentTime;
  final List<Map<String, dynamic>> evidence;

  MyReport({
    required this.id, required this.title, required this.category,
    required this.description, required this.status, required this.createdAt,
    required this.evidence, this.locationAddress, this.areaName,
    this.adminNotes, this.reporterType, this.incidentDate, this.incidentTime,
  });

  factory MyReport.fromJson(Map<String, dynamic> j) {
    final ev = (j['evidence'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    return MyReport(
      id: j['id'], title: j['title'] ?? 'Untitled', category: j['category'] ?? 'other',
      description: j['description'] ?? '', status: j['status'] ?? 'submitted',
      locationAddress: j['location_address'], areaName: j['area_name'],
      adminNotes: j['admin_notes'], reporterType: j['reporter_type'],
      incidentDate: j['incident_date'], incidentTime: j['incident_time'],
      createdAt: j['created_at'] ?? '', evidence: ev,
    );
  }
}

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});
  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<MyReport> _all      = [];
  bool           _loading  = true;
  bool           _isOffline = false;
  String         _filter   = 'all';

  final _filterKeys = ['all', 'submitted', 'under_review', 'active_case', 'resolved', 'rejected'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final cached = await CacheService.load('my_reports');
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as List;
        if (mounted) setState(() {
          _all     = data.map((j) => MyReport.fromJson(j)).toList();
          _loading = false;
        });
      } catch (_) {}
    }

    try {
      final res = await ApiService.getWithAuth('/reports');
      if (res.statusCode == 200) {
        await CacheService.save('my_reports', res.body);
        final data = jsonDecode(res.body) as List;
        if (mounted) setState(() {
          _all      = data.map((j) => MyReport.fromJson(j)).toList();
          _loading  = false;
          _isOffline = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _loading   = false;
        _isOffline = _all.isNotEmpty;
      });
    }
  }

  List<MyReport> get _filtered => _filter == 'all' ? _all : _all.where((r) => r.status == _filter).toList();

  String _filterLabel(String key, AppLocalizations tr) {
    switch (key) {
      case 'all': return tr.get('all'); case 'submitted': return tr.get('submitted');
      case 'under_review': return tr.get('under_review'); case 'active_case': return tr.get('active_case');
      case 'resolved': return tr.get('resolved'); case 'rejected': return tr.get('rejected');
      default: return key;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted': return const Color(0xFF64748B); case 'under_review': return const Color(0xFFD97706);
      case 'active_case': return const Color(0xFF1976D2); case 'resolved': return const Color(0xFF059669);
      case 'rejected': return const Color(0xFFDC2626); default: return const Color(0xFF64748B);
    }
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'theft': return const Color(0xFF1976D2); case 'assault': return const Color(0xFFDC2626);
      case 'robbery': return const Color(0xFFDC2626); case 'vandalism': return const Color(0xFF7C3AED);
      case 'missing_person': return const Color(0xFFD97706);
      case 'suspicious_activity': return const Color(0xFFF59E0B);
      default: return const Color(0xFF486D99);
    }
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'theft': return Icons.no_backpack_outlined; case 'assault': return Icons.personal_injury_outlined;
      case 'robbery': return Icons.directions_run; case 'vandalism': return Icons.broken_image_outlined;
      case 'missing_person': return Icons.person_search_outlined;
      case 'suspicious_activity': return Icons.visibility_outlined;
      default: return Icons.report_outlined;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$h:${dt.minute.toString().padLeft(2,'0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final tr       = context.watch<LanguageProvider>().tr;
    final t        = context.watch<ThemeProvider>().theme;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: Column(children: [
        // Filter chips
        Container(
          color: t.appBarColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: _filterKeys.map((key) {
                final active = _filter == key;
                return GestureDetector(
                  onTap: () => setState(() => _filter = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? (t.isNight ? t.navSelectedColor : const Color(0xFF486D99))
                          : (t.isNight ? Colors.white.withOpacity(0.15) : t.scaffoldBg),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_filterLabel(key, tr),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: active
                            ? (t.isNight ? t.appBarColor : Colors.white)
                            : (t.isNight ? Colors.white : const Color(0xFF486D99)))),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        if (_isOffline) _offlineBanner(tr),

        // Count bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: t.scaffoldBg,
          child: Row(children: [
            Text(
              '${filtered.length} ${tr.get(filtered.length != 1 ? 'reports_count' : 'report_count')}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.primaryText),
            ),
            if (_filter != 'all') ...[
              const SizedBox(width: 6),
              Text('· ${_filterLabel(_filter, tr)}',
                  style: TextStyle(fontSize: 13, color: t.secondaryText)),
            ],
          ]),
        ),

        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: t.buttonColor))
              : filtered.isEmpty
                  ? _buildEmpty(tr, t)
                  : RefreshIndicator(
                      color: t.buttonColor, onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildCard(filtered[i], tr, t),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildCard(MyReport r, AppLocalizations tr, AppTheme t) {
    final statusColor = _statusColor(r.status);
    final catIcon     = _categoryIcon(r.category);

    return GestureDetector(
      onTap: () => _openDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: t.cardColor, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: t.isNight
                      ? const Color(0xFFD5C38B).withOpacity(0.12)
                      : const Color(0xFF486D99).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(catIcon, color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(tr.translateCrimeType(r.title),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: t.primaryText))),
                  const SizedBox(width: 6),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: t.secondaryText),
                    const SizedBox(width: 4),
                    Text(_formatDate(r.createdAt), style: TextStyle(fontSize: 11, color: t.secondaryText)),
                  ]),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 13, color: t.secondaryText),
                  const SizedBox(width: 3),
                  Expanded(child: Text(
                    r.areaName ?? r.locationAddress ?? tr.get('location_not_specified'),
                    style: TextStyle(fontSize: 12, color: t.secondaryText),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: 8),
                  Text('· ${_formatTime(r.createdAt)}',
                      style: TextStyle(fontSize: 11, color: t.secondaryText)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Text('${tr.get('status')}: ',
                      style: TextStyle(fontSize: 12, color: t.secondaryText, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(_filterLabel(r.status, tr),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                  if (r.evidence.isNotEmpty) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.buttonColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.attach_file_rounded, size: 12, color: t.iconColor),
                        const SizedBox(width: 3),
                        Text('${r.evidence.length}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.primaryText)),
                      ]),
                    ),
                  ],
                ]),
              ])),
            ]),
          ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.dividerColor))),
            child: TextButton(
              onPressed: () => _openDetail(r),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(tr.get('view_details'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.primaryText)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: t.iconColor),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _openDetail(MyReport r) {
    final langCode = Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    final t        = Provider.of<ThemeProvider>(context, listen: false).theme;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ReportDetailSheet(report: r, languageCode: langCode, theme: t),
    );
  }

  Widget _offlineBanner(AppLocalizations tr) => Container(
    color: const Color(0xFFD97706),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
      const SizedBox(width: 8),
      Text(tr.get('offline_cached_data'),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      const Spacer(),
      GestureDetector(
        onTap: _load,
        child: Text(tr.get('retry'),
            style: const TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
      ),
    ]),
  );

  Widget _buildEmpty(AppLocalizations tr, AppTheme t) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(color: t.buttonColor.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(Icons.description_outlined, size: 44, color: t.iconColor),
      ),
      const SizedBox(height: 16),
      Text(tr.get('no_reports'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.primaryText)),
      const SizedBox(height: 8),
      Text(
        _filter == 'all' ? tr.get('no_reports_yet') : '${tr.get('no_filter_reports')} ${_filterLabel(_filter, tr)}',
        style: TextStyle(fontSize: 13, color: t.secondaryText), textAlign: TextAlign.center,
      ),
    ]));
  }
}

class _ReportDetailSheet extends StatelessWidget {
  final MyReport report;
  final String   languageCode;
  final AppTheme theme;
  const _ReportDetailSheet({required this.report, required this.languageCode, required this.theme});

  AppLocalizations get tr => AppLocalizations(languageCode);
  AppTheme         get t  => theme;

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted': return const Color(0xFF64748B); case 'under_review': return const Color(0xFFD97706);
      case 'active_case': return const Color(0xFF1976D2); case 'resolved': return const Color(0xFF059669);
      case 'rejected': return const Color(0xFFDC2626); default: return const Color(0xFF64748B);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'submitted': return tr.get('submitted'); case 'under_review': return tr.get('under_review');
      case 'active_case': return tr.get('active_case'); case 'resolved': return tr.get('resolved');
      case 'rejected': return tr.get('rejected'); default: return s;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$h:${dt.minute.toString().padLeft(2,'0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return ''; }
  }

  String _translateReporterType(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'victim': return tr.get('victim'); case 'witness': return tr.get('witness');
      case 'anonymous': return tr.get('anonymous'); default: return raw ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(color: t.scaffoldBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        // Header — gold in night mode, #486D99 in day mode
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Icon(Icons.description_rounded,
                color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(tr.get('report_details'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white))),
            IconButton(
              icon: Icon(Icons.close,
                  color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Status banner
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_statusIcon(report.status), color: statusColor, size: 22),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr.get('current_status'), style: TextStyle(fontSize: 11, color: t.secondaryText)),
                  Text(_statusLabel(report.status),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: statusColor)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),

            _card(children: [
              _row(Icons.title_rounded, tr.get('report_title'), tr.translateCrimeType(report.title)),
              _divider(),
              _row(Icons.category_outlined, tr.get('category'), tr.translateCrimeType(report.category)),
              _divider(),
              _row(Icons.person_outline, tr.get('reporter_type'), _translateReporterType(report.reporterType)),
              _divider(),
              _row(Icons.calendar_today_outlined, tr.get('submitted_date'),
                  '${_formatDate(report.createdAt)}  ${_formatTime(report.createdAt)}'),
              if (report.incidentDate != null) ...[
                _divider(),
                _row(Icons.event_outlined, tr.get('incident_date'),
                    '${report.incidentDate}  ${report.incidentTime ?? ''}'),
              ],
            ]),
            const SizedBox(height: 12),

            if (report.locationAddress != null || report.areaName != null)
              _section(tr.get('location'), Icons.location_on_outlined, const Color(0xFF1976D2),
                  '${report.areaName ?? ''}${report.areaName != null && report.locationAddress != null ? '\n' : ''}${report.locationAddress ?? ''}'),

            _section(tr.get('description'), Icons.description_outlined, t.buttonColor, report.description),

            if (report.adminNotes != null && report.adminNotes!.isNotEmpty)
              _section(tr.get('officer_notes'), Icons.shield_outlined, const Color(0xFF059669), report.adminNotes!),

            if (report.evidence.isNotEmpty) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.attach_file_rounded, size: 16,
                        color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)),
                    const SizedBox(width: 6),
                    Text('${tr.get('evidence')} (${report.evidence.length})',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                            color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99))),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8,
                      children: report.evidence.map((e) => _evidenceThumb(context, e)).toList()),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ]),
        )),
      ]),
    );
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'resolved': return Icons.check_circle_outline; case 'active_case': return Icons.local_police_outlined;
      case 'under_review': return Icons.hourglass_top_outlined; case 'rejected': return Icons.cancel_outlined;
      default: return Icons.upload_outlined;
    }
  }

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _section(String title, IconData icon, Color color, String content) {
    final headerColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: headerColor), const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: headerColor)),
        ]),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.5)),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    final accent = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: accent), const SizedBox(width: 8),
        SizedBox(width: 90, child: Text(label,
            style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, color: t.primaryText, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1, color: t.dividerColor);

  Widget _evidenceThumb(BuildContext context, Map<String, dynamic> e) {
    final isImage = (e['file_type'] ?? '') == 'image';
    final url     = '${ApiConstants.storageUrl}/${e['file_path']}';
    if (isImage) {
      return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => _ImageViewer(url: url, tr: tr))),
        child: ClipRRect(borderRadius: BorderRadius.circular(8),
          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: 80, height: 80,
              decoration: BoxDecoration(color: t.scaffoldBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.broken_image_outlined, color: t.secondaryText))),
        ),
      );
    }
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(color: t.buttonColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon((e['file_type'] == 'video') ? Icons.videocam_outlined : Icons.audio_file_outlined,
            color: t.iconColor, size: 28),
        const SizedBox(height: 4),
        Text(e['file_type'] ?? 'file',
            style: TextStyle(fontSize: 10, color: t.primaryText, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String url;
  final AppLocalizations tr;
  const _ImageViewer({required this.url, required this.tr});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white,
        title: Text(tr.get('evidence'), style: const TextStyle(fontSize: 15))),
    body: Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0,
        child: Image.network(url,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60)))),
  );
}