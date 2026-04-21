import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/nearby_mosque.dart';
import '../services/nearby_mosque_service.dart';

class NearbyMosqueController extends ChangeNotifier {
  bool _disposed = false;

  bool loading = false;
  String? error;
  String? infoMessage;

  int radiusMeters = 3000;
  double? userLatitude;
  double? userLongitude;

  List<NearbyMosque> mosques = const [];

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialize() async {
    await fetchNearbyMosques();
  }

  Future<void> setRadiusAndReload(int value) async {
    if (radiusMeters == value) return;
    radiusMeters = value;
    _safeNotify();
    await fetchNearbyMosques();
  }

  Future<void> fetchNearbyMosques() async {
    if (_disposed) return;

    loading = true;
    error = null;
    infoMessage = null;
    _safeNotify();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (_disposed) return;
      if (!serviceEnabled) {
        error = 'Layanan lokasi belum aktif. Aktifkan GPS lalu coba lagi.';
        mosques = const [];
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (_disposed) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (_disposed) return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        error = 'Izin lokasi diperlukan untuk mencari masjid terdekat.';
        mosques = const [];
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (_disposed) return;

      userLatitude = position.latitude;
      userLongitude = position.longitude;

      final data = await NearbyMosqueService.instance.getNearbyMosques(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: radiusMeters,
      );
      if (_disposed) return;

      mosques = data;
      if (data.isEmpty) {
        infoMessage =
            'Belum ada data masjid pada radius ${_radiusLabel(radiusMeters)} dari lokasi Anda.';
      }
    } catch (e) {
      if (_disposed) return;
      error = e.toString();
      mosques = const [];
    } finally {
      if (!_disposed) {
        loading = false;
        _safeNotify();
      }
    }
  }

  String radiusLabel() => _radiusLabel(radiusMeters);

  String _radiusLabel(int radius) {
    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(radius % 1000 == 0 ? 0 : 1)} km';
    }
    return '$radius m';
  }
}
