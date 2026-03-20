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

  @override
  void initState() { super.initState(); _initGPS(); }

  Future<void> _initGPS() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          final latlng = LatLng(pos.latitude, pos.longitude);
          setState(() { _markerPos = latlng; _loadingGPS = false; });
          Future.delayed(const Duration(milliseconds: 500), () => _mapController.move(latlng, 15));
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
      // Try Photon first (more accurate than Nominatim)
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/reverse?lat=${pos.latitude}&lon=${pos.longitude}&limit=1',
      );
      final photonResp = await http.get(photonUrl, headers: {
        'User-Agent': 'HawassaCrimeReport/1.0',
      }).timeout(const Duration(seconds: 10));

      if (photonResp.statusCode == 200) {
        final data     = jsonDecode(photonResp.body);
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final props   = features[0]['properties'] as Map<String, dynamic>? ?? {};
          final name    = props['name'] as String? ?? '';
          final street  = props['street'] as String? ?? '';
          final city    = props['city'] ?? props['town'] ?? props['village'] ?? props['county'] ?? '';
          String result;
          if (name.isNotEmpty && name != city) {
            result = city.isNotEmpty ? '$name, $city' : name;
          } else if (street.isNotEmpty && city.isNotEmpty) {
            result = '$street, $city';
          } else if (city.isNotEmpty) {
            result = city;
          } else {
            result = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          }
          if (mounted) setState(() => _address = result);
          return;
        }
      }

      // Fallback to Nominatim if Photon fails
      final nomUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
      );
      final nomResp = await http.get(nomUrl, headers: {
        'User-Agent': 'HawassaCrimeReport/1.0', 'Accept-Language': 'en',
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
          result = city;
        } else {
          result = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        }
        if (mounted) setState(() => _address = result);
      } else {
        if (mounted) setState(() => _address =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
      }
    } catch (e) {
      if (mounted) setState(() => _address =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _onTap(TapPosition tap, LatLng pos) {
    _mapController.move(pos, _mapController.camera.zoom);
    setState(() { _markerPos = pos; _hasPicked = true; _address = ''; });
    _fetchAddress(pos);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    if (_loadingGPS) {
      return Scaffold(
        backgroundColor: t.scaffoldBg,
        appBar: AppBar(
          backgroundColor: t.appBarColor,
          foregroundColor: t.appBarFg,
          title: Text('Pick Location', style: TextStyle(color: t.appBarTextColor, fontSize: 16, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: t.buttonColor),
          const SizedBox(height: 16),
          Text('Getting your location...', style: TextStyle(color: t.primaryText)),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text('Pick Location', style: TextStyle(color: t.appBarTextColor, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: t.appBarFg),
            onPressed: () async {
              try {
                final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                final latlng = LatLng(pos.latitude, pos.longitude);
                _mapController.move(latlng, 15);
                setState(() { _markerPos = latlng; _hasPicked = true; _address = ''; });
                _fetchAddress(latlng);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Stack(children: [
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
            ),
            MarkerLayer(markers: [
              Marker(
                point: _markerPos,
                width: 50, height: 50,
                child: Icon(Icons.location_pin,
                    color: _hasPicked ? Colors.red : Colors.blue, size: 50),
              ),
            ]),
          ],
        ),

        // TOP HINT
        Positioned(
          top: 12, left: 40, right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: t.appBarColor.withOpacity(0.88),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _hasPicked ? 'Tap again to change location' : 'Tap anywhere on the map to pick location',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.appBarFg, fontSize: 12),
            ),
          ),
        ),

        // BOTTOM PANEL
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -3))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selected Location',
                  style: TextStyle(color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF1A3A5C),
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_pin, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: !_hasPicked
                      ? Text('Tap on the map to select a location',
                          style: TextStyle(color: t.secondaryText, fontSize: 13))
                      : _loadingAddress
                          ? Row(children: [
                              SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: t.buttonColor)),
                              const SizedBox(width: 8),
                              Text('Getting address...', style: TextStyle(color: t.secondaryText, fontSize: 13)),
                            ])
                          : Text(
                              _address.isEmpty ? 'Location selected' : _address,
                              style: TextStyle(fontSize: 13, color: t.primaryText),
                            ),
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: (!_hasPicked || _loadingAddress)
                      ? null
                      : () => Navigator.pop(context, {
                            'latitude': _markerPos.latitude,
                            'longitude': _markerPos.longitude,
                            'address': _address.isEmpty
                                ? '${_markerPos.latitude.toStringAsFixed(5)}, ${_markerPos.longitude.toStringAsFixed(5)}'
                                : _address,
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF1A3A5C),
                    foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    !_hasPicked ? 'Pick a location first' : 'Confirm Location',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}