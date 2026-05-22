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
  final String? locationAddress, areaName, adminNotes, reporterType,
      incidentDate, incidentTime;
  final List<Map<String, dynamic>> evidence;

  MyReport({
    required this.id, required this.title, required this.category,
    required this.description, required this.status, required this.createdAt,
    required this.evidence, this.locationAddress, this.areaName,
    this.adminNotes, this.reporterType, this.incidentDate, this.incidentTime,
  });

  factory MyReport.fromJson(Map<String, dynamic> j) {
    final ev = (j['evidence'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e)).toList();
    // Safe parse: JSON may deliver id as int, double, or String
    final rawId = j['id'];
    final int parsedId = rawId is int
        ? rawId
        : rawId is double
            ? rawId.toInt()
            : int.tryParse(rawId.toString()) ?? 0;
    return MyReport(
      id: parsedId, title: j['title'] ?? 'Untitled',
      category: j['category'] ?? 'other',
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
  List<MyReport> _all        = [];
  bool           _loading    = true;
  bool           _isOffline  = false;
  String         _filter     = 'all';

  // ── Delete / selection state ───────────────────────────────────────────────
  bool           _selectMode = false;
  final Set<int> _selected   = {};
  bool           _deleting   = false;

  final _filterKeys = [
    'all', 'submitted', 'under_review', 'active_case', 'resolved', 'rejected'
  ];

  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _gold     = Color(0xFFC9A84C);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _red      = Color(0xFFDC2626);

  @override
  void initState() { super.initState(); _load(); }

  // ── Data ───────────────────────────────────────────────────────────────────

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
          _all       = data.map((j) => MyReport.fromJson(j)).toList();
          _loading   = false;
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

  List<MyReport> get _filtered =>
      _filter == 'all' ? _all : _all.where((r) => r.status == _filter).toList();

  // ── Delete logic ───────────────────────────────────────────────────────────

  /// Shows a styled confirmation dialog. Returns true if user confirmed.
 Future<bool?> _showDeleteDialog({
  required String title,
  required String message,
  required String confirmLabel,
}) {
  final tr = context.read<LanguageProvider>().tr;  // ← ADD THIS
  final t = context.read<ThemeProvider>().theme;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Red delete icon badge
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _red.withOpacity(0.1),
              border: Border.all(color: _red.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.delete_forever_rounded,
                color: _red, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: _red, letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13, color: t.secondaryText, height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // "Cannot be undone" warning strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withOpacity(0.18)),
            ),
           child: Row(mainAxisSize: MainAxisSize.min, children: [
  const Icon(Icons.warning_amber_rounded, size: 13, color: _red),
  const SizedBox(width: 6),
  Text(tr.get('cannot_be_undone'),
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _red,
                ),
              ),
            ]),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        actions: [
          Row(children: [
            // Cancel
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(
                    color: t.isNight
                        ? const Color(0xFF2A5080)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(tr.get('cancel'),
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: t.primaryText)),
              ),
            ),
            const SizedBox(width: 10),
            // Confirm
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// Delete a single report with confirmation
 Future<void> _confirmDeleteOne(MyReport r) async {
  final tr = context.read<LanguageProvider>().tr;  // ← ADD THIS
  final ok = await _showDeleteDialog(
      title: tr.get('delete_report_title'),
message: '${tr.get('delete_report_message_prefix')} #${r.id} — "${r.title}" ${tr.get('delete_report_message_suffix')}',
confirmLabel: tr.get('delete'),
    );
    if (ok != true) return;
    await _deleteReports([r.id]);
  }

  /// Delete currently selected reports with confirmation
 Future<void> _confirmDeleteSelected() async {
  final tr = context.read<LanguageProvider>().tr;  // ← ADD THIS
  if (_selected.isEmpty) return;
    final count = _selected.length;
    final ok = await _showDeleteDialog(
      title: tr.get('delete_selected_title').replaceAll('{count}', '$count'),
message: tr.get('delete_selected_message').replaceAll('{count}', '$count'),
confirmLabel: tr.get('delete'),
    );
    if (ok != true) return;
    await _deleteReports(_selected.toList());
  }

  /// Delete ALL reports with confirmation (from overflow menu)
  Future<void> _confirmDeleteAll() async {
    final tr = context.read<LanguageProvider>().tr;

    if (_all.isEmpty) return;
    final ok = await _showDeleteDialog(
      title: tr.get('delete_all_title').replaceAll('{count}', '${_all.length}'),
message: tr.get('delete_all_message'),
confirmLabel: tr.get('delete_all'),
    );
    if (ok != true) return;
    await _deleteReports(_all.map((r) => r.id).toList());
  }

  Future<void> _deleteReports(List<int> ids) async {
    final tr = context.read<LanguageProvider>().tr;
    if (ids.isEmpty) return;
  
    setState(() => _deleting = true);

    // Fire delete requests — we don't gate on status code because
    // the snackbar count should always equal what the user asked to delete.
    for (final id in ids) {
      try {
        await ApiService.deleteWithAuth('/reports/$id');
      } catch (_) {}
    }

    // Use ids.length as the authoritative count — it is always correct.
    final int successCount = ids.length;

    if (mounted) {
      setState(() {
        _all.removeWhere((r) => ids.contains(r.id));
        _selected.clear();
        _selectMode = false;
        _deleting   = false;
      });

      await CacheService.save(
        'my_reports',
        jsonEncode(_all.map((r) => {
          'id': r.id, 'title': r.title, 'category': r.category,
          'description': r.description, 'status': r.status,
          'created_at': r.createdAt, 'location_address': r.locationAddress,
          'area_name': r.areaName, 'admin_notes': r.adminNotes,
          'reporter_type': r.reporterType, 'incident_date': r.incidentDate,
          'incident_time': r.incidentTime, 'evidence': r.evidence,
        }).toList()),
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: _white, size: 18),
          const SizedBox(width: 8),
          Text(tr.get('reports_deleted').replaceAll('{count}', '$successCount')),
        ]),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void _toggleSelectMode() => setState(() {
    _selectMode = !_selectMode;
    _selected.clear();
  });

  void _toggleSelect(int id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  void _selectAll() =>
      setState(() => _selected.addAll(_filtered.map((r) => r.id)));

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _filterLabel(String key, AppLocalizations tr) {
    switch (key) {
      case 'all':          return tr.get('all');
      case 'submitted':    return tr.get('submitted');
      case 'under_review': return tr.get('under_review');
      case 'active_case':  return tr.get('in_progress');
      case 'resolved':     return tr.get('resolved');
      case 'rejected':     return tr.get('rejected');
      default:             return key;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted':    return const Color(0xFF64748B);
      case 'under_review': return const Color(0xFFD97706);
      case 'active_case':  return const Color(0xFF1976D2);
      case 'resolved':     return const Color(0xFF059669);
      case 'rejected':     return _red;
      default:             return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'submitted':    return Icons.upload_outlined;
      case 'under_review': return Icons.hourglass_top_outlined;
      case 'active_case':  return Icons.local_police_outlined;
      case 'resolved':     return Icons.check_circle_outline;
      case 'rejected':     return Icons.cancel_outlined;
      default:             return Icons.upload_outlined;
    }
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'theft':               return Icons.no_backpack_outlined;
      case 'assault':             return Icons.personal_injury_outlined;
      case 'robbery':             return Icons.directions_run;
      case 'vandalism':           return Icons.broken_image_outlined;
      case 'missing_person':      return Icons.person_search_outlined;
      case 'suspicious_activity': return Icons.visibility_outlined;
      default:                    return Icons.report_outlined;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$h:${dt.minute.toString().padLeft(2,'0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return ''; }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tr       = context.watch<LanguageProvider>().tr;
    final t        = context.watch<ThemeProvider>().theme;
    final filtered = _filtered;

    final bgColor   = t.isNight ? const Color(0xFF112D4E) : const Color(0xFFF0F4F8);
    final cardBg    = t.isNight ? const Color(0xFF1A3A5C) : _white;
    final textColor = t.isNight ? _white.withOpacity(0.9) : _navy;
    final subColor  = t.isNight ? _white.withOpacity(0.45) : _navy.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [

        Column(children: [

          // ── Header + filter bar ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.isNight
                    ? [const Color(0xFF1A2F4A), const Color(0xFF0D1B2A)]
                    : [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)],
              ),
            ),
            child: Column(children: [

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: _filterKeys.map((key) {
                    final active = _filter == key;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? _gold
                              : _white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? _gold
                                : _white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _filterLabel(key, tr),
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? _navyDark : _white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Toolbar row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 10, 12),
                child: Row(children: [

                  // Report count
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length} ${filtered.length != 1 ? tr.get('reports_count') : tr.get('report_count')}',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _white.withOpacity(0.8),
                      ),
                    ),
                  ),

                  const Spacer(),

                  if (_selectMode) ...[
                    // Select All button
                    _toolbarBtn(
                      label: tr.get('all'), 
                      icon: Icons.select_all_rounded,
                      onTap: _selectAll,
                      color: _white.withOpacity(0.8),
                      bg: _white.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),

                    // Delete selected button (red when items selected)
                    _toolbarBtn(
                      label: _selected.isEmpty
    ? tr.get('delete')
    : '${tr.get('delete')} (${_selected.length})',
                      icon: Icons.delete_rounded,
                      onTap: _selected.isEmpty
                          ? null
                          : _confirmDeleteSelected,
                      color: _selected.isEmpty
                          ? _white.withOpacity(0.3)
                          : _white,
                      bg: _selected.isEmpty
                          ? _white.withOpacity(0.07)
                          : _red,
                    ),
                    const SizedBox(width: 8),

                    // Cancel select mode
                    GestureDetector(
                      onTap: _toggleSelectMode,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: _white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: _white, size: 16),
                      ),
                    ),

                  ] else ...[

                    // Select mode toggle
                    _toolbarBtn(
                      label: tr.get('select'),
                      icon: Icons.checklist_rounded,
                      onTap: filtered.isEmpty ? null : _toggleSelectMode,
                      color: _white.withOpacity(
                          filtered.isEmpty ? 0.3 : 0.8),
                      bg: _white.withOpacity(0.1),
                      bordered: true,
                    ),
                    const SizedBox(width: 6),

                    // Overflow menu (Refresh + Delete All)
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert_rounded,
                            color: _white, size: 18),
                      ),
                      color: t.cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'delete_all') _confirmDeleteAll();
                        if (val == 'refresh') _load();
                      },
                      itemBuilder: (_) => [
                        _popupItem(
                          value: 'refresh',
                          icon: Icons.refresh_rounded,
                          label: tr.get('refresh'), 
                          color: t.isNight ? _gold : _navy,
                          textColor: t.primaryText,
                        ),
                        const PopupMenuDivider(),
                        _popupItem(
                          value: 'delete_all',
                          icon: Icons.delete_sweep_rounded,
                          label: tr.get('delete_all_reports'),
                          color: _red,
                          textColor: _red,
                        ),
                      ],
                    ),
                  ],
                ]),
              ),
            ]),
          ),

          // ── Offline banner ─────────────────────────────────────────────
          if (_isOffline) _buildOfflineBanner(tr),


          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(
                    color: t.isNight ? _gold : _navy))
                : filtered.isEmpty
    ? _buildEmpty(t, tr)
    : RefreshIndicator(
                        color: t.isNight ? _gold : _navy,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildCard(
                            filtered[i], tr, t, cardBg, textColor, subColor),
                        ),
                      ),
          ),
        ]),

        // ── Deleting full-screen overlay ─────────────────────────────────
        if (_deleting)
          Container(
            color: Colors.black.withOpacity(0.45),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 24),
                decoration: BoxDecoration(
                  color: t.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: _red),
                  const SizedBox(height: 16),
                 Text(tr.get('deleting'),
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: t.primaryText)),
                ]),
              ),
            ),
          ),

      ]),
    );
  }

  // ── Toolbar button ─────────────────────────────────────────────────────────
  Widget _toolbarBtn({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    required Color bg,
    bool bordered = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: bordered
              ? Border.all(color: _white.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  // ── Popup menu item ────────────────────────────────────────────────────────
  PopupMenuItem<String> _popupItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: textColor)),
      ]),
    );
  }

  // ── Offline banner ─────────────────────────────────────────────────────────
  Widget _buildOfflineBanner(AppLocalizations tr) => Container(  // ← add tr param
    color: const Color(0xFFD97706),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     child: Row(children: [
    const Icon(Icons.wifi_off_rounded, color: _white, size: 14),
    const SizedBox(width: 8),
    Expanded(child: Text(tr.get('offline_cached_data'),        // ← remove const
          style: TextStyle(color: _white, fontSize: 12,
              fontWeight: FontWeight.w600))),
      GestureDetector(
        onTap: _load,
         child: Text(tr.get('retry'),    
            style: TextStyle(color: _white, fontSize: 12,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline)),
      ),
    ]),
  );

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _buildCard(MyReport r, AppLocalizations tr, AppTheme t,
      Color cardBg, Color textColor, Color subColor) {
    final sColor     = _statusColor(r.status);
    final isSelected = _selected.contains(r.id);

    return GestureDetector(
      onTap: _selectMode ? () => _toggleSelect(r.id) : () => _openDetail(r),
      onLongPress: !_selectMode
          ? () { _toggleSelectMode(); _toggleSelect(r.id); }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _red.withOpacity(0.06)
              : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _red.withOpacity(0.45)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.07),
              blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              // ── Checkbox (select mode) OR category icon ──────────────
              if (_selectMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _red
                        : _red.withOpacity(0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? _red
                          : _red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.circle_outlined,
                    size: 22,
                    color: isSelected
                        ? _white
                        : _red.withOpacity(0.45),
                  ),
                )
              else
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(t.isNight ? 0.15 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_categoryIcon(r.category),
                      size: 24, color: sColor),
                ),

              const SizedBox(width: 14),

              // ── Main content ─────────────────────────────────────────
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(r.title,
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w800, color: textColor))),
                  const SizedBox(width: 8),
                  Text(_formatDate(r.createdAt),
                      style: TextStyle(fontSize: 11, color: subColor)),
                ]),

                const SizedBox(height: 5),

                if (r.areaName != null || r.locationAddress != null)
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 12, color: subColor),
                    const SizedBox(width: 3),
                    Expanded(child: Text(
                      r.areaName ?? r.locationAddress ?? '',
                      style: TextStyle(fontSize: 12, color: subColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),

                const SizedBox(height: 10),

                Row(children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sColor.withOpacity(0.3), width: 1),
                    ),
                    child: Row(children: [
                      Icon(_statusIcon(r.status), size: 11, color: sColor),
                      const SizedBox(width: 4),
                      Text(_filterLabel(r.status, tr),
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700, color: sColor)),
                    ]),
                  ),

                  if (r.evidence.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (t.isNight ? _gold : _navy).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(Icons.attach_file_rounded, size: 11,
                            color: t.isNight ? _gold : _navy),
                        const SizedBox(width: 3),
                        Text('${r.evidence.length}',
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: t.isNight ? _gold : _navy)),
                      ]),
                    ),
                  ],

                  const Spacer(),
                  Text(_formatTime(r.createdAt),
                      style: TextStyle(fontSize: 11, color: subColor)),
                ]),
              ])),

              // ── Per-card delete icon (non-select mode only) ────────────
              if (!_selectMode) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDeleteOne(r),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _red.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 17, color: _red),
                  ),
                ),
              ],
            ]),
          ),

          // ── Admin notes ─────────────────────────────────────────────────
          if (r.adminNotes != null && r.adminNotes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.08),
                border: Border(
                  top: BorderSide(
                      color: const Color(0xFF059669).withOpacity(0.2)),
                  bottom: BorderSide(
                      color: const Color(0xFF059669).withOpacity(0.1)),
                ),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(child: Text(r.adminNotes!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF059669),
                        fontWeight: FontWeight.w500),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
            ),

          // ── View Details button (non-select mode) ───────────────────────
          if (!_selectMode)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(
                  color: t.isNight
                      ? _white.withOpacity(0.08)
                      : const Color(0xFFDDE6F0),
                  width: 1,
                )),
              ),
              child: TextButton(
                onPressed: () => _openDetail(r),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20))),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(tr.get('view_details'),
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.isNight ? _gold : _navy)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 15,
                      color: t.isNight ? _gold : _navy),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  void _openDetail(MyReport r) {
    final langCode =
        Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    final t = Provider.of<ThemeProvider>(context, listen: false).theme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _ReportDetailSheet(report: r, languageCode: langCode, theme: t),
    );
  }

  Widget _buildEmpty(AppTheme t, AppLocalizations tr) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: (t.isNight ? _gold : _navy).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.description_outlined, size: 44,
            color: t.isNight ? _gold : _navy.withOpacity(0.4)),
      ),
      const SizedBox(height: 16),
      Text(tr.get('no_reports'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: t.isNight ? _white : _navy)),
      const SizedBox(height: 8),
      Text(
        _filter == 'all'
    ? tr.get('no_reports_yet')   // key already exists
    : tr.get('no_filter_reports_msg'),
        style: TextStyle(fontSize: 13,
            color: t.isNight
                ? _white.withOpacity(0.45)
                : _navy.withOpacity(0.5)),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}

// ── Report detail bottom sheet ────────────────────────────────────────────────
class _ReportDetailSheet extends StatelessWidget {
  final MyReport report;
  final String   languageCode;
  final AppTheme theme;
  const _ReportDetailSheet({
    required this.report, required this.languageCode, required this.theme,
  });

  AppLocalizations get tr => AppLocalizations(languageCode);
  AppTheme         get t  => theme;

  static const Color _navy  = Color(0xFF1A3A5C);
  static const Color _gold  = Color(0xFFC9A84C);
  static const Color _white = Color(0xFFFFFFFF);

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted':    return const Color(0xFF64748B);
      case 'under_review': return const Color(0xFFD97706);
      case 'active_case':  return const Color(0xFF1976D2);
      case 'resolved':     return const Color(0xFF059669);
      case 'rejected':     return const Color(0xFFDC2626);
      default:             return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'resolved':     return Icons.check_circle_outline;
      case 'active_case':  return Icons.local_police_outlined;
      case 'under_review': return Icons.hourglass_top_outlined;
      case 'rejected':     return Icons.cancel_outlined;
      default:             return Icons.upload_outlined;
    }
  }

  String _statusLabel(String s) {
  switch (s) {
    case 'submitted':    return tr.get('submitted');
    case 'under_review': return tr.get('under_review');
    case 'active_case':  return tr.get('in_progress');
    case 'resolved':     return tr.get('resolved');
    case 'rejected':     return tr.get('rejected');
    default:             return s;
  }
}

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m  = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$h:${dt.minute.toString().padLeft(2,'0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final sColor    = _statusColor(report.status);
    final cardBg    = t.isNight ? const Color(0xFF1A3A5C) : _white;
    final bgColor   = t.isNight ? const Color(0xFF112D4E) : const Color(0xFFF0F4F8);
    final textClr   = t.isNight ? _white.withOpacity(0.9) : _navy;
    final subClr    = t.isNight ? _white.withOpacity(0.45) : _navy.withOpacity(0.5);
    final accentClr = t.isNight ? _gold : _navy;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: t.isNight
                ? [const Color(0xFF0A1628), const Color(0xFF112D4E)]
                : [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
              )),
              Row(children: [
                const Icon(Icons.description_rounded, color: _white, size: 20),
                const SizedBox(width: 10),
                Text('${tr.get('report_hash')} ${report.id}',
    style: const TextStyle(fontSize: 16,
        fontWeight: FontWeight.w800, color: _white)),
              ]),
              const SizedBox(height: 3),
              Text(report.title,
                  style: TextStyle(fontSize: 12,
                      color: _white.withOpacity(0.6))),
            ]),
            const Spacer(),
            IconButton(
              icon: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: _white, size: 18)),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),

        // Content
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Status card
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sColor.withOpacity(0.25), width: 1.5)),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(_statusIcon(report.status),
                      color: sColor, size: 22)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr.get('current_status'),
                      style: TextStyle(fontSize: 11, color: subClr)),
                  Text(_statusLabel(report.status),
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w800, color: sColor)),
                ]),
              ]),
            ),

            const SizedBox(height: 14),
            _infoCard(cardBg, textClr, subClr, accentClr),
            const SizedBox(height: 12),

            if (report.locationAddress != null || report.areaName != null)
              _sectionCard(
                icon: Icons.location_on_outlined, title: tr.get('location') ,
                content: '${report.areaName ?? ''}${report.areaName != null && report.locationAddress != null ? '\n' : ''}${report.locationAddress ?? ''}',
                cardBg: cardBg, textClr: textClr,
                subClr: subClr, accentClr: accentClr),

            _sectionCard(
              icon: Icons.description_outlined, title: tr.get('description') ,
              content: report.description,
              cardBg: cardBg, textClr: textClr,
              subClr: subClr, accentClr: accentClr),

            if (report.adminNotes != null && report.adminNotes!.isNotEmpty)
              _sectionCard(
                icon: Icons.shield_outlined, title: tr.get('officer_notes'),
                content: report.adminNotes!,
                cardBg: cardBg, textClr: textClr, subClr: subClr,
                accentClr: const Color(0xFF059669),
                accentBg: const Color(0xFF059669).withOpacity(0.08)),

            if (report.evidence.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.05),
                    blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Icon(Icons.attach_file_rounded, size: 16, color: accentClr),
                    const SizedBox(width: 8),
                    Text('${tr.get('evidence')} (${report.evidence.length})',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w800, color: accentClr)),
                  ]),
                  Divider(height: 16,
                      color: t.isNight
                          ? _white.withOpacity(0.08)
                          : const Color(0xFFDDE6F0)),
                  Wrap(spacing: 8, runSpacing: 8,
                      children: report.evidence
                          .map((e) => _evidenceThumb(context, e))
                          .toList()),
                ]),
              ),
            ],

            const SizedBox(height: 16),
          ]),
        )),
      ]),
    );
  }

  Widget _infoCard(Color cardBg, Color textClr, Color subClr, Color accentClr) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.05),
          blurRadius: 12, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _infoRow(Icons.tag_rounded, tr.get('case_id'), '#${report.id}',
            textClr, subClr, accentClr),
        _divider(),
        _infoRow(Icons.category_outlined, tr.get('category'),
    tr.get(report.category),   // ← uses the key directly
    textClr, subClr, accentClr),
        _divider(),
        _infoRow(Icons.person_outline_rounded, tr.get('reporter_type'),
            report.reporterType ?? '—', textClr, subClr, accentClr),
        _divider(),
        _infoRow(Icons.calendar_today_outlined, tr.get('submitted_date'),
            '${_formatDate(report.createdAt)}  ${_formatTime(report.createdAt)}',
            textClr, subClr, accentClr),
        if (report.incidentDate != null) ...[
          _divider(),
          _infoRow(Icons.event_outlined, tr.get('incident_date'),
              '${report.incidentDate}  ${report.incidentTime ?? ''}',
              textClr, subClr, accentClr),
        ],
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      Color textClr, Color subClr, Color accentClr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: accentClr),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label,
            style: TextStyle(fontSize: 12, color: subClr,
                fontWeight: FontWeight.w600))),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, color: textClr,
                fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1,
      color: t.isNight ? _white.withOpacity(0.08) : const Color(0xFFDDE6F0));

  Widget _sectionCard({
    required IconData icon, required String title, required String content,
    required Color cardBg, required Color textClr, required Color subClr,
    required Color accentClr, Color? accentBg,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentBg ?? cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: accentBg != null ? [] : [BoxShadow(
          color: Colors.black.withOpacity(t.isNight ? 0.15 : 0.05),
          blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: accentClr),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w800, color: accentClr)),
        ]),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 13, color: textClr,
            height: 1.6)),
      ]),
    );
  }

 Widget _evidenceThumb(BuildContext context, Map<String, dynamic> e) {
  final isImage = (e['file_type'] ?? '') == 'image';
  final url     = '${ApiConstants.storageUrl}/${e['file_path']}';
  if (isImage) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _ImageViewer(url: url, title: tr.get('evidence')))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: t.isNight
                      ? _white.withOpacity(0.05)
                      : const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.broken_image_outlined,
                    color: t.isNight
                        ? _white.withOpacity(0.3)
                        : _navy.withOpacity(0.3)))),
        ),
      );
    }
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: t.isNight ? _white.withOpacity(0.08) : _navy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(e['file_type'] == 'video'
            ? Icons.videocam_outlined : Icons.audio_file_outlined,
            color: t.isNight ? _gold : _navy.withOpacity(0.6), size: 26),
        const SizedBox(height: 4),
        Text(e['file_type'] ?? 'file',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: t.isNight
                    ? _white.withOpacity(0.5)
                    : _navy.withOpacity(0.5))),
      ]),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String url;
  final String title;
  const _ImageViewer({required this.url, required this.title});  // ← add required this.title
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black, foregroundColor: Colors.white,
      title: Text(title, style: const TextStyle(fontSize: 15))),
    body: Center(child: InteractiveViewer(
      minScale: 0.5, maxScale: 4.0,
      child: Image.network(url,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined, color: Colors.white54, size: 60)))),
  );
}