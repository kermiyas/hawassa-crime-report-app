// lib/screens/alerts/missing_person_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/alert_post.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import 'alert_detail_screen.dart';
import '../../widgets/auth_gate.dart';
import '../../providers/badge_provider.dart';

const _kNavy    = Color(0xFF0D1B2A);
const _kNavyMid = Color(0xFF1A3A5C);
const _kGold    = Color(0xFFC9A84C);
const _kGreen   = Color(0xFF2E7D32);
const _kAmber   = Color(0xFFE65100);

class MissingPersonScreen extends StatefulWidget {
  MissingPersonScreen({super.key});
  @override
  State<MissingPersonScreen> createState() => _MissingPersonScreenState();
}

class _MissingPersonScreenState extends State<MissingPersonScreen>
    with SingleTickerProviderStateMixin {
  List<AlertPost> _posts = [];
  bool _loading = true;
  bool _isOffline = false;
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
    setState(() { _error = null; });

    final cached = await CacheService.load('alerts_missing_person');
    if (cached != null) {
      try {
        final data = jsonDecode(cached)['data'] as List;
        if (mounted) setState(() {
          _posts   = data.map((j) => AlertPost.fromJson(j)).toList();
          _loading = false;
        });
      } catch (_) {}
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/alerts?category=Missing+Person'),
      );
      if (res.statusCode == 200) {
        await CacheService.save('alerts_missing_person', res.body);
        final data = jsonDecode(res.body)['data'] as List;
        if (mounted) {
          setState(() {
            _posts     = data.map((j) => AlertPost.fromJson(j)).toList();
            _loading   = false;
            _isOffline = false;
            _error     = null;
          });
          _animController.forward(from: 0);
        }
      } else {
        if (mounted && _posts.isEmpty)
          setState(() { _error = 'failed_to_load'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() {
        _loading   = false;
        _isOffline = _posts.isNotEmpty;
        if (_posts.isEmpty) _error = 'network_error';
      });
    }
  }

  void _openReportForm() {
   if (!AuthGate.require(context, featureName: 'report a missing person')) return;
HapticFeedback.lightImpact();
    final langCode = Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    final t        = Provider.of<ThemeProvider>(context, listen: false).theme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportMissingPersonSheet(
        languageCode: langCode,
        theme: t,
        onSubmitted: _load,
      ),
    );
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
            boxShadow: [BoxShadow(color: _kNavy.withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 4))],
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
                    child: const Icon(Icons.person_search_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.get('missing_persons'),
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

              // Info strip
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: _kGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'If you have seen any of these persons, please contact police.',
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

        // ── Body ─────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(
                  color: t.isNight ? _kGold : _kNavyMid, strokeWidth: 2.5))
              : _error != null
                  ? _buildError(tr, t, accent)
                  : Column(children: [
                      if (_isOffline) _offlineBanner(tr, accent),
                      Expanded(
                        child: _posts.isEmpty
                            ? _buildEmpty(tr, t, accent)
                            : RefreshIndicator(
                                color: t.isNight ? _kGold : _kNavyMid,
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                                      child: _MissingPersonCard(
                                        post: _posts[i], tr: tr, t: t,
                                        onTap: () async {
  HapticFeedback.selectionClick();
  await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AlertDetailScreen(post: _posts[i])));
  if (mounted) context.read<BadgeProvider>().markMissingPersonSeen();
},
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ]),
        ),
      ]),

      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReportForm,
        backgroundColor: t.isNight ? _kGold : _kNavyMid,
        foregroundColor: t.isNight ? _kNavy : Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: Text(tr.get('report_missing_person'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }

  Widget _offlineBanner(dynamic tr, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFBF360C)]),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(tr.get('offline_cached_data'),
          style: const TextStyle(color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.w600))),
      GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)),
          child: Text(tr.get('retry'),
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    ]),
  );

  Widget _buildError(dynamic tr, AppTheme t, Color accent) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08), shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Icon(Icons.wifi_off_rounded, size: 36, color: accent.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        Text(tr.get(_error!), style: TextStyle(fontSize: 15,
            color: t.primaryText, fontWeight: FontWeight.w700)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          color: accent.withOpacity(0.07), shape: BoxShape.circle,
          border: Border.all(color: accent.withOpacity(0.15), width: 1.5),
        ),
        child: Icon(Icons.person_search_rounded, size: 42,
            color: accent.withOpacity(0.45)),
      ),
      const SizedBox(height: 20),
      Text(tr.get('no_missing_persons'),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
              color: t.primaryText)),
      const SizedBox(height: 8),
      Text('No active records at this time',
          style: TextStyle(fontSize: 13, color: t.secondaryText)),
      const SizedBox(height: 80),
    ]),
  );
}

// ── Missing Person Card ───────────────────────────────────────────────────────
class _MissingPersonCard extends StatelessWidget {
  final AlertPost    post;
  final VoidCallback onTap;
  final dynamic      tr;
  final AppTheme     t;
  const _MissingPersonCard(
      {required this.post, required this.onTap, required this.tr, required this.t});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = post.mediaFiles.isNotEmpty;
    final isFound  = post.caseStatus != null && post.caseStatus != 'active';
    final accent   = t.isNight ? _kGold : _kNavyMid;

    String? daysMissing;
    if (post.lastSeenDate != null && !isFound) {
      try {
        final parts = post.lastSeenDate!.split('/');
        if (parts.length == 3) {
          final dt = DateTime(int.parse(parts[2]),
              int.parse(parts[1]), int.parse(parts[0]));
          final days = DateTime.now().difference(dt).inDays;
          if (days >= 0) daysMissing = '$days day${days == 1 ? '' : 's'} missing';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: [

            // Top accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFound
                      ? [_kGreen, const Color(0xFF43A047)]
                      : [accent, accent.withOpacity(0.4)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Photo
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
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
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
                          color: isFound
                              ? _kGreen.withOpacity(0.1)
                              : accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isFound
                                ? _kGreen.withOpacity(0.25)
                                : accent.withOpacity(0.25),
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            isFound
                                ? Icons.check_circle_outline_rounded
                                : Icons.person_off_rounded,
                            size: 10,
                            color: isFound ? _kGreen : accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFound ? 'FOUND' : tr.get('missing_badge'),
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w900,
                              color: isFound ? _kGreen : accent,
                              letterSpacing: 1,
                            ),
                          ),
                        ]),
                      ),
                      if (daysMissing != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kAmber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kAmber.withOpacity(0.2)),
                          ),
                          child: Text(daysMissing,
                              style: const TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _kAmber)),
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
                    const SizedBox(height: 7),

                    // Detail rows
                    if (post.age != null)
                      _row(Icons.cake_outlined,
                          '${tr.get('age')}: ${post.age} ${tr.get('years_old')}',
                          t, accent),
                    if (post.lastSeenLocation != null)
                      _row(Icons.location_on_outlined,
                          '${tr.get('last_seen')}: ${post.lastSeenLocation}',
                          t, accent),
                    if (post.lastSeenDate != null)
                      _row(Icons.calendar_today_outlined,
                          '${tr.get('last_seen_date')}: ${post.lastSeenDate}',
                          t, accent),
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
            Container(
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
                  'Tap to view details & submit sighting info',
                  style: TextStyle(fontSize: 11, color: t.secondaryText,
                      fontWeight: FontWeight.w500),
                )),
                Icon(Icons.arrow_forward_rounded, size: 12,
                    color: accent.withOpacity(0.4)),
              ]),
            ),
          ]),
        ),
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
              style: TextStyle(fontSize: 11.5, color: t.secondaryText, height: 1.4),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _placeholder() => Container(
    color: t.isNight ? const Color(0xFF1A2F46) : const Color(0xFFF4F6FA),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.person_rounded, size: 32,
          color: t.isNight ? _kGold.withOpacity(0.25) : _kNavyMid.withOpacity(0.2)),
      const SizedBox(height: 4),
      Text('No Photo', style: TextStyle(fontSize: 9, color: t.secondaryText,
          fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Report Missing Person Sheet ───────────────────────────────────────────────
class _ReportMissingPersonSheet extends StatefulWidget {
  final String languageCode;
  final AppTheme theme;
  final VoidCallback onSubmitted;
  const _ReportMissingPersonSheet({
    required this.languageCode,
    required this.theme,
    required this.onSubmitted,
  });
  @override
  State<_ReportMissingPersonSheet> createState() =>
      _ReportMissingPersonSheetState();
}

class _ReportMissingPersonSheetState
    extends State<_ReportMissingPersonSheet> {
  final _formKey             = GlobalKey<FormState>();
  final _fullNameCtrl        = TextEditingController();
  final _nicknameCtrl        = TextEditingController();
  final _ageCtrl             = TextEditingController();
  final _heightCtrl          = TextEditingController();
  final _locationCtrl        = TextEditingController();
  final _clothingCtrl        = TextEditingController();
  final _featuresCtrl        = TextEditingController();
  final _reporterNameCtrl    = TextEditingController();
  final _reporterPhoneCtrl   = TextEditingController();
  String? _gender, _bodyType, _skinColor, _relationship;
  DateTime? _lastSeenDate;
  TimeOfDay? _lastSeenTime;
  File? _photo;
  bool _submitting = false;
  final _picker = ImagePicker();

  AppTheme get t => widget.theme;
  Color get accent => t.isNight ? _kGold : _kNavyMid;
  Color get accentFg => t.isNight ? _kNavy : Colors.white;
  Color get _inputBg => t.isNight ? const Color(0xFF0D1B2A) : const Color(0xFFF4F6FA);

  @override
  void dispose() {
    _fullNameCtrl.dispose(); _nicknameCtrl.dispose(); _ageCtrl.dispose();
    _heightCtrl.dispose(); _locationCtrl.dispose(); _clothingCtrl.dispose();
    _featuresCtrl.dispose(); _reporterNameCtrl.dispose();
    _reporterPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xf = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (xf != null) setState(() => _photo = File(xf.path));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: accent)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _lastSeenDate = d);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: accent)),
        child: child!,
      ),
    );
    if (time != null) setState(() => _lastSeenTime = time);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/missing-person-reports'),
      );
      final token = await ApiService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['full_name']               = _fullNameCtrl.text.trim();
      request.fields['nickname']                = _nicknameCtrl.text.trim();
      request.fields['gender']                  = _gender ?? '';
      request.fields['age']                     = _ageCtrl.text.trim();
      request.fields['height']                  = _heightCtrl.text.trim();
      request.fields['body_type']               = _bodyType ?? '';
      request.fields['skin_color']              = _skinColor ?? '';
      request.fields['last_seen_date']          = _lastSeenDate != null ? _fmtDate(_lastSeenDate!) : '';
      request.fields['last_seen_time']          = _lastSeenTime != null ? _fmtTime(_lastSeenTime!) : '';
      request.fields['last_seen_location']      = _locationCtrl.text.trim();
      request.fields['clothing_worn']           = _clothingCtrl.text.trim();
      request.fields['distinguishing_features'] = _featuresCtrl.text.trim();
      request.fields['reporter_name']           = _reporterNameCtrl.text.trim();
      request.fields['reporter_phone']          = _reporterPhoneCtrl.text.trim();
      request.fields['relationship']            = _relationship ?? '';
      if (_photo != null)
        request.files.add(
            await http.MultipartFile.fromPath('photo', _photo!.path));
      final streamed = await request.send();
      final res      = await http.Response.fromStream(streamed);
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onSubmitted();
        _showSnack(AppLocalizations(widget.languageCode)
            .get('report_submitted_success'), true);
      } else {
        _showSnack(AppLocalizations(widget.languageCode)
            .get('submission_failed'), false);
      }
    } catch (_) {
      _showSnack(AppLocalizations(widget.languageCode)
          .get('submission_failed'), false);
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tr   = AppLocalizations(widget.languageCode);
    final isAm = widget.languageCode == 'am';

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: BoxDecoration(
        color: t.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [

        // Sheet header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: t.isNight
                  ? [const Color(0xFF2A4A6A), const Color(0xFF1A3A5C)]
                  : [_kNavy, _kNavyMid],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr.get('report_missing_person'),
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                Text(tr.get('police_review_immediately'),
                    style: TextStyle(fontSize: 11,
                        color: Colors.white.withOpacity(0.65))),
              ],
            )),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white60),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),

        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                _section(isAm ? 'የሰው መሠረታዊ መረጃ' : 'PERSON BASIC INFORMATION'),
                _field(tr.get('full_name'), _fullNameCtrl,
                    hint: isAm ? 'ሙሉ ስም ያስገቡ' : 'Enter full name',
                    required: true),
                _field(tr.get('nickname'), _nicknameCtrl,
                    hint: isAm ? 'አማራጭ' : 'Optional'),
                Row(children: [
                  _genderBtn('male',   tr.get('male'),   Icons.male),
                  const SizedBox(width: 12),
                  _genderBtn('female', tr.get('female'), Icons.female),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field(tr.get('age'), _ageCtrl,
                      hint: '18', keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('${tr.get('height')} (cm)',
                      _heightCtrl,
                      hint: '170', keyboardType: TextInputType.number)),
                ]),
                Row(children: [
                  Expanded(child: _dropdown(
                    label: tr.get('body_type'), value: _bodyType,
                    items: isAm
                        ? ['ቀጭን', 'መካከለኛ', 'ወፍራም', 'ጡንቻማ']
                        : ['Slim', 'Medium', 'Heavy', 'Muscular'],
                    keys: ['slim', 'medium', 'heavy', 'muscular'],
                    onChanged: (v) => setState(() => _bodyType = v),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdown(
                    label: tr.get('skin_color'), value: _skinColor,
                    items: isAm
                        ? ['ነጭ', 'ቀላል ቡናማ', 'ቡናማ', 'ጥቁር']
                        : ['Light', 'Brown', 'Dark Brown', 'Dark'],
                    keys: ['light', 'brown', 'dark_brown', 'dark'],
                    onChanged: (v) => setState(() => _skinColor = v),
                  )),
                ]),
                _divider(),

                _section(isAm ? 'መጨረሻ የታዩበት ዝርዝር' : 'LAST SEEN DETAILS'),
                Row(children: [
                  Expanded(child: _datePick(
                    label: tr.get('date'),
                    value: _lastSeenDate != null ? _fmtDate(_lastSeenDate!) : null,
                    hint: isAm ? 'ቀን ይምረጡ' : 'Select Date',
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _datePick(
                    label: tr.get('time'),
                    value: _lastSeenTime != null ? _fmtTime(_lastSeenTime!) : null,
                    hint: isAm ? 'ሰዓት ይምረጡ' : 'Select Time',
                    icon: Icons.access_time_outlined,
                    onTap: _pickTime,
                  )),
                ]),
                _field(tr.get('location'), _locationCtrl,
                    hint: isAm ? 'ቅርብ ቤተ ክርስቲያን' : 'e.g. Near St. Gabriel Church'),
                _divider(),

                _section(isAm ? 'ልብስና መልክ' : 'CLOTHING & APPEARANCE'),
                _multiline(tr.get('clothing_worn'), _clothingCtrl,
                    hint: isAm
                        ? 'ሸሚዝ፣ ሱሪ፣ ጫማ፣ ቀለሞች ይግለጹ'
                        : 'Describe shirt, pants, shoes, colors, etc.'),
                _multiline(tr.get('distinguishing_features'), _featuresCtrl,
                    hint: isAm
                        ? 'ጠባሳ፣ ንቅሳት፣ መነጽር...'
                        : 'Scars, tattoos, birthmarks, glasses...'),
                _divider(),

                _section(tr.get('upload_photo')),
                _photoPicker(tr),
                _divider(),

                _section(isAm ? 'የዘጋቢ መረጃ' : 'CONTACT INFORMATION'),
                _field(tr.get('reporter_full_name'), _reporterNameCtrl,
                    hint: isAm ? 'ስምዎ' : 'Your Name', required: true),
                _field(tr.get('phone_number'), _reporterPhoneCtrl,
                    hint: '09...', keyboardType: TextInputType.phone,
                    required: true),
                _dropdown(
                  label: tr.get('relationship_to_missing'), value: _relationship,
                  items: isAm
                      ? ['ቤተሰብ', 'ጓደኛ', 'ጎረቤት', 'ባልደረባ', 'ሌላ']
                      : ['Family', 'Friend', 'Neighbor', 'Colleague', 'Other'],
                  keys: ['family', 'friend', 'neighbor', 'colleague', 'other'],
                  onChanged: (v) => setState(() => _relationship = v),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(tr.get('submit_report'),
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.isNight ? _kGold : _kNavyMid,
                      foregroundColor: t.isNight ? _kNavy : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(tr.get('police_review_immediately'),
                    style: TextStyle(fontSize: 11, color: t.secondaryText),
                    textAlign: TextAlign.center)),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
          color: accent, letterSpacing: 0.5)),
    ]),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Divider(color: t.dividerColor, height: 1),
  );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: accent)),
            if (required)
              Text(' *', style: const TextStyle(color: Color(0xFFC62828),
                  fontWeight: FontWeight.w900, fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14, color: t.primaryText,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: t.secondaryText, fontSize: 13),
              filled: true, fillColor: _inputBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.dividerColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.dividerColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null
                : null,
          ),
        ]),
      );

  Widget _multiline(String label, TextEditingController ctrl, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: accent)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl, maxLines: 3,
            style: TextStyle(fontSize: 14, color: t.primaryText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: t.secondaryText, fontSize: 13),
              filled: true, fillColor: _inputBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.dividerColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.dividerColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ]),
      );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required List<String> keys,
    required ValueChanged<String?> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: accent)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value, isExpanded: true,
                dropdownColor: t.cardColor,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: t.secondaryText),
                hint: Text(label, style: TextStyle(
                    color: t.secondaryText, fontSize: 13)),
                items: List.generate(items.length, (i) =>
                    DropdownMenuItem(
                      value: keys[i],
                      child: Text(items[i], style: TextStyle(
                          color: t.primaryText, fontSize: 14)),
                    )),
                onChanged: onChanged,
              ),
            ),
          ),
        ]),
      );

  Widget _datePick({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: accent)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.dividerColor),
              ),
              child: Row(children: [
                Expanded(child: Text(value ?? hint,
                    style: TextStyle(
                        color: value != null ? t.primaryText : t.secondaryText,
                        fontSize: 13))),
                Icon(icon, size: 18, color: accent),
              ]),
            ),
          ),
        ]),
      );

  Widget _genderBtn(String key, String label, IconData icon) {
    final sel = _gender == key;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _gender = key); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? accent.withOpacity(0.1) : _inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? accent : t.dividerColor,
                width: sel ? 1.5 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: sel ? accent : t.secondaryText),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: sel ? accent : t.secondaryText)),
          ]),
        ),
      ),
    );
  }

  Widget _photoPicker(AppLocalizations tr) => GestureDetector(
    onTap: _pickPhoto,
    child: Container(
      width: double.infinity,
      height: _photo != null ? 180 : 110,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
      ),
      child: _photo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(fit: StackFit.expand, children: [
                Image.file(_photo!, fit: BoxFit.cover),
                Positioned(top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _photo = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFC62828), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
              ]),
            )
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_a_photo_outlined, size: 30, color: accent),
              const SizedBox(height: 8),
              Text(tr.get('tap_to_upload_photo'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: accent)),
              const SizedBox(height: 2),
              Text(tr.get('photo_optional'),
                  style: TextStyle(fontSize: 11, color: t.secondaryText)),
            ]),
    ),
  );
}