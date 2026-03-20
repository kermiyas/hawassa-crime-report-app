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

class ReportSightingScreen extends StatefulWidget {
  final AlertPost post;
  const ReportSightingScreen({super.key, required this.post});
  @override
  State<ReportSightingScreen> createState() => _ReportSightingScreenState();
}

class _ReportSightingScreenState extends State<ReportSightingScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _contactCtrl  = TextEditingController();
  final List<File> _evidenceFiles = [];
  bool _submitting = false;

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() { for (final x in picked) _evidenceFiles.add(File(x.path)); });
    }
  }

  Future<void> _submit() async {
    final tr = context.read<LanguageProvider>().tr;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _showError(tr.isAmharic ? 'ክፍለ ጊዜ አልቋል። እንደገና ይግቡ።' : 'Session expired. Please log in again.');
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
      if (_locationCtrl.text.isNotEmpty) request.fields['location']       = _locationCtrl.text.trim();
      if (_dateCtrl.text.isNotEmpty)     request.fields['sighting_date']  = _dateCtrl.text.trim();
      if (_contactCtrl.text.isNotEmpty)  request.fields['contact_number'] = _contactCtrl.text.trim();

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
      _showError(tr.isAmharic ? 'የኔትወርክ ስህተት። እንደገና ይሞክሩ።' : 'Network error. Please try again.');
    }

    if (mounted) setState(() => _submitting = false);
  }

  void _showSuccess() {
    final tr = context.read<LanguageProvider>().tr;
    final t  = context.read<ThemeProvider>().theme;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Color(0xFF065F46), size: 36),
          ),
          const SizedBox(height: 16),
          Text(tr.get('thank_you'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor)),
          const SizedBox(height: 8),
          Text(
            tr.get('sighting_success_msg'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.secondaryText, height: 1.5),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(tr.get('done'), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose(); _locationCtrl.dispose();
    _dateCtrl.dispose(); _contactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr          = context.watch<LanguageProvider>().tr;
    final t           = context.watch<ThemeProvider>().theme;
    final isAm        = tr.isAmharic;
    final accentColor = t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text(
          widget.post.category == 'Missing Item'
              ? tr.get('report_item_location')
              : tr.get('report_sighting'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.appBarTextColor),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.isNight ? const Color(0xFF1E4268) : const Color(0xFF486D99),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr.get('reporting_for'),
                        style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    Text(
                      widget.post.subjectName ?? widget.post.itemDescription ?? widget.post.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              _buildLabel(tr.get('what_did_you_see'), accentColor),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: TextStyle(color: t.primaryText),
                decoration: _inputDeco(hint: tr.get('describe_hint'), t: t, accentColor: accentColor),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr.get('please_describe') : null,
              ),
              const SizedBox(height: 16),

              _buildLabel(tr.get('where_did_you_see'), accentColor),
              TextFormField(
                controller: _locationCtrl,
                style: TextStyle(color: t.primaryText),
                decoration: _inputDeco(
                    hint: isAm ? 'ቦታ ያስገቡ' : 'Enter location', t: t, accentColor: accentColor),
              ),
              const SizedBox(height: 16),

              _buildLabel(tr.get('when_did_you_see'), accentColor),
              TextFormField(
                controller: _dateCtrl,
                style: TextStyle(color: t.primaryText),
                decoration: _inputDeco(hint: tr.get('when_hint'), t: t, accentColor: accentColor),
              ),
              const SizedBox(height: 16),

              _buildLabel(tr.get('your_contact_optional'), accentColor),
              TextFormField(
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: t.primaryText),
                decoration: _inputDeco(hint: tr.get('follow_up_hint'), t: t, accentColor: accentColor),
              ),
              const SizedBox(height: 20),

              _buildLabel(tr.get('evidence_photos_optional'), accentColor),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: t.isNight ? const Color(0xFF2A5080) : const Color(0xFFCBD5E1),
                        width: 1.5),
                  ),
                  child: _evidenceFiles.isEmpty
                      ? Column(children: [
                          Icon(Icons.camera_alt_outlined, size: 36,
                              color: accentColor.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(tr.get('tap_to_add_photos'),
                              style: TextStyle(fontSize: 13, color: accentColor,
                                  fontWeight: FontWeight.w700)),
                          Text(tr.get('evidence_help_police'),
                              style: TextStyle(fontSize: 12, color: t.secondaryText)),
                        ])
                      : Wrap(spacing: 8, runSpacing: 8, children: [
                          ..._evidenceFiles.asMap().entries.map((e) => Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(e.value, width: 80, height: 80,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2, right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _evidenceFiles.removeAt(e.key)),
                                child: Container(
                                  width: 20, height: 20,
                                  decoration: const BoxDecoration(
                                      color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ])),
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: t.isNight ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: t.isNight ? const Color(0xFF2A5080) : Colors.grey.shade300),
                              ),
                              child: Icon(Icons.add, color: t.iconColor),
                            ),
                          ),
                        ]),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.isNight ? const Color(0xFF1A3A5C).withOpacity(0.4) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.lock_outline, size: 16, color: t.secondaryText),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    tr.get('strict_confidential'),
                    style: TextStyle(fontSize: 12, color: t.secondaryText, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white))
                      : const Icon(Icons.send, size: 20),
                  label: Text(
                    _submitting ? tr.get('submitting') : tr.get('submit_sighting'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: accentColor.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color accentColor) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor)),
  );

  InputDecoration _inputDeco({
    required String hint,
    required AppTheme t,
    required Color accentColor,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: t.secondaryText),
        filled: true,
        fillColor: t.cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: t.isNight ? const Color(0xFF2A5080) : const Color(0xFFE2E8F0),
                width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: t.isNight ? const Color(0xFF2A5080) : const Color(0xFFE2E8F0),
                width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accentColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}