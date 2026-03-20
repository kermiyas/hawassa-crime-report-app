// lib/screens/alerts/missing_item_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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

class MissingItemScreen extends StatefulWidget {
  const MissingItemScreen({super.key});
  @override
  State<MissingItemScreen> createState() => _MissingItemScreenState();
}

class _MissingItemScreenState extends State<MissingItemScreen> {
  List<AlertPost> _posts = [];
  bool _loading = true;
  bool _isOffline = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _error = null;

    final cached = await CacheService.load('alerts_missing_item');
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
        Uri.parse('${ApiConstants.baseUrl}/alerts?category=Missing+Item'),
      );
      if (res.statusCode == 200) {
        await CacheService.save('alerts_missing_item', res.body);
        final data = jsonDecode(res.body)['data'] as List;
        if (mounted) setState(() {
          _posts     = data.map((j) => AlertPost.fromJson(j)).toList();
          _loading   = false;
          _isOffline = false;
          _error     = null;
        });
      } else {
        if (mounted && _posts.isEmpty) setState(() { _error = 'failed_to_load'; _loading = false; });
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
    final langCode = Provider.of<LanguageProvider>(context, listen: false).tr.languageCode;
    final t        = Provider.of<ThemeProvider>(context, listen: false).theme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportMissingItemSheet(
        languageCode: langCode,
        theme: t,
        onSubmitted: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;
    final t  = context.watch<ThemeProvider>().theme;
    final accent = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Row(children: [
          Icon(Icons.inventory_2_outlined, size: 20, color: t.appBarTextColor),
          const SizedBox(width: 8),
          Text(tr.get('missing_items'),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: t.appBarTextColor)),
        ]),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReportForm,
        backgroundColor: accent,
        foregroundColor: t.isNight ? const Color(0xFF0F2440) : Colors.white,
        icon: const Icon(Icons.add_box_outlined),
        label: Text(tr.get('report_missing_item'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, size: 48, color: t.iconColor),
                  const SizedBox(height: 12),
                  Text(tr.get(_error!), style: TextStyle(color: t.secondaryText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                    ),
                    child: Text(tr.get('retry')),
                  ),
                ]))
              : Column(children: [
                  if (_isOffline) _offlineBanner(tr, accent),
                  Expanded(
                    child: _posts.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: t.secondaryText),
                            const SizedBox(height: 12),
                            Text(tr.get('no_missing_items'),
                                style: TextStyle(color: t.secondaryText, fontSize: 15)),
                            const SizedBox(height: 80),
                          ]))
                        : RefreshIndicator(
                            color: accent,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: _posts.length,
                              itemBuilder: (_, i) => _MissingItemCard(
                                post: _posts[i], tr: tr, t: t,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => AlertDetailScreen(post: _posts[i]))),
                              ),
                            ),
                          ),
                  ),
                ]),
    );
  }

  Widget _offlineBanner(AppLocalizations tr, Color accent) => Container(
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
}

class _MissingItemCard extends StatelessWidget {
  final AlertPost post;
  final VoidCallback onTap;
  final dynamic tr;
  final AppTheme t;
  const _MissingItemCard({required this.post, required this.onTap,
      required this.tr, required this.t});

  @override
  Widget build(BuildContext context) {
    final hasPhoto    = post.mediaFiles.isNotEmpty;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
    final badgeBg     = t.isNight
        ? const Color(0xFFD5C38B).withOpacity(0.15)
        : const Color(0xFFD6E4F0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.07),
              blurRadius: 8, offset: const Offset(0, 2))],
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasPhoto
                  ? Image.network(post.mediaFiles.first.url, width: 80, height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(t))
                  : _placeholder(t),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inventory_2_outlined, size: 12, color: accentColor),
                  const SizedBox(width: 4),
                  Text(tr.get('missing_item_badge'),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                          color: accentColor, letterSpacing: 1)),
                ]),
              ),
              const SizedBox(height: 6),
              Text(post.itemDescription ?? post.title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accentColor)),
              if (post.locationLost != null)
                Text('${tr.get('location_lost')}: ${post.locationLost}',
                    style: TextStyle(fontSize: 12, color: t.primaryText)),
              if (post.lastSeenDate != null)
                Text('${tr.get('last_seen_date')}: ${post.lastSeenDate}',
                    style: TextStyle(fontSize: 12, color: t.primaryText)),
              if (post.rewardInfo != null) ...[
                const SizedBox(height: 4),
                Text('${tr.get('reward')}: ${post.rewardInfo}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFD97706),
                        fontWeight: FontWeight.w700)),
              ],
              if (post.caseStatus != null && post.caseStatus != 'active') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(4)),
                  child: Text(tr.get('found_resolved'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46))),
                ),
              ],
            ])),
            Icon(Icons.chevron_right, color: t.iconColor),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder(AppTheme t) => Container(
    width: 80, height: 90,
    decoration: BoxDecoration(
      color: t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Icon(Icons.inventory_2_outlined, size: 36,
        color: t.isNight ? const Color(0xFFD5C38B).withOpacity(0.4) : const Color(0xFF94A3B8)),
  );
}

class _ReportMissingItemSheet extends StatefulWidget {
  final String languageCode;
  final AppTheme theme;
  final VoidCallback onSubmitted;
  const _ReportMissingItemSheet({
    required this.languageCode,
    required this.theme,
    required this.onSubmitted,
  });
  @override
  State<_ReportMissingItemSheet> createState() => _ReportMissingItemSheetState();
}

class _ReportMissingItemSheetState extends State<_ReportMissingItemSheet> {
  final _formKey = GlobalKey<FormState>();

  final _itemNameCtrl   = TextEditingController();
  final _itemColorCtrl  = TextEditingController();
  String? _itemCategory;

  DateTime? _dateLost;
  TimeOfDay? _timeLost;
  final _locationCtrl   = TextEditingController();
  String? _howLost;

  final _descriptionCtrl = TextEditingController();

  final _reporterNameCtrl  = TextEditingController();
  final _reporterPhoneCtrl = TextEditingController();
  final _reporterAddrCtrl  = TextEditingController();

  File? _photo;
  final _picker = ImagePicker();

  bool _submitting = false;

  AppTheme get t => widget.theme;
  Color get accent => t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);
  Color get accentFg => t.isNight ? const Color(0xFF0F2440) : Colors.white;

  // Night: navy input fields, golden 75% labels
  Color get _inputBg    => t.isNight ? const Color(0xFF1A3A5C) : t.inputBg;
  Color get _labelColor => t.isNight ? const Color(0xFFD5C38B).withOpacity(0.75) : t.primaryText;

  @override
  void dispose() {
    _itemNameCtrl.dispose(); _itemColorCtrl.dispose(); _locationCtrl.dispose();
    _descriptionCtrl.dispose(); _reporterNameCtrl.dispose();
    _reporterPhoneCtrl.dispose(); _reporterAddrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    if (d != null) setState(() => _dateLost = d);
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
    if (time != null) setState(() => _timeLost = time);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/missing-item-reports'),
      );
      final token = await ApiService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['item_name']      = _itemNameCtrl.text.trim();
      request.fields['item_category']  = _itemCategory ?? '';
      request.fields['item_color']     = _itemColorCtrl.text.trim();
      request.fields['date_lost']      = _dateLost != null ? _formatDate(_dateLost!) : '';
      request.fields['time_lost']      = _timeLost != null ? _formatTime(_timeLost!) : '';
      request.fields['location']       = _locationCtrl.text.trim();
      request.fields['how_lost']       = _howLost ?? '';
      request.fields['description']    = _descriptionCtrl.text.trim();
      request.fields['reporter_name']  = _reporterNameCtrl.text.trim();
      request.fields['reporter_phone'] = _reporterPhoneCtrl.text.trim();
      request.fields['reporter_address']= _reporterAddrCtrl.text.trim();

      if (_photo != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _photo!.path));
      }

      final streamed = await request.send();
      final res      = await http.Response.fromStream(streamed);

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: Color(0xFF059669),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Submission failed. Please try again.'),
          backgroundColor: Color(0xFFDC2626),
        ));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Network error. Please check your connection.'),
        backgroundColor: Color(0xFFDC2626),
      ));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final tr   = AppLocalizations(widget.languageCode);
    final isAm = widget.languageCode == 'am';

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: BoxDecoration(
        color: t.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // ── Header: golden (night) / #486D99 (day) ───────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Icon(Icons.add_box_outlined,
                color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr.get('report_missing_item'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white)),
              Text(tr.get('police_contact_if_found'),
                  style: TextStyle(fontSize: 11,
                      color: t.isNight
                          ? const Color(0xFF1A3A5C).withOpacity(0.7)
                          : Colors.white.withOpacity(0.7))),
            ])),
            IconButton(
              icon: Icon(Icons.close,
                  color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),

        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                _sectionHeader(isAm ? 'የዕቃ ዝርዝር' : 'ITEM DETAILS'),
                _field(tr.get('item_name'), _itemNameCtrl,
                    hint: isAm ? 'ለምሳሌ፡ ቦርሳ' : 'e.g. wallet', required: true),
                _dropdown(
                  label: tr.get('item_category'),
                  value: _itemCategory,
                  items: isAm
                      ? ['ሞባይል/ኤሌክትሮኒክስ', 'ቦርሳ/ቦርሳ', 'ጌጣጌጥ', 'ሰነዶች', 'ልብስ', 'ተሽከርካሪ', 'ሌላ']
                      : ['Phone/Electronics', 'Bag/Wallet', 'Jewelry', 'Documents', 'Clothing', 'Vehicle', 'Other'],
                  keys: ['electronics', 'bag_wallet', 'jewelry', 'documents', 'clothing', 'vehicle', 'other'],
                  onChanged: (v) => setState(() => _itemCategory = v),
                ),
                _field(tr.get('item_color'), _itemColorCtrl,
                    hint: isAm ? 'ለምሳሌ፡ ጥቁር' : 'e.g. Black'),
                _divider(),

                _sectionHeader(isAm ? 'የጥፋት ዝርዝር' : 'LOSS DETAILS'),
                Row(children: [
                  Expanded(child: _datePicker(
                    label: tr.get('date_lost'),
                    value: _dateLost != null ? _formatDate(_dateLost!) : null,
                    hint: isAm ? 'ቀን ይምረጡ' : 'Select Date',
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker(
                    label: tr.get('time_lost'),
                    value: _timeLost != null ? _formatTime(_timeLost!) : null,
                    hint: isAm ? 'ሰዓት ይምረጡ' : 'Select Time',
                    icon: Icons.access_time_outlined,
                    onTap: _pickTime,
                  )),
                ]),
                _field(tr.get('location'), _locationCtrl,
                    hint: isAm ? 'ለምሳሌ፡ ሀዋሳ ማዕከላዊ ገበያ' : 'e.g. Central Market, Hawassa'),

                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label(tr.get('how_lost')),
                    Row(children: [
                      _howLostOption('lost', tr.get('lost'), Icons.help_outline_rounded),
                      const SizedBox(width: 12),
                      _howLostOption('stolen', tr.get('stolen'), Icons.shield_outlined),
                    ]),
                  ]),
                ),
                _divider(),

                _sectionHeader(isAm ? 'መግለጫ' : 'DESCRIPTION'),
                _multilineField(tr.get('detailed_description'), _descriptionCtrl,
                    hint: isAm ? 'ዕቃውን በዝርዝር ይግለጹ...' : 'Describe the item in detail...'),
                _divider(),

                _sectionHeader(tr.get('upload_photo')),
                _photoPicker(tr),
                _divider(),

                _sectionHeader(isAm ? 'የዘጋቢ መረጃ' : 'REPORTER INFORMATION'),
                _field(tr.get('reporter_full_name'), _reporterNameCtrl,
                    hint: isAm ? 'ስምዎ' : 'Your Name', required: true),
                _field(tr.get('phone_number'), _reporterPhoneCtrl,
                    hint: '09...', keyboardType: TextInputType.phone, required: true),
                _field(tr.get('reporter_address'), _reporterAddrCtrl,
                    hint: isAm ? 'ቤት ቁጥር፣ ቀበሌ፣ ክፍለ ከተማ' : 'House No, Kebele, Sub-city'),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: accentFg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: accentFg))
                        : Text(tr.get('submit_report'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(
                  tr.get('police_contact_if_found'),
                  style: TextStyle(fontSize: 11, color: t.secondaryText),
                  textAlign: TextAlign.center,
                )),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w900,
        color: accent, letterSpacing: 0.5)),
  );

  // Golden 75% in night, primaryText in day
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(
        fontSize: 13, color: _labelColor, fontWeight: FontWeight.w600)),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Divider(color: t.dividerColor, height: 1),
  );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TextStyle(color: t.primaryText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.secondaryText, fontSize: 13),
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        ),
      ]),
    );
  }

  Widget _multilineField(String label, TextEditingController ctrl, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextFormField(
          controller: ctrl,
          maxLines: 3,
          style: TextStyle(color: t.primaryText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.secondaryText, fontSize: 13),
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ]),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required List<String> keys,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: t.cardColor,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: t.secondaryText),
              hint: Text(label, style: TextStyle(color: t.secondaryText, fontSize: 13)),
              items: List.generate(items.length, (i) => DropdownMenuItem(
                value: keys[i],
                child: Text(items[i], style: TextStyle(color: t.primaryText, fontSize: 14)),
              )),
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _datePicker({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.dividerColor),
            ),
            child: Row(children: [
              Expanded(child: Text(value ?? hint,
                  style: TextStyle(
                    color: value != null ? t.primaryText : t.secondaryText,
                    fontSize: 13,
                  ))),
              Icon(icon, size: 18, color: accent),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _howLostOption(String key, String label, IconData icon) {
    final selected = _howLost == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _howLost = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.12) : _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : t.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: selected ? accent : t.secondaryText),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? accent : t.secondaryText)),
          ]),
        ),
      ),
    );
  }

  Widget _photoPicker(AppLocalizations tr) {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: double.infinity,
        height: _photo != null ? 180 : 110,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
        ),
        child: _photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(fit: StackFit.expand, children: [
                  Image.file(_photo!, fit: BoxFit.cover),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _photo = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Color(0xFFDC2626), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, size: 32, color: accent),
                const SizedBox(height: 8),
                Text(tr.get('tap_to_upload_photo'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                Text(tr.get('photo_optional'),
                    style: TextStyle(fontSize: 11, color: t.secondaryText)),
              ]),
      ),
    );
  }
}