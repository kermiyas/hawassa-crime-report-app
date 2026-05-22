// lib/screens/reports/map_picker_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});
  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();

  LatLng _markerPos      = const LatLng(7.0621, 38.4759);
  bool   _hasPicked      = false;
  String _address        = '';
  bool   _loadingGPS     = true;
  bool   _loadingAddress = false;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _gold     = Color(0xFFC9A84C);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _red      = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _initGPS();
  }

  Future<void> _initGPS() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          final latlng = LatLng(pos.latitude, pos.longitude);
          setState(() { _markerPos = latlng; _loadingGPS = false; });
          Future.delayed(const Duration(milliseconds: 500),
            () => _mapController.move(latlng, 15));
        }
      } else {
        if (mounted) setState(() => _loadingGPS = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGPS = false);
    }
  }

  Future<void> _fetchAddress(LatLng pos) async {
    setState(() { _loadingAddress = true; _address = ''; });
    try {
      // Try Photon first
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&limit=1');
      final photonResp = await http.get(photonUrl,
        headers: {'User-Agent': 'HawassaCrimeReport/1.0'})
        .timeout(const Duration(seconds: 10));

      if (photonResp.statusCode == 200) {
        final data     = jsonDecode(photonResp.body);
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final props  = features[0]['properties'] as Map<String, dynamic>? ?? {};
          final name   = props['name'] as String? ?? '';
          final street = props['street'] as String? ?? '';
          final city   = props['city'] ?? props['town'] ??
              props['village'] ?? props['county'] ?? '';
          String result;
          if (name.isNotEmpty && name != city) {
            result = city.isNotEmpty ? '$name, $city' : name;
          } else if (street.isNotEmpty && city.isNotEmpty) {
            result = '$street, $city';
          } else if (city.isNotEmpty) {
            result = city.toString();
          } else {
            result = '${pos.latitude.toStringAsFixed(5)}, '
                '${pos.longitude.toStringAsFixed(5)}';
          }
          if (mounted) setState(() => _address = result);
          return;
        }
      }

      // Fallback to Nominatim
      final nomUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1');
      final nomResp = await http.get(nomUrl, headers: {
        'User-Agent': 'HawassaCrimeReport/1.0',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 10));

      if (nomResp.statusCode == 200) {
        final data   = jsonDecode(nomResp.body);
        final addr   = data['address'] as Map<String, dynamic>? ?? {};
        final road   = addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? '';
        final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? '';
        final city   = addr['city'] ?? addr['town'] ?? addr['village'] ?? '';
        String result;
        if (road.isNotEmpty && city.isNotEmpty) {
          result = '$road, $city';
        } else if (suburb.isNotEmpty && city.isNotEmpty) {
          result = '$suburb, $city';
        } else if (city.isNotEmpty) {
          result = city.toString();
        } else {
          result = '${pos.latitude.toStringAsFixed(5)}, '
              '${pos.longitude.toStringAsFixed(5)}';
        }
        if (mounted) setState(() => _address = result);
      } else {
        if (mounted) setState(() => _address =
          '${pos.latitude.toStringAsFixed(5)}, '
          '${pos.longitude.toStringAsFixed(5)}');
      }
    } catch (e) {
      if (mounted) setState(() => _address =
        '${pos.latitude.toStringAsFixed(5)}, '
        '${pos.longitude.toStringAsFixed(5)}');
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
      final latlng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latlng, 15);
      setState(() { _markerPos = latlng; _hasPicked = true; _address = ''; });
      _fetchAddress(latlng);
    } catch (_) {}
  }

  void _onTap(TapPosition tap, LatLng pos) {
    _mapController.move(pos, _mapController.camera.zoom);
    setState(() { _markerPos = pos; _hasPicked = true; _address = ''; });
    _fetchAddress(pos);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    // Loading GPS state
    if (_loadingGPS) {
      return Scaffold(
        backgroundColor: t.isNight
          ? const Color(0xFF112D4E) : const Color(0xFFF0F4F8),
        body: Stack(children: [
          // Navy header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_navyDark, _navy]),
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _white, size: 20)),
                  const Expanded(
                    child: Text('Pick Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _white, fontSize: 18,
                        fontWeight: FontWeight.w700))),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(
                child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _navy.withOpacity(0.1),
                        border: Border.all(
                          color: _gold.withOpacity(0.3), width: 2)),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: _navy, strokeWidth: 2.5)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Getting your location...',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: _navy)),
                    const SizedBox(height: 6),
                    Text('Please wait',
                      style: TextStyle(
                        fontSize: 13,
                        color: _navy.withOpacity(0.5))),
                  ],
                )),
              ),
            ]),
          ),
        ]),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markerPos,
              initialZoom: 15,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.crime_reporting_app',
  tileProvider: NetworkTileProvider(),
),
              MarkerLayer(markers: [
                Marker(
                  point: _markerPos,
                  width: 60, height: 60,
                  child: Column(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _hasPicked ? _red : _navy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_hasPicked ? _red : _navy)
                              .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: _white, width: 2.5)),
                      child: Icon(
                        _hasPicked
                          ? Icons.location_on_rounded
                          : Icons.my_location_rounded,
                        color: _white, size: 18),
                    ),
                    // Pin tail
                    Container(
                      width: 2, height: 12,
                      color: _hasPicked ? _red : _navy),
                    Container(
                      width: 8, height: 4,
                      decoration: BoxDecoration(
                        color: (_hasPicked ? _red : _navy).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4)),
                    ),
                  ]),
                ),
              ]),
            ],
          ),

          // ── Top nav bar overlay ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navyDark.withOpacity(0.95),
                    _navyDark.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                  child: Row(children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: _navyDark.withOpacity(0.7),
                        shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _white, size: 18)),
                    ),

                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _navyDark.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          Icon(Icons.touch_app_rounded,
                            size: 14, color: _gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _hasPicked
                                ? 'Tap to change location'
                                : 'Tap on map to pick location',
                              style: const TextStyle(
                                color: _white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500))),
                        ]),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // GPS button
                    Container(
                      decoration: BoxDecoration(
                        color: _navy.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gold.withOpacity(0.4), width: 1.5)),
                      child: IconButton(
                        onPressed: _goToCurrentLocation,
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: _gold, size: 20)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: t.isNight
                  ? const Color(0xFF0F2440)
                  : _white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: t.isNight
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),

                  // Header
                  Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _navy.withOpacity(t.isNight ? 0.25 : 0.08),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.location_on_outlined,
                        size: 17,
                        color: t.isNight ? _gold : _navy),
                    ),
                    const SizedBox(width: 10),
                    Text('Selected Location',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: t.isNight ? _white : _navy)),
                  ]),

                  const SizedBox(height: 14),

                  // Address display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.isNight
                        ? const Color(0xFF112D4E)
                        : const Color(0xFFF5F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: t.isNight
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFDDE6F0),
                        width: 1.5)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.place_rounded,
                          size: 18,
                          color: _hasPicked ? _red : (t.isNight
                            ? Colors.white.withOpacity(0.3)
                            : _navy.withOpacity(0.3))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: !_hasPicked
                            ? Text('Tap on the map to select a location',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: t.isNight
                                    ? Colors.white.withOpacity(0.4)
                                    : _navy.withOpacity(0.4)))
                            : _loadingAddress
                              ? Row(children: [
                                  SizedBox(width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: t.isNight ? _gold : _navy)),
                                  const SizedBox(width: 10),
                                  Text('Resolving address...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: t.isNight
                                        ? Colors.white.withOpacity(0.5)
                                        : _navy.withOpacity(0.5))),
                                ])
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _address.isEmpty
                                        ? 'Location selected'
                                        : _address,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: t.isNight ? _white : _navy,
                                        height: 1.4)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_markerPos.latitude.toStringAsFixed(5)}, '
                                      '${_markerPos.longitude.toStringAsFixed(5)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: t.isNight
                                          ? Colors.white.withOpacity(0.4)
                                          : _navy.withOpacity(0.4))),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: (!_hasPicked || _loadingAddress)
                        ? null
                        : () => Navigator.pop(context, {
                            'latitude':  _markerPos.latitude,
                            'longitude': _markerPos.longitude,
                            'address':   _address.isEmpty
                              ? '${_markerPos.latitude.toStringAsFixed(5)}, '
                                '${_markerPos.longitude.toStringAsFixed(5)}'
                              : _address,
                          }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.isNight ? _gold : _navy,
                        foregroundColor: t.isNight ? _navyDark : _white,
                        disabledBackgroundColor: t.isNight
                          ? _gold.withOpacity(0.3)
                          : _navy.withOpacity(0.3),
                        disabledForegroundColor: t.isNight
                          ? _navyDark.withOpacity(0.5)
                          : _white.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            !_hasPicked
                              ? Icons.touch_app_rounded
                              : Icons.check_circle_outline_rounded,
                            size: 20),
                          const SizedBox(width: 10),
                          Text(
                            !_hasPicked
                              ? 'Tap map to pick location'
                              : 'CONFIRM LOCATION',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}