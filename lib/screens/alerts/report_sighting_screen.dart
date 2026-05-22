// lib/screens/alerts/report_sighting_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/alert_post.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/auth_gate.dart';

class ReportSightingScreen extends StatefulWidget {
  final AlertPost post;
  const ReportSightingScreen({super.key, required this.post});
  @override
  State<ReportSightingScreen> createState() => _ReportSightingScreenState();
}

class _ReportSightingScreenState extends State<ReportSightingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _contactCtrl  = TextEditingController();
  final List<File> _evidenceFiles = [];
  bool _submitting = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Track which field is focused for step-indicator styling
  int _activeStep = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        for (final x in picked) _evidenceFiles.add(File(x.path));
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (ctx, child) {
        final t = context.read<ThemeProvider>().theme;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
              onPrimary: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
              surface: t.cardColor,
              onSurface: t.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final tr = context.read<LanguageProvider>().tr;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _showError(tr.isAmharic
            ? 'ክፍለ ጊዜ አልቋል። እንደገና ይግቡ።'
            : 'Session expired. Please log in again.');
        setState(() => _submitting = false);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/alerts/${widget.post.id}/sighting'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept']        = 'application/json';
      request.fields['description']    = _descCtrl.text.trim();
      if (_locationCtrl.text.isNotEmpty)
        request.fields['location']       = _locationCtrl.text.trim();
      if (_dateCtrl.text.isNotEmpty)
        request.fields['sighting_date']  = _dateCtrl.text.trim();
      if (_contactCtrl.text.isNotEmpty)
        request.fields['contact_number'] = _contactCtrl.text.trim();

      for (final f in _evidenceFiles) {
        request.files.add(await http.MultipartFile.fromPath('evidence[]', f.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res      = await http.Response.fromStream(streamed);

      if (res.statusCode == 201) {
        if (mounted) _showSuccess();
      } else {
        final body = jsonDecode(res.body);
        _showError(body['message'] ?? 'Failed to submit (${res.statusCode})');
      }
    } catch (e) {
      _showError(tr.isAmharic
          ? 'የኔትወርክ ስህተት። እንደገና ይሞክሩ።'
          : 'Network error. Please try again.');
    }

    if (mounted) setState(() => _submitting = false);
  }

  void _showSuccess() {
    final tr = context.read<LanguageProvider>().tr;
    final t  = context.read<ThemeProvider>().theme;
    final gold = const Color(0xFFD5C38B);
    final navy = const Color(0xFF1A3A5C);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Success badge
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [const Color(0xFF065F46), const Color(0xFF047857)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF065F46).withOpacity(0.4),
                  blurRadius: 16, spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            tr.get('thank_you'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: t.isNight ? gold : navy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr.get('sighting_success_msg'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: t.secondaryText,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          // Decorative divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (t.isNight ? gold : navy).withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Case reference hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (t.isNight ? gold : navy).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shield_outlined, size: 14,
                  color: t.isNight ? gold : navy),
              const SizedBox(width: 6),
              Text(
                tr.isAmharic
                    ? 'ሪፖርቱ ለፖሊስ ተቀብሏል'
                    : 'Report received by authorities',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: t.isNight ? gold : navy,
                ),
              ),
            ]),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: t.isNight ? gold : navy,
                foregroundColor: t.isNight ? navy : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                tr.get('done'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr    = context.watch<LanguageProvider>().tr;
    final t     = context.watch<ThemeProvider>().theme;
    final isAm  = tr.isAmharic;
    final gold  = const Color(0xFFD5C38B);
    final navy  = const Color(0xFF1A3A5C);
    final accent = t.isNight ? gold : navy;

    // Category-specific color for the header strip
    final Color catColor = widget.post.category == 'Wanted Person'
        ? const Color(0xFFDC2626)
        : widget.post.category == 'Missing Person'
            ? const Color(0xFFD97706)
            : const Color(0xFF486D99);

    final String catIcon = widget.post.category == 'Wanted Person'
        ? '🚨'
        : widget.post.category == 'Missing Person'
            ? '🔍'
            : '📦';

    final String screenTitle = widget.post.category == 'Missing Item'
        ? tr.get('report_item_location')
        : tr.get('report_sighting');

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      // ─── AppBar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: t.isNight ? const Color(0xFF0F2744) : const Color(0xFF1A3A5C),
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
            screenTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            isAm ? 'ሚስጥራዊ ሪፖርት' : 'Confidential Report',
            style: TextStyle(
              fontSize: 11,
              color: gold.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
        // Gold bottom border
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  gold.withOpacity(0.6),
                  gold,
                  gold.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Subject card ────────────────────────────────────────
                  _SubjectCard(
                    post: widget.post,
                    catColor: catColor,
                    catIcon: catIcon,
                    t: t,
                    gold: gold,
                    navy: navy,
                    tr: tr,
                  ),

                  const SizedBox(height: 24),

                  // ── Steps progress indicator ─────────────────────────────
                  _StepsRow(activeStep: _activeStep, accent: accent),

                  const SizedBox(height: 24),

                  // ── Section: What ─────────────────────────────────────────
                  _SectionHeader(
                    step: '1',
                    label: tr.get('what_did_you_see'),
                    accent: accent,
                    isActive: _activeStep == 0,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: TextStyle(color: t.primaryText, fontSize: 14),
                    onTap: () => setState(() => _activeStep = 0),
                    decoration: _inputDeco(
                      hint: tr.get('describe_hint'),
                      t: t,
                      accent: accent,
                      icon: Icons.visibility_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? tr.get('please_describe')
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Where ────────────────────────────────────────
                  _SectionHeader(
                    step: '2',
                    label: tr.get('where_did_you_see'),
                    accent: accent,
                    isActive: _activeStep == 1,
                    optional: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationCtrl,
                    style: TextStyle(color: t.primaryText, fontSize: 14),
                    onTap: () => setState(() => _activeStep = 1),
                    decoration: _inputDeco(
                      hint: isAm ? 'ቦታ ያስገቡ (ለምሳሌ፦ ቀቤና ገበያ)' : 'e.g. Kebena Market, near the mosque',
                      t: t,
                      accent: accent,
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: When ─────────────────────────────────────────
                  _SectionHeader(
                    step: '3',
                    label: tr.get('when_did_you_see'),
                    accent: accent,
                    isActive: _activeStep == 2,
                    optional: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    style: TextStyle(color: t.primaryText, fontSize: 14),
                    onTap: () {
                      setState(() => _activeStep = 2);
                      _selectDate();
                    },
                    decoration: _inputDeco(
                      hint: tr.get('when_hint'),
                      t: t,
                      accent: accent,
                      icon: Icons.calendar_today_outlined,
                      suffix: _dateCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => setState(() => _dateCtrl.clear()),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: t.secondaryText),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Contact ──────────────────────────────────────
                  _SectionHeader(
                    step: '4',
                    label: tr.get('your_contact_optional'),
                    accent: accent,
                    isActive: _activeStep == 3,
                    optional: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contactCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: t.primaryText, fontSize: 14),
                    onTap: () => setState(() => _activeStep = 3),
                    decoration: _inputDeco(
                      hint: tr.get('follow_up_hint'),
                      t: t,
                      accent: accent,
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Evidence Photos ──────────────────────────────
                  _SectionHeader(
                    step: '5',
                    label: tr.get('evidence_photos_optional'),
                    accent: accent,
                    isActive: _activeStep == 4,
                    optional: true,
                  ),
                  const SizedBox(height: 8),
                  _EvidenceUploader(
                    files: _evidenceFiles,
                    onTap: () {
                      setState(() => _activeStep = 4);
                      _pickImages();
                    },
                    onRemove: (i) => setState(() => _evidenceFiles.removeAt(i)),
                    t: t,
                    accent: accent,
                    tr: tr,
                  ),

                  const SizedBox(height: 16),

                  // ── Confidentiality notice ────────────────────────────────
                  _ConfidentialBadge(t: t, tr: tr, accent: accent),

                  const SizedBox(height: 28),

                  // ── Submit button ─────────────────────────────────────────
                  _SubmitButton(
  submitting: _submitting,
  onPressed: () {
    if (!AuthGate.require(context, featureName: 'report a sighting')) return;
    _submit();
  },
                    t: t,
                    gold: gold,
                    navy: navy,
                    tr: tr,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required AppTheme t,
    required Color accent,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: t.secondaryText.withOpacity(0.7)),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, size: 18, color: accent.withOpacity(0.6)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            )
          : null,
      filled: true,
      fillColor: t.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: t.isNight
              ? const Color(0xFF2A5080)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: t.isNight
              ? const Color(0xFF2A5080)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final AlertPost post;
  final Color catColor, gold, navy;
  final AppTheme t;
  final dynamic tr;
  final String catIcon;

  const _SubjectCard({
    required this.post,
    required this.catColor,
    required this.gold,
    required this.navy,
    required this.t,
    required this.tr,
    required this.catIcon,
  });

  @override
  Widget build(BuildContext context) {
    final subjectName =
        post.subjectName ?? post.itemDescription ?? post.title;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.isNight
              ? [const Color(0xFF1E3A5C), const Color(0xFF152C47)]
              : [const Color(0xFF1A3A5C), const Color(0xFF243B55)],
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(
                    color: catColor.withOpacity(0.3), width: 1),
              ),
            ),
            child: Row(children: [
              Text(catIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withOpacity(0.4)),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: catColor == const Color(0xFF486D99)
                        ? gold
                        : catColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.shield_outlined,
                  size: 14, color: gold.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                tr.isAmharic ? 'HPD-#${post.id}' : 'HPD-#${post.id}',
                style: TextStyle(
                  fontSize: 10,
                  color: gold.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ]),
          ),
          // Subject info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  post.category == 'Wanted Person'
                      ? Icons.person_search_rounded
                      : post.category == 'Missing Person'
                          ? Icons.search_rounded
                          : Icons.inventory_2_outlined,
                  color: gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    tr.isAmharic ? 'ሪፖርት ለ' : 'Reporting about',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subjectName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  final int activeStep;
  final Color accent;
  const _StepsRow({required this.activeStep, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final isActive = i == activeStep;
        final isDone   = i < activeStep;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isDone
                      ? accent
                      : isActive
                          ? accent.withOpacity(0.7)
                          : accent.withOpacity(0.15),
                ),
              ),
            ),
            if (i < 4) const SizedBox(width: 4),
          ]),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String step, label;
  final Color accent;
  final bool isActive;
  final bool optional;

  const _SectionHeader({
    required this.step,
    required this.label,
    required this.accent,
    this.isActive = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? accent : accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'optional',
              style: TextStyle(
                fontSize: 9,
                color: accent.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EvidenceUploader extends StatelessWidget {
  final List<File> files;
  final VoidCallback onTap;
  final void Function(int) onRemove;
  final AppTheme t;
  final Color accent;
  final dynamic tr;

  const _EvidenceUploader({
    required this.files,
    required this.onTap,
    required this.onRemove,
    required this.t,
    required this.accent,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: files.isEmpty ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: files.isNotEmpty
                ? accent.withOpacity(0.4)
                : t.isNight
                    ? const Color(0xFF2A5080)
                    : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: files.isEmpty
            ? Column(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      size: 24, color: accent.withOpacity(0.7)),
                ),
                const SizedBox(height: 10),
                Text(
                  tr.get('tap_to_add_photos'),
                  style: TextStyle(
                    fontSize: 13,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr.get('evidence_help_police'),
                  style: TextStyle(
                    fontSize: 12,
                    color: t.secondaryText,
                  ),
                ),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.photo_library_outlined,
                      size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    '${files.length} ${tr.isAmharic ? 'ፎቶዎች ተጨምረዋል' : 'photo(s) added'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ...files.asMap().entries.map(
                    (e) => Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          e.value,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10)),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(e.key),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4)
                              ],
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  // Add more button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accent.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.add_rounded,
                            color: accent, size: 22),
                        Text(
                          tr.isAmharic ? 'ጨምር' : 'Add',
                          style: TextStyle(
                            fontSize: 10,
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ]),
      ),
    );
  }
}

class _ConfidentialBadge extends StatelessWidget {
  final AppTheme t;
  final dynamic tr;
  final Color accent;

  const _ConfidentialBadge(
      {required this.t, required this.tr, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15), width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.lock_outline_rounded,
              size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tr.get('strict_confidential'),
            style: TextStyle(
              fontSize: 12,
              color: t.secondaryText,
              height: 1.5,
            ),
          ),
        ),
      ]),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool submitting;
  final VoidCallback onPressed;
  final AppTheme t;
  final Color gold, navy;
  final dynamic tr;

  const _SubmitButton({
    required this.submitting,
    required this.onPressed,
    required this.t,
    required this.gold,
    required this.navy,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: submitting ? 0 : 4,
          shadowColor: navy.withOpacity(0.4),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return (t.isNight ? gold : navy).withOpacity(0.4);
            }
            return Colors.transparent;
          }),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: submitting
                ? null
                : LinearGradient(
                    colors: t.isNight
                        ? [const Color(0xFFD5C38B), const Color(0xFFC4AE6A)]
                        : [const Color(0xFF1A3A5C), const Color(0xFF243B55)],
                  ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            alignment: Alignment.center,
            child: submitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: t.isNight ? navy : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          size: 15,
                          color: t.isNight ? navy : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr.get('submit_sighting'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: t.isNight ? navy : Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: (t.isNight ? navy : Colors.white).withOpacity(0.6),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}