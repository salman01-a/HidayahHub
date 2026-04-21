import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  NearbyMosque? activeDestination;
  List<LatLng> activeRoute = const [];
  double? activeRouteDistanceKm;
  int? activeRouteDurationMin;
  bool routeLoading = false;

  StreamSubscription<Position>? _positionSub;
  bool _isFetchingRoute = false;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteFetchAt;

  bool get navigationActive => activeDestination != null;

  @override
  void dispose() {
    _disposed = true;
    _positionSub?.cancel();
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

  Future<void> startNavigation(NearbyMosque mosque) async {
    if (_disposed) return;

    final lat = userLatitude;
    final lon = userLongitude;
    if (lat == null || lon == null) {
      error = 'Lokasi Anda belum tersedia.';
      _safeNotify();
      return;
    }

    activeDestination = mosque;
    routeLoading = true;
    activeRouteDistanceKm = null;
    activeRouteDurationMin = null;
    activeRoute = [LatLng(lat, lon), LatLng(mosque.latitude, mosque.longitude)];
    _safeNotify();

    _startLivePositionTracking();
    await _refreshActiveRoute(force: true);
  }

  void stopNavigation() {
    _positionSub?.cancel();
    _positionSub = null;
    activeDestination = null;
    activeRoute = const [];
    activeRouteDistanceKm = null;
    activeRouteDurationMin = null;
    routeLoading = false;
    _lastRouteOrigin = null;
    _lastRouteFetchAt = null;
    _safeNotify();
  }

  void _startLivePositionTracking() {
    _positionSub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) async {
        await _handlePositionUpdate(position);
      },
      onError: (_) {},
    );
  }

  Future<void> _handlePositionUpdate(Position position) async {
    if (_disposed) return;

    userLatitude = position.latitude;
    userLongitude = position.longitude;
    _safeNotify();

    if (!navigationActive) return;

    final destination = activeDestination;
    if (destination == null) return;

    final current = LatLng(position.latitude, position.longitude);
    final destinationPoint = LatLng(destination.latitude, destination.longitude);

    final remainingMeters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      destinationPoint.latitude,
      destinationPoint.longitude,
    );

    if (remainingMeters <= 20) {
      stopNavigation();
      infoMessage = 'Anda sudah sampai di ${destination.name}.';
      _safeNotify();
      return;
    }

    if (_shouldRefreshRoute(current)) {
      await _refreshActiveRoute();
    }
  }

  bool _shouldRefreshRoute(LatLng current) {
    final lastOrigin = _lastRouteOrigin;
    final lastFetchAt = _lastRouteFetchAt;
    if (lastOrigin == null || lastFetchAt == null) {
      return true;
    }

    final movedMeters = Geolocator.distanceBetween(
      lastOrigin.latitude,
      lastOrigin.longitude,
      current.latitude,
      current.longitude,
    );

    final elapsed = DateTime.now().difference(lastFetchAt);
    return movedMeters >= 25 || elapsed.inSeconds >= 8;
  }

  Future<void> _refreshActiveRoute({bool force = false}) async {
    if (_disposed || _isFetchingRoute) return;

    final lat = userLatitude;
    final lon = userLongitude;
    final destination = activeDestination;
    if (lat == null || lon == null || destination == null) return;

    final start = LatLng(lat, lon);
    final end = LatLng(destination.latitude, destination.longitude);

    if (!force && !_shouldRefreshRoute(start)) return;

    _isFetchingRoute = true;
    routeLoading = true;
    _safeNotify();

    try {
      final route = await NearbyMosqueService.instance.getRoadRoute(
        start: start,
        destination: end,
      );
      if (_disposed) return;

      activeRoute = route.points;
      activeRouteDistanceKm = route.distanceKm;
      activeRouteDurationMin = route.durationMin;
      _lastRouteOrigin = start;
      _lastRouteFetchAt = DateTime.now();
    } catch (_) {
      if (_disposed) return;

      final fallbackDistance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      activeRoute = [start, end];
      activeRouteDistanceKm = fallbackDistance / 1000;
      activeRouteDurationMin = null;
      _lastRouteOrigin = start;
      _lastRouteFetchAt = DateTime.now();
    } finally {
      if (!_disposed) {
        routeLoading = false;
        _isFetchingRoute = false;
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
