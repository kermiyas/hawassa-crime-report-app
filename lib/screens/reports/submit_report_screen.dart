// lib/screens/reports/submit_report_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import 'map_picker_screen.dart';
import 'evidence_preview_screen.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});
  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _landmarkController    = TextEditingController();
  final _descriptionController = TextEditingController();
  String?    _selectedCategory;
  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;
  double?    _latitude;
  double?    _longitude;
  String     _areaName     = '';
  String     _selectedRole = 'Victim';
  bool       _confirmed    = false;
  bool       _isLoading    = false;

  List<Map<String, dynamic>> _evidenceFiles = [];

  final ImagePicker   _picker        = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool    _isRecording  = false;
  String? _recordingPath;

  List<String> _categories(AppLocalizations tr) => [
    tr.get('theft'), tr.get('assault'), tr.get('robbery'), tr.get('vandalism'),
    tr.get('missing_person_cat'), tr.get('suspicious_activity'), tr.get('other'),
  ];

  List<Map<String, String>> _roles(AppLocalizations tr) => [
    {'label': tr.get('victim'),    'value': 'Victim'},
    {'label': tr.get('witness'),   'value': 'Witness'},
    {'label': tr.get('anonymous'), 'value': 'Anonymous'},
  ];

  String _categoryToKey(String translated, AppLocalizations tr) {
    final map = {
      tr.get('theft'): 'theft', tr.get('assault'): 'assault',
      tr.get('robbery'): 'robbery', tr.get('vandalism'): 'vandalism',
      tr.get('missing_person_cat'): 'missing_person',
      tr.get('suspicious_activity'): 'suspicious_activity',
      tr.get('other'): 'other',
    };
    return map[translated] ?? translated.toLowerCase().replaceAll(' ', '_');
  }

  @override
  void dispose() {
    _landmarkController.dispose();
    _descriptionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final t = context.read<ThemeProvider>().theme;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            brightness: t.isNight ? Brightness.dark : Brightness.light,
            colorScheme: t.isNight
                ? const ColorScheme.dark(
                    primary: Color(0xFFD5C38B),
                    onPrimary: Color(0xFF1A3A5C),
                    surface: Color(0xFF112D4E),
                    onSurface: Colors.white,
                    background: Color(0xFF112D4E),
                    onBackground: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF1A3A5C),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1A3A5C),
                  ),
            dialogBackgroundColor: t.isNight ? const Color(0xFF112D4E) : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final t = context.read<ThemeProvider>().theme;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            brightness: t.isNight ? Brightness.dark : Brightness.light,
            colorScheme: t.isNight
                ? const ColorScheme.dark(
                    primary: Color(0xFFD5C38B),
                    onPrimary: Color(0xFF1A3A5C),
                    surface: Color(0xFF112D4E),
                    onSurface: Colors.white,
                    background: Color(0xFF112D4E),
                    onBackground: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF1A3A5C),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1A3A5C),
                  ),
            dialogBackgroundColor: t.isNight ? const Color(0xFF112D4E) : Colors.white,
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: t.isNight ? Colors.white : const Color(0xFF1A3A5C)),
              labelMedium: TextStyle(color: t.isNight ? Colors.white : const Color(0xFF1A3A5C)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const MapPickerScreen()));
    if (result != null) {
      setState(() {
        _latitude  = result['latitude'];
        _longitude = result['longitude'];
        _areaName  = result['address'];
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) {
      final f = File(file.path);
      if (await f.length() > 10 * 1024 * 1024) { _showMessage('Image must be less than 10MB'); return; }
      setState(() => _evidenceFiles.add({'file': f, 'type': 'image', 'thumbnail': null}));
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      final f = File(file.path);
      if (await f.length() > 10 * 1024 * 1024) { _showMessage('Image must be less than 10MB'); return; }
      setState(() => _evidenceFiles.add({'file': f, 'type': 'image', 'thumbnail': null}));
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
    if (file != null) {
      final f = File(file.path);
      if (await f.length() > 50 * 1024 * 1024) { _showMessage('Video must be less than 50MB'); return; }
      File? thumb;
      try {
        final thumbPath = await VideoThumbnail.thumbnailFile(
          video: file.path, thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG, quality: 75,
        );
        if (thumbPath != null) thumb = File(thumbPath);
      } catch (e) { debugPrint('Thumbnail error: $e'); }
      setState(() => _evidenceFiles.add({'file': f, 'type': 'video', 'thumbnail': thumb}));
    }
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() { _isRecording = false; _recordingPath = null; });
      if (path != null) setState(() => _evidenceFiles.add({'file': File(path), 'type': 'audio', 'thumbnail': null}));
    } else {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) { _showMessage('Microphone permission denied'); return; }
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() { _isRecording = true; _recordingPath = path; });
    }
  }

  Future<void> _submitReport() async {
    final tr = context.read<LanguageProvider>().tr;
    if (_selectedCategory == null) { _showMessage(tr.get('category')); return; }
    if (_selectedDate == null)     { _showMessage(tr.get('date'));     return; }
    if (_selectedTime == null)     { _showMessage(tr.get('time'));     return; }
    if (_landmarkController.text.isEmpty) { _showMessage(tr.get('location_hint')); return; }
    if (_descriptionController.text.isEmpty) { _showMessage(tr.get('description_hint')); return; }
    if (!_confirmed) { _showMessage(tr.get('submit')); return; }

    setState(() => _isLoading = true);
    try {
      final token   = await ApiService.getToken();
      final uri     = Uri.parse('${ApiConstants.baseUrl}/reports');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept']        = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      final categoryKey = _categoryToKey(_selectedCategory!, tr);
      request.fields['title']            = _selectedCategory!;
      request.fields['category']         = categoryKey;
      request.fields['description']      = _descriptionController.text.trim();
      request.fields['location_address'] = _landmarkController.text.trim();
      request.fields['area_name']        = _areaName;
      request.fields['reporter_type']    = _selectedRole;
      request.fields['incident_date']    =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}';
      request.fields['incident_time']    =
          '${_selectedTime!.hour.toString().padLeft(2,'0')}:${_selectedTime!.minute.toString().padLeft(2,'0')}:00';
      if (_latitude != null) {
        request.fields['latitude']  = _latitude.toString();
        request.fields['longitude'] = _longitude.toString();
      }
      for (var item in _evidenceFiles) {
        request.files.add(await http.MultipartFile.fromPath('evidence[]', (item['file'] as File).path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final data     = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() => _isLoading = false);
        _showMessage(tr.get('success'));
        // ✅ Fixed navigator
       if (mounted && Navigator.canPop(context)) {
  Navigator.pop(context);
}
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? tr.get('error'));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('${tr.get('error')}: $e');
    }
  }

  Widget _buildEvidenceButton(IconData icon, VoidCallback onTap, AppTheme t, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.red : (t.isNight ? t.scaffoldBg : t.buttonColor),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: isActive ? Colors.white : (t.isNight ? t.iconColor : Colors.white),
            size: 26),
      ),
    );
  }

  Widget _buildEvidencePreview(int index, AppTheme t) {
    final item      = _evidenceFiles[index];
    final type      = item['type'] as String;
    final thumbnail = item['thumbnail'] as File?;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => EvidencePreviewScreen(evidenceFiles: _evidenceFiles, initialIndex: index))),
      child: Stack(children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 80, height: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: t.scaffoldBg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: type == 'image'
                ? Image.file(item['file'] as File, fit: BoxFit.cover)
                : type == 'video'
                    ? thumbnail != null
                        ? Stack(fit: StackFit.expand, children: [
                            Image.file(thumbnail, fit: BoxFit.cover),
                            const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32)),
                          ])
                        : Center(child: Icon(Icons.videocam, color: t.primaryText, size: 36))
                    : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.audiotrack, color: t.primaryText, size: 28),
                        const SizedBox(height: 4),
                        Text('Audio', style: TextStyle(fontSize: 10, color: t.primaryText)),
                      ])),
          ),
        ),
        Positioned(
          top: 0, right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _evidenceFiles.removeAt(index)),
            child: Container(
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr    = context.watch<LanguageProvider>().tr;
    final t     = context.watch<ThemeProvider>().theme;
    final cats  = _categories(tr);
    final roles = _roles(tr);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Category ──────────────────────────────────────────────────────
          Text('${tr.get('category')} *',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(tr.get('category'), style: TextStyle(color: t.secondaryText)),
                value: _selectedCategory,
                icon: Icon(Icons.arrow_drop_down, color: t.primaryText),
                dropdownColor: t.cardColor,
                style: TextStyle(color: t.primaryText, fontSize: 14),
                items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Date & Time ───────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${tr.get('date')} *',
                style: TextStyle(fontWeight: FontWeight.w600,
                    color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: t.cardColor, borderRadius: BorderRadius.circular(10),
                    border: _selectedDate != null ? Border.all(color: t.buttonColor, width: 1.5) : null,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      _selectedDate == null
                          ? tr.get('date')
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                          color: _selectedDate == null
                              ? t.secondaryText
                              : (t.isNight ? const Color(0xFFD5C38B) : t.primaryText),
                          fontSize: 13),
                    ),
                    Icon(Icons.calendar_today, color: t.iconColor, size: 20),
                  ]),
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${tr.get('time')} *',
                style: TextStyle(fontWeight: FontWeight.w600,
                    color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: t.cardColor, borderRadius: BorderRadius.circular(10),
                    border: _selectedTime != null ? Border.all(color: t.buttonColor, width: 1.5) : null,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      _selectedTime == null ? tr.get('time') : _selectedTime!.format(context),
                      style: TextStyle(
                          color: _selectedTime == null
                              ? t.secondaryText
                              : (t.isNight ? const Color(0xFFD5C38B) : t.primaryText),
                          fontSize: 13),
                    ),
                    Icon(Icons.access_time, color: t.iconColor, size: 20),
                  ]),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 16),

          // ── Location map ──────────────────────────────────────────────────
          Text(tr.get('location'),
            style: TextStyle(fontWeight: FontWeight.w600,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openMapPicker,
            child: Container(
              height: 150,
              decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10)),
              child: _latitude != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_on, color: t.iconColor, size: 40),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(_areaName, textAlign: TextAlign.center,
                            style: TextStyle(color: t.primaryText, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      Text(tr.get('tap_to_change_location'),
                          style: TextStyle(color: t.secondaryText, fontSize: 12)),
                    ]))
                  : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.map, color: t.secondaryText, size: 50),
                      const SizedBox(height: 8),
                      Text(tr.get('tap_to_pick_location'),
                          style: TextStyle(color: t.secondaryText)),
                    ])),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: _openMapPicker,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.isNight ? const Color(0xFFD5C38B) : t.buttonColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.my_location, color: t.iconColor),
              label: Text(tr.get('get_current_location'),
                  style: TextStyle(color: t.primaryText, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),

          // ── Landmark ──────────────────────────────────────────────────────
          Text('${tr.get('location')} *',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _landmarkController,
              style: TextStyle(color: t.primaryText),
              decoration: InputDecoration(
                hintText: tr.get('landmark_hint'),
                hintStyle: TextStyle(color: t.secondaryText),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────────
          Text('${tr.get('description')} *',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: t.primaryText),
              decoration: InputDecoration(
                hintText: tr.get('description_hint'),
                hintStyle: TextStyle(color: t.secondaryText),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Evidence ──────────────────────────────────────────────────────
          Text(tr.get('evidence'),
            style: TextStyle(fontWeight: FontWeight.w600,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildEvidenceButton(Icons.camera_alt, _pickFromCamera, t),
                _buildEvidenceButton(Icons.image, _pickFromGallery, t),
                _buildEvidenceButton(Icons.videocam, _pickVideo, t),
                _buildEvidenceButton(
                  _isRecording ? Icons.stop : Icons.mic, _toggleAudioRecording, t,
                  isActive: _isRecording,
                ),
              ]),
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                    SizedBox(width: 6),
                    Text('Recording... tap to stop',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ]),
                ),
              const SizedBox(height: 12),
              _evidenceFiles.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: Center(child: Text(tr.get('no_data'),
                          style: TextStyle(color: t.secondaryText))))
                  : SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _evidenceFiles.length,
                        itemBuilder: (_, i) => _buildEvidencePreview(i, t),
                      ),
                    ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 14, color: t.iconColor),
            const SizedBox(width: 6),
            Expanded(child: Text('Note: Max 10MB for images, 50MB for videos.',
                style: TextStyle(fontSize: 11, color: t.secondaryText))),
          ]),
          const SizedBox(height: 16),

          // ── Reporter role ─────────────────────────────────────────────────
          Text(tr.get('reporter_type'),
            style: TextStyle(fontWeight: FontWeight.w600,
                color: t.isNight ? const Color(0xFFD5C38B) : t.primaryText)),
          const SizedBox(height: 8),
          Row(
            children: roles.map((role) {
              return Expanded(child: Row(children: [
                Radio<String>(
                  value: role['value']!,
                  groupValue: _selectedRole,
                  activeColor: t.iconColor,
                  fillColor: MaterialStateProperty.resolveWith((states) =>
                      states.contains(MaterialState.selected)
                          ? t.iconColor
                          : (t.isNight
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF1A3A5C))),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                Flexible(child: Text(role['label']!,
                    style: TextStyle(color: t.primaryText, fontSize: 13))),
              ]));
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Confirmation checkbox ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: _confirmed,
                activeColor: t.iconColor,
                checkColor: const Color(0xFF1A3A5C),
                side: BorderSide(
                    color: t.isNight
                        ? Colors.white.withOpacity(0.5)
                        : const Color(0xFF1A3A5C),
                    width: 2),
                onChanged: (v) => setState(() => _confirmed = v!),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(tr.get('confirm_accuracy'),
                      style: TextStyle(color: t.primaryText, fontSize: 13)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Submit button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.isNight ? const Color(0xFFD5C38B) : t.buttonColor,
                foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(tr.get('submit_report'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}