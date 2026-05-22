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
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class SubmitReportScreen extends StatefulWidget {
  final int?    preselectedStationId;
  final String  preselectedStationName;
  final String  preselectedStationAddress;

  const SubmitReportScreen({
    super.key,
    this.preselectedStationId,
    this.preselectedStationName    = '',
    this.preselectedStationAddress = '',
  });

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
  String     _areaName = '';

  // ── Police station ───────────────────────────────────────────────────────
  int?    _selectedStationId;
  String  _selectedStationName    = '';
  String  _selectedStationAddress = '';
  bool    _isFetchingStation      = false;

  String  _selectedRole = 'Victim';
  bool    _confirmed    = false;
  bool    _isLoading    = false;

  List<Map<String, dynamic>> _stations      = [];
  bool                       _stationsLoaded  = false;
  bool                       _stationsLoading = false;

  List<Map<String, dynamic>> _evidenceFiles = [];
  final ImagePicker   _picker        = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  // ── Colors ────────────────────────────────────────────────────────────────
  final Color _navy     = const Color(0xFF1A3A5C);
  final Color _navyDark = const Color(0xFF0D1B2A);
  final Color _gold     = const Color(0xFFC9A84C);
  final Color _inputBg  = const Color(0xFFF5F8FC);
  final Color _border   = const Color(0xFFDDE6F0);
  final Color _textGrey = const Color(0xFF7A90B0);

  final List<Map<String, String>> _categoryItems = [
    {'key': 'theft',             'value': 'theft'},
    {'key': 'robbery',           'value': 'robbery'},
    {'key': 'burglary',          'value': 'burglary'},
    {'key': 'assault',           'value': 'assault'},
    {'key': 'sexual_assault',    'value': 'sexual_assault'},
    {'key': 'domestic_violence', 'value': 'domestic_violence'},
    {'key': 'homicide',          'value': 'homicide'},
    {'key': 'kidnapping',        'value': 'kidnapping'},
    {'key': 'human_trafficking', 'value': 'human_trafficking'},
    {'key': 'vandalism',         'value': 'vandalism'},
    {'key': 'arson',             'value': 'arson'},
    {'key': 'fraud',             'value': 'fraud'},
    {'key': 'cybercrime',        'value': 'cybercrime'},
    {'key': 'drug_offense',      'value': 'drug_offense'},
    {'key': 'weapon_offense',    'value': 'weapon_offense'},
    {'key': 'vehicle_theft',     'value': 'vehicle_theft'},
    {'key': 'hit_and_run',       'value': 'hit_and_run'},
    {'key': 'trespassing',       'value': 'trespassing'},
    {'key': 'harassment',        'value': 'harassment'},
    {'key': 'other',             'value': 'other'},
  ];

  final List<Map<String, String>> _roleItems = [
    {'value': 'Victim',    'key': 'victim',    'icon': 'person'},
    {'value': 'Witness',   'key': 'witness',   'icon': 'visibility'},
    {'value': 'Anonymous', 'key': 'anonymous', 'icon': 'person_off'},
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    if (widget.preselectedStationName.isNotEmpty) {
      _selectedStationName    = widget.preselectedStationName;
      _selectedStationAddress = widget.preselectedStationAddress;
      if (widget.preselectedStationId != null) {
        _selectedStationId = widget.preselectedStationId;
      }
    }

    _loadStations();

    if (widget.preselectedStationName.isEmpty) {
      _autoDetectLocation();
    }
  }

  @override
  void dispose() {
    _landmarkController.dispose();
    _descriptionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ── Geocoding helper — returns clean "Neighbourhood, City" string ─────────
  //
  // Priority:  subLocality  →  locality  →  administrativeArea
  // Street is intentionally skipped: in Ethiopia it returns road codes.
  // We show at most two levels to avoid the multi-comma problem.
  String _buildPlaceName(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return '';
    final p = placemarks.first;

    final primary = (p.subLocality?.isNotEmpty == true)
        ? p.subLocality!
        : (p.locality?.isNotEmpty == true)
            ? p.locality!
            : (p.administrativeArea?.isNotEmpty == true)
                ? p.administrativeArea!
                : '';

    // Only add a second level when primary is the sub-locality
    final secondary = (primary == p.subLocality &&
            p.locality?.isNotEmpty == true)
        ? p.locality!
        : '';

    if (primary.isEmpty)   return '';
    if (secondary.isEmpty) return primary;
    return '$primary, $secondary';
  }

  // ── Load stations from API ────────────────────────────────────────────────

  Future<void> _loadStations() async {
    if (_stationsLoading || _stationsLoaded) return;
    setState(() => _stationsLoading = true);

    try {
      final token    = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/police-stations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> raw = jsonDecode(response.body);

        final loaded = raw.map<Map<String, dynamic>>((s) {
          final rawId = s['id'];
          final int? id = rawId == null
              ? null
              : rawId is int
                  ? rawId
                  : int.tryParse(rawId.toString());

          double parseDbl(dynamic v) {
            if (v == null) return 0.0;
            if (v is num)  return v.toDouble();
            return double.tryParse(v.toString()) ?? 0.0;
          }

          return {
            'id':        id,
            'name':      s['name']?.toString()    ?? '',
            'address':   s['address']?.toString() ?? '',
            'district':  s['district']?.toString() ?? '',
            'phone':     s['phone']?.toString(),
            'latitude':  parseDbl(s['latitude']),
            'longitude': parseDbl(s['longitude']),
            'type':      s['type']?.toString()    ?? 'local',
          };
        }).toList();

        setState(() {
          _stations        = loaded;
          _stationsLoaded  = true;
          _stationsLoading = false;
        });

        // Resolve preselected station id by name if needed
        if (widget.preselectedStationName.isNotEmpty &&
            _selectedStationId == null) {
          final match = _stations.firstWhere(
            (s) => s['name'] == widget.preselectedStationName,
            orElse: () => {},
          );
          if (match.isNotEmpty && match['id'] != null) {
            setState(() => _selectedStationId = match['id'] as int);
          }
        }

        // Auto-select nearest if no station pre-filled and location known
        if (widget.preselectedStationName.isEmpty &&
            _selectedStationId == null &&
            _latitude != null &&
            _longitude != null) {
          _autoSelectNearestStation(_latitude!, _longitude!);
        }
      } else {
        setState(() => _stationsLoading = false);
      }
    } catch (e) {
      setState(() => _stationsLoading = false);
    }
  }

  // ── Auto-detect location on screen open ───────────────────────────────────

  Future<void> _autoDetectLocation() async {
    setState(() => _isFetchingStation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 15));

      String placeName = '';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        placeName = _buildPlaceName(placemarks);
      } catch (e) {
        debugPrint('[Geocoding] failed: $e');
      }

      if (placeName.isEmpty) {
        placeName = '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }

      setState(() {
        _latitude  = position.latitude;
        _longitude = position.longitude;
        _areaName  = placeName;
      });

      if (_stationsLoaded) {
        _autoSelectNearestStation(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('[Location] auto-detect failed: $e');
    } finally {
      if (mounted) setState(() => _isFetchingStation = false);
    }
  }

  // ── Nearest station (Haversine) ───────────────────────────────────────────

  void _autoSelectNearestStation(double lat, double lng) {
    if (_stations.isEmpty) return;

    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    for (final s in _stations) {
      final sLat = s['latitude']  as double;
      final sLng = s['longitude'] as double;
      if (sLat == 0.0 && sLng == 0.0) continue;

      final d = _haversineKm(lat, lng, sLat, sLng);
      if (d < minDist) {
        minDist = d;
        nearest = s;
      }
    }

    if (nearest != null) {
      setState(() {
        _selectedStationId      = nearest!['id'] as int?;
        _selectedStationName    = nearest['name']    as String;
        _selectedStationAddress = nearest['address'] as String? ?? '';
      });
    }
  }

  // ── Station picker bottom sheet ───────────────────────────────────────────

  Future<void> _showStationPicker() async {
    final tr = context.read<LanguageProvider>().tr;

    if (!_stationsLoaded) {
      if (!_stationsLoading) _loadStations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.get('loading_stations')),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      for (int i = 0; i < 50 && !_stationsLoaded; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    if (_stations.isEmpty) {
      _showMessage(tr.get('stations_load_error'));
      return;
    }

    final t       = context.read<ThemeProvider>().theme;
    final sheetBg = t.isNight ? const Color(0xFF112D4E) : Colors.white;
    final textClr = t.isNight ? Colors.white : _navy;

    final stations = List<Map<String, dynamic>>.from(_stations);
    if (_latitude != null && _longitude != null) {
      stations.sort((a, b) {
        final da = _haversineKm(_latitude!, _longitude!,
            a['latitude'] as double, a['longitude'] as double);
        final db = _haversineKm(_latitude!, _longitude!,
            b['latitude'] as double, b['longitude'] as double);
        return da.compareTo(db);
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(children: [
                  Icon(Icons.local_police_rounded,
                      color: t.isNight ? _gold : _navy, size: 20),
                  const SizedBox(width: 10),
                  Text(tr.get('select_police_station'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textClr)),
                  if (_latitude != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: _navy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.near_me_rounded,
                            size: 11, color: t.isNight ? _gold : _navy),
                        const SizedBox(width: 4),
                        Text(tr.get('sorted_by_distance'),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: t.isNight ? _gold : _navy)),
                      ]),
                    ),
                  ],
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: stations.length,
                  itemBuilder: (_, i) {
                    final s        = stations[i];
                    final sid      = s['id'] as int?;
                    final selected = sid != null && sid == _selectedStationId;

                    String? distLabel;
                    if (_latitude != null) {
                      final km = _haversineKm(_latitude!, _longitude!,
                          s['latitude'] as double, s['longitude'] as double);
                      distLabel = km < 1
                          ? '${(km * 1000).round()} m away'
                          : '${km.toStringAsFixed(1)} km away';
                    }

                    final typeColour =
                        _typeColor(s['type'] as String? ?? '');

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                            color: selected
                                ? _navy
                                : _navy.withOpacity(
                                    t.isNight ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.account_balance_rounded,
                            size: 20,
                            color: selected
                                ? Colors.white
                                : (t.isNight ? _gold : _navy)),
                      ),
                      title: Text(s['name'] as String,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: textClr)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['address'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: textClr.withOpacity(0.5))),
                          const SizedBox(height: 2),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: typeColour.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(5)),
                              child: Text(
                                (s['type'] as String? ?? '')
                                    .toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: typeColour),
                              ),
                            ),
                            if (distLabel != null) ...[
                              const SizedBox(width: 6),
                              Text(distLabel,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: i == 0
                                          ? const Color(0xFF27AE60)
                                          : textClr.withOpacity(0.45))),
                            ],
                          ]),
                        ],
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle_rounded,
                              color: _navy, size: 22)
                          : (i == 0 && _latitude != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF27AE60)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                  child: Text(tr.get('nearest'),
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF27AE60))))
                              : null),
                      onTap: () {
                        setState(() {
                          _selectedStationId      = s['id'] as int?;
                          _selectedStationName    = s['name'] as String;
                          _selectedStationAddress =
                              s['address'] as String? ?? '';
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'headquarters': return const Color(0xFF1A3A5C);
      case 'subcity':      return const Color(0xFF1976D2);
      case 'regional':     return const Color(0xFF7B1FA2);
      case 'traffic':      return const Color(0xFFE65100);
      case 'special':      return const Color(0xFF27AE60);
      default:             return const Color(0xFF607D8B);
    }
  }

  double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r    = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a    = math.sin(dLat / 2) * math.sin(dLat / 2)
        + math.cos(lat1 * math.pi / 180)
        * math.cos(lat2 * math.pi / 180)
        * math.sin(dLon / 2)
        * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor:
            isError ? const Color(0xFFC0392B) : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickDate() async {
    final t    = context.read<ThemeProvider>().theme;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: t.isNight
              ? const ColorScheme.dark(
                  primary: Color(0xFFC9A84C),
                  onPrimary: Color(0xFF1A3A5C))
              : const ColorScheme.light(
                  primary: Color(0xFF1A3A5C),
                  onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final t    = context.read<ThemeProvider>().theme;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: t.isNight
              ? const ColorScheme.dark(
                  primary: Color(0xFFC9A84C),
                  onPrimary: Color(0xFF1A3A5C))
              : const ColorScheme.light(
                  primary: Color(0xFF1A3A5C),
                  onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  // ── Map picker — address comes directly from MapPickerScreen ─────────────
  // MapPickerScreen returns {'latitude', 'longitude', 'address'} where
  // 'address' is already reverse-geocoded by the map screen itself.
  // We trust that value directly — no re-geocoding needed here.
  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const MapPickerScreen()));
    if (result != null) {
      final lat     = result['latitude']  as double;
      final lng     = result['longitude'] as double;
      final address = result['address']   as String? ?? '';

      // If the map screen returned a raw coordinate string or empty,
      // do a single clean geocode pass with our helper.
      String placeName = address;
      if (placeName.isEmpty || placeName.contains(',') && placeName.split(',').length > 2) {
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          final clean      = _buildPlaceName(placemarks);
          if (clean.isNotEmpty) placeName = clean;
        } catch (_) {}
      }

      setState(() {
        _latitude  = lat;
        _longitude = lng;
        _areaName  = placeName;
        if (widget.preselectedStationId == null &&
            widget.preselectedStationName.isEmpty) {
          _selectedStationId      = null;
          _selectedStationName    = '';
          _selectedStationAddress = '';
        }
      });

      if (widget.preselectedStationName.isEmpty) {
        _autoSelectNearestStation(lat, lng);
      }
    }
  }

  // ── Evidence pickers ──────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (file != null) {
      final f = File(file.path);
      if (await f.length() > 10 * 1024 * 1024) {
        _showMessage('Image must be less than 10MB');
        return;
      }
      setState(() =>
          _evidenceFiles.add({'file': f, 'type': 'image', 'thumbnail': null}));
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      final f = File(file.path);
      if (await f.length() > 10 * 1024 * 1024) {
        _showMessage('Image must be less than 10MB');
        return;
      }
      setState(() =>
          _evidenceFiles.add({'file': f, 'type': 'image', 'thumbnail': null}));
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5));
    if (file != null) {
      final f = File(file.path);
      if (await f.length() > 50 * 1024 * 1024) {
        _showMessage('Video must be less than 50MB');
        return;
      }
      File? thumb;
      try {
        final thumbPath = await VideoThumbnail.thumbnailFile(
            video: file.path,
            thumbnailPath: (await getTemporaryDirectory()).path,
            imageFormat: ImageFormat.JPEG,
            quality: 75);
        if (thumbPath != null) thumb = File(thumbPath);
      } catch (e) {
        debugPrint('Thumbnail error: $e');
      }
      setState(() =>
          _evidenceFiles.add({'file': f, 'type': 'video', 'thumbnail': thumb}));
    }
  }

  Future<void> _toggleAudio() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() => _evidenceFiles
            .add({'file': File(path), 'type': 'audio', 'thumbnail': null}));
      }
    } else {
      final ok = await _audioRecorder.hasPermission();
      if (!ok) {
        _showMessage('Microphone permission denied');
        return;
      }
      final dir  = await getTemporaryDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() => _isRecording = true);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    final tr = context.read<LanguageProvider>().tr;

    if (_selectedCategory == null) {
      _showMessage(tr.get('select_crime_type'));
      return;
    }
    if (_selectedDate == null) {
      _showMessage('Please select the incident date');
      return;
    }
    if (_selectedTime == null) {
      _showMessage('Please select the incident time');
      return;
    }
    if (_landmarkController.text.isEmpty) {
      _showMessage('Please enter a landmark or location description');
      return;
    }
    if (_descriptionController.text.trim().length < 20) {
      _showMessage('Description must be at least 20 characters');
      return;
    }
    if (_selectedStationId == null) {
      _showMessage(tr.get('please_select_station'));
      return;
    }
    if (!_confirmed) {
      _showMessage('Please confirm that the information is accurate!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token   = await ApiService.getToken();
      final uri     = Uri.parse('${ApiConstants.baseUrl}/reports');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept']        = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      final catItem = _categoryItems.firstWhere(
        (c) => c['value'] == _selectedCategory,
        orElse: () => {'key': 'other', 'value': 'other'},
      );

      request.fields['title']             = catItem['value']!;
      request.fields['category']          = catItem['value']!;
      request.fields['description']       = _descriptionController.text.trim();
      request.fields['location_address']  = _landmarkController.text.trim();
      request.fields['area_name']         = _areaName;
      request.fields['reporter_type']     = _selectedRole;
      request.fields['police_station_id'] = _selectedStationId.toString();
      request.fields['incident_date'] =
          '${_selectedDate!.year}-'
          '${_selectedDate!.month.toString().padLeft(2, '0')}-'
          '${_selectedDate!.day.toString().padLeft(2, '0')}';
      request.fields['incident_time'] =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
          '${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      if (_latitude != null) {
        request.fields['latitude']  = _latitude.toString();
        request.fields['longitude'] = _longitude.toString();
      }
      for (final item in _evidenceFiles) {
        request.files.add(await http.MultipartFile.fromPath(
            'evidence[]', (item['file'] as File).path));
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final data     = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() => _isLoading = false);
        _showMessage(tr.get('report_submitted_success'), isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? tr.get('submission_failed'));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(tr.get('network_error'));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tr       = context.watch<LanguageProvider>().tr;
    final t        = context.watch<ThemeProvider>().theme;
    final cardBg   = t.isNight ? const Color(0xFF1A3A5C) : Colors.white;
    final labelClr = t.isNight ? const Color(0xFFC9A84C) : _navy;
    final hintClr  = t.isNight
        ? Colors.white.withOpacity(0.4)
        : _textGrey.withOpacity(0.7);
    final fieldBg  = t.isNight ? const Color(0xFF112D4E) : _inputBg;
    final fieldBdr = t.isNight ? Colors.white.withOpacity(0.1) : _border;
    final textClr  = t.isNight ? Colors.white.withOpacity(0.9) : _navy;

    return Scaffold(
      backgroundColor:
          t.isNight ? const Color(0xFF112D4E) : const Color(0xFFF0F4F8),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Pre-filled station banner ─────────────────────────────
            if (widget.preselectedStationName.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _navy.withOpacity(0.15), width: 1.5)),
                child: Row(children: [
                  Icon(Icons.local_police_rounded,
                      size: 16, color: _navy.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr.get('reporting_to')} ${widget.preselectedStationName}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _navy.withOpacity(0.75)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // ── Incident Details ──────────────────────────────────────
            _buildSection(
              title: tr.get('incident_details'),
              icon: Icons.report_problem_outlined,
              labelClr: labelClr, cardBg: cardBg, t: t,
              children: [
                _buildLabel(tr.get('category'), labelClr),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: fieldBdr, width: 1.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(tr.get('select_crime_type'),
                          style: TextStyle(color: hintClr, fontSize: 13)),
                      value: _selectedCategory,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: t.isNight
                              ? Colors.white.withOpacity(0.5)
                              : _navy.withOpacity(0.5)),
                      dropdownColor: t.isNight
                          ? const Color(0xFF1A3A5C)
                          : Colors.white,
                      style: TextStyle(color: textClr, fontSize: 13),
                      menuMaxHeight: 300,
                      items: _categoryItems
                          .map((c) => DropdownMenuItem(
                                value: c['value'],
                                child: Text(tr.get(c['key']!),
                                    style: TextStyle(
                                        color: textClr,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(tr.get('date'), labelClr),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? _navy.withOpacity(0.5)
                                    : fieldBdr,
                                width: _selectedDate != null ? 2 : 1.5)),
                            child: Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16,
                                  color: t.isNight
                                      ? _gold
                                      : _navy.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? tr.get('select_date')
                                      : '${_selectedDate!.day}/'
                                        '${_selectedDate!.month}/'
                                        '${_selectedDate!.year}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _selectedDate == null
                                          ? hintClr
                                          : textClr,
                                      fontWeight: _selectedDate != null
                                          ? FontWeight.w600
                                          : FontWeight.w400),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(tr.get('time'), labelClr),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTime != null
                                    ? _navy.withOpacity(0.5)
                                    : fieldBdr,
                                width: _selectedTime != null ? 2 : 1.5)),
                            child: Row(children: [
                              Icon(Icons.access_time_rounded,
                                  size: 16,
                                  color: t.isNight
                                      ? _gold
                                      : _navy.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTime == null
                                      ? tr.get('select_time')
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _selectedTime == null
                                          ? hintClr
                                          : textClr,
                                      fontWeight: _selectedTime != null
                                          ? FontWeight.w600
                                          : FontWeight.w400),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),

            const SizedBox(height: 16),

            // ── Location ──────────────────────────────────────────────
            _buildSection(
              title: tr.get('location'),
              icon: Icons.location_on_outlined,
              labelClr: labelClr, cardBg: cardBg, t: t,
              children: [
                GestureDetector(
                  onTap: _openMapPicker,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _latitude != null
                            ? _navy.withOpacity(0.4)
                            : fieldBdr,
                        width: _latitude != null ? 2 : 1.5)),
                    child: _latitude != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 32,
                                  color: t.isNight ? _gold : _navy),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(_areaName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: textClr,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              const SizedBox(height: 4),
                              Text(tr.get('tap_to_change_location'),
                                  style: TextStyle(
                                      color: hintClr, fontSize: 11)),
                            ])
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined,
                                  size: 36, color: hintClr),
                              const SizedBox(height: 8),
                              Text(tr.get('tap_to_pick_location'),
                                  style: TextStyle(
                                      color: hintClr, fontSize: 13)),
                            ]),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Get Current Location button ───────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () async {
                      setState(() => _isFetchingStation = true);
                      try {
                        bool serviceEnabled =
                            await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          _showMessage(
                              'Please enable GPS/location services on your device');
                          return;
                        }
                        LocationPermission permission =
                            await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission =
                              await Geolocator.requestPermission();
                          if (permission == LocationPermission.denied) {
                            _showMessage('Location permission denied');
                            return;
                          }
                        }
                        if (permission ==
                            LocationPermission.deniedForever) {
                          _showMessage(
                              'Location permission permanently denied. Enable it in Settings.');
                          return;
                        }

                        final position =
                            await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.best,
                        ).timeout(const Duration(seconds: 15));

                        // ── Clean single-location geocoding ───────────
                        String placeName = '';
                        try {
                          final placemarks =
                              await placemarkFromCoordinates(
                                  position.latitude, position.longitude);
                          placeName = _buildPlaceName(placemarks);
                        } catch (e) {
                          debugPrint('[Geocoding] failed: $e');
                        }

                        if (placeName.isEmpty) {
                          placeName =
                              '${position.latitude.toStringAsFixed(5)}, '
                              '${position.longitude.toStringAsFixed(5)}';
                        }

                        setState(() {
                          _latitude  = position.latitude;
                          _longitude = position.longitude;
                          _areaName  = placeName;
                        });

                        if (_stationsLoaded) {
                          _autoSelectNearestStation(
                              position.latitude, position.longitude);
                        }
                      } on TimeoutException {
                        _showMessage(
                            'Location timed out. Make sure GPS is on.');
                      } catch (e) {
                        _showMessage(
                            'Could not get location. Try picking on map.');
                        debugPrint('[Location] error: $e');
                      } finally {
                        if (mounted)
                          setState(() => _isFetchingStation = false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: t.isNight
                              ? _gold.withOpacity(0.5)
                              : _navy.withOpacity(0.3),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      foregroundColor: t.isNight ? _gold : _navy,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location_rounded,
                            size: 18,
                            color: t.isNight
                                ? _gold
                                : _navy.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text(
                          tr.get('get_current_location'),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: t.isNight
                                  ? _gold
                                  : _navy.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                _buildLabel(tr.get('landmark_hintt'), labelClr),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: fieldBdr, width: 1.5)),
                  child: TextField(
                    controller: _landmarkController,
                    style: TextStyle(color: textClr, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: tr.get('landmark_hint'),
                      hintStyle:
                          TextStyle(color: hintClr, fontSize: 13),
                      prefixIcon: Icon(Icons.place_outlined,
                          color: t.isNight
                              ? Colors.white.withOpacity(0.4)
                              : _navy.withOpacity(0.5),
                          size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Police Station ────────────────────────────────────────
            _buildSection(
              title: tr.get('police_station'),
              icon: Icons.local_police_outlined,
              labelClr: labelClr, cardBg: cardBg, t: t,
              children: [
                _buildStationCard(t, textClr, hintClr, fieldBg, fieldBdr),
              ],
            ),

            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────────
            _buildSection(
              title: tr.get('description'),
              icon: Icons.description_outlined,
              labelClr: labelClr, cardBg: cardBg, t: t,
              children: [
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: fieldBdr, width: 1.5)),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: TextStyle(color: textClr, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: tr.get('description_hint'),
                      hintStyle:
                          TextStyle(color: hintClr, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Evidence ──────────────────────────────────────────────
            _buildSection(
              title: tr.get('evidence'),
              icon: Icons.attach_file_rounded,
              labelClr: labelClr, cardBg: cardBg, t: t,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEvidenceBtn(
                        icon: Icons.camera_alt_rounded,
                        label: tr.get('camera'),
                        color: const Color(0xFF1976D2),
                        onTap: _pickFromCamera, t: t),
                    _buildEvidenceBtn(
                        icon: Icons.photo_library_rounded,
                        label: tr.get('gallery'),
                        color: const Color(0xFF7B1FA2),
                        onTap: _pickFromGallery, t: t),
                    _buildEvidenceBtn(
                        icon: Icons.videocam_rounded,
                        label: tr.get('video'),
                        color: const Color(0xFFD32F2F),
                        onTap: _pickVideo, t: t),
                    _buildEvidenceBtn(
                        icon: _isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        label: _isRecording
                            ? tr.get('stop')
                            : tr.get('audio'),
                        color: _isRecording
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF388E3C),
                        onTap: _toggleAudio, t: t,
                        isActive: _isRecording),
                  ],
                ),
                if (_isRecording) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            color: Color(0xFFDC2626), size: 12),
                        const SizedBox(width: 6),
                        Text(tr.get('recording_in_progress'),
                            style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
                if (_evidenceFiles.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 88,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidenceFiles.length,
                      itemBuilder: (_, i) =>
                          _buildEvidencePreview(i, t, tr),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: fieldBdr)),
                    child: Column(children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 28, color: hintClr),
                      const SizedBox(height: 6),
                      Text(tr.get('no_evidence_yet'),
                          style:
                              TextStyle(color: hintClr, fontSize: 12)),
                      Text(tr.get('evidence_optional_note'),
                          style: TextStyle(
                              color: hintClr.withOpacity(0.6),
                              fontSize: 11)),
                    ]),
                  ),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.info_outline, size: 13, color: hintClr),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(tr.get('evidence_size_note'),
                          style:
                              TextStyle(fontSize: 11, color: hintClr))),
                ]),
              ],
            ),

            const SizedBox(height: 16),

            // ── Reporter Role ─────────────────────────────────────────
            _buildSection(
              title: tr.get('reporter_type'),
              icon: Icons.person_outline_rounded,
              labelClr: labelClr, cardBg: cardBg, t: t,
              children: [
                _buildLabel(tr.get('i_am_the'), labelClr),
                const SizedBox(height: 10),
                Row(children: [
                  _buildRoleOption(
                      _roleItems[0], tr, t, textClr, fieldBg, fieldBdr),
                  const SizedBox(width: 8),
                  _buildRoleOption(
                      _roleItems[1], tr, t, textClr, fieldBg, fieldBdr),
                  const SizedBox(width: 8),
                  _buildRoleOption(
                      _roleItems[2], tr, t, textClr, fieldBg, fieldBdr),
                ]),
                const SizedBox(height: 10),
                if (_selectedRole == 'Anonymous')
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A5C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.shield_outlined,
                          size: 14,
                          color: t.isNight
                              ? _gold
                              : _navy.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(tr.get('info_confidential'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: t.isNight
                                      ? Colors.white.withOpacity(0.6)
                                      : _navy.withOpacity(0.65)))),
                    ]),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Confirmation ──────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _confirmed = !_confirmed),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _confirmed
                        ? _navy.withOpacity(0.4)
                        : fieldBdr,
                    width: _confirmed ? 2 : 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(t.isNight ? 0.15 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: _confirmed ? _navy : fieldBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _confirmed ? _navy : fieldBdr,
                          width: 1.5)),
                      child: _confirmed
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr.get('accuracy_confirmation'),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textClr)),
                          const SizedBox(height: 4),
                          Text(tr.get('accuracy_confirmation_text'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: hintClr,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.isNight ? _gold : _navy,
                  foregroundColor: t.isNight ? _navyDark : Colors.white,
                  disabledBackgroundColor: t.isNight
                      ? _gold.withOpacity(0.5)
                      : _navy.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            tr.get('submit_report').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                tr.get('evidence_legal_note'),
                style: TextStyle(
                    fontSize: 11, color: hintClr.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Station card ──────────────────────────────────────────────────────────

  Widget _buildStationCard(
    AppTheme t,
    Color textClr,
    Color hintClr,
    Color fieldBg,
    Color fieldBdr,
  ) {
    final tr = context.read<LanguageProvider>().tr;

    Widget selectButton({String label = ''}) {
      final effectiveLabel = label.isEmpty ? tr.get('select') : label;
      return TextButton(
        onPressed: _showStationPicker,
        style: TextButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          backgroundColor: t.isNight
              ? _gold.withOpacity(0.15)
              : _navy.withOpacity(0.08),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(effectiveLabel,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: t.isNight ? _gold : _navy)),
      );
    }

    // State A: station selected
    if (_selectedStationId != null) {
      final isPreselected = widget.preselectedStationName.isNotEmpty &&
          _selectedStationName == widget.preselectedStationName;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.isNight
              ? _navy.withOpacity(0.5)
              : _navy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: t.isNight
                ? _gold.withOpacity(0.3)
                : _navy.withOpacity(0.2),
            width: 1.5)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _navy, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_police_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedStationName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textClr)),
                if (_selectedStationAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_selectedStationAddress,
                      style: TextStyle(
                          fontSize: 11,
                          color: textClr.withOpacity(0.55))),
                ],
                if (isPreselected) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 10, color: Color(0xFF27AE60)),
                        const SizedBox(width: 4),
                        Text(tr.get('pre_selected'),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF27AE60))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          selectButton(label: tr.get('change')),
        ]),
      );
    }

    // State B: fetching
    if (_isFetchingStation) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fieldBdr, width: 1.5)),
        child: Row(children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: t.isNight ? _gold : _navy)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tr.get('finding_nearest_station'),
                style: TextStyle(color: hintClr, fontSize: 13))),
          const SizedBox(width: 8),
          selectButton(label: tr.get('pick_manually')),
        ]),
      );
    }

    // State C: nothing selected yet
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fieldBdr, width: 1.5)),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _latitude == null
                    ? tr.get('no_station_selected')
                    : tr.get('station_auto_detect_failed'),
                style: TextStyle(
                    color: textClr.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(tr.get('tap_select_station_hint'),
                  style: TextStyle(
                      color: hintClr, fontSize: 11, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        selectButton(),
      ]),
    );
  }

  // ── Reused helpers ────────────────────────────────────────────────────────

  Widget _buildSection({
    required String    title,
    required IconData  icon,
    required Color     labelClr,
    required Color     cardBg,
    required AppTheme  t,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(t.isNight ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C)
                    .withOpacity(t.isNight ? 0.25 : 0.08),
                borderRadius: BorderRadius.circular(8)),
              child: Icon(icon,
                  size: 17, color: t.isNight ? _gold : _navy),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: labelClr,
                    letterSpacing: 0.2)),
          ]),
          Divider(
              color: t.isNight
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFDDE6F0),
              height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2));

  Widget _buildEvidenceBtn({
    required IconData    icon,
    required String      label,
    required Color       color,
    required VoidCallback onTap,
    required AppTheme    t,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: isActive
                ? color
                : color.withOpacity(t.isNight ? 0.15 : 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withOpacity(isActive ? 1 : 0.3),
                width: 1.5)),
          child: Icon(icon, size: 22,
              color: isActive ? Colors.white : color),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: t.isNight
                    ? Colors.white.withOpacity(0.6)
                    : _navy.withOpacity(0.6))),
      ]),
    );
  }

  Widget _buildRoleOption(
    Map<String, String> roleItem,
    AppLocalizations    tr,
    AppTheme            t,
    Color               textClr,
    Color               fieldBg,
    Color               fieldBdr,
  ) {
    final apiValue = roleItem['value']!;
    final selected = _selectedRole == apiValue;
    final IconData icon = apiValue == 'Victim'
        ? Icons.person_rounded
        : apiValue == 'Witness'
            ? Icons.visibility_rounded
            : Icons.person_off_rounded;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = apiValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _navy : fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _navy : fieldBdr, width: 1.5)),
          child: Column(children: [
            Icon(icon, size: 18,
                color: selected
                    ? Colors.white
                    : _navy.withOpacity(0.5)),
            const SizedBox(height: 4),
            Text(
              tr.get(roleItem['key']!),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : textClr.withOpacity(0.6)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEvidencePreview(
      int index, AppTheme t, AppLocalizations tr) {
    final item      = _evidenceFiles[index];
    final type      = item['type'] as String;
    final thumbnail = item['thumbnail'] as File?;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EvidencePreviewScreen(
                  evidenceFiles: _evidenceFiles,
                  initialIndex: index))),
      child: Stack(children: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          width: 84, height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: t.isNight
                ? const Color(0xFF112D4E)
                : const Color(0xFFF0F4F8),
            border: Border.all(
              color: t.isNight
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFFDDE6F0),
              width: 1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: type == 'image'
                ? Image.file(item['file'] as File, fit: BoxFit.cover)
                : type == 'video'
                    ? thumbnail != null
                        ? Stack(fit: StackFit.expand, children: [
                            Image.file(thumbnail, fit: BoxFit.cover),
                            const Center(
                                child: Icon(Icons.play_circle_fill,
                                    color: Colors.white, size: 30)),
                          ])
                        : Center(
                            child: Icon(Icons.videocam_rounded,
                                color: t.isNight
                                    ? Colors.white.withOpacity(0.5)
                                    : _navy.withOpacity(0.4),
                                size: 32))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.audiotrack_rounded,
                                color: t.isNight
                                    ? Colors.white.withOpacity(0.5)
                                    : _navy.withOpacity(0.4),
                                size: 26),
                            const SizedBox(height: 4),
                            Text(tr.get('audio'),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: t.isNight
                                        ? Colors.white.withOpacity(0.4)
                                        : _navy.withOpacity(0.4))),
                          ],
                        )),
          ),
        ),
        Positioned(
          top: 0, right: 10,
          child: GestureDetector(
            onTap: () =>
                setState(() => _evidenceFiles.removeAt(index)),
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                  color: Color(0xFFDC2626), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 13),
            ),
          ),
        ),
      ]),
    );
  }
}