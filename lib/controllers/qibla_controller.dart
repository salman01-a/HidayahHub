import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaController extends ChangeNotifier {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLon = 39.8262;

  CameraController? cameraController;
  StreamSubscription<CompassEvent>? _compassSub;

  double? heading;
  double? qiblaBearing;
  double? currentLatitude;
  double? currentLongitude;
  bool isLoading = true;
  bool locationServiceDisabled = false;
  bool locationPermissionDeniedForever = false;
  String? statusMessage;

  bool _disposed = false;

  bool get isAligned {
    if (heading == null || qiblaBearing == null) return false;
    return angleDiff(heading!, qiblaBearing!).abs() <= 8;
  }

  @override
  void dispose() {
    _disposed = true;
    _compassSub?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialize() async {
    isLoading = true;
    locationServiceDisabled = false;
    locationPermissionDeniedForever = false;
    statusMessage = null;
    _safeNotify();

    await _initializeCamera();
    await initializeLocationAndQibla();
    _startCompassStream();

    isLoading = false;
    _safeNotify();
  }

  Future<void> initializeLocationAndQibla() async {
    locationServiceDisabled = false;
    locationPermissionDeniedForever = false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationServiceDisabled = true;
      statusMessage = 'Aktifkan layanan lokasi untuk menentukan arah kiblat.';
      _safeNotify();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (permission == LocationPermission.deniedForever) {
        locationPermissionDeniedForever = true;
      }
      statusMessage = 'Izin lokasi diperlukan agar arah kiblat akurat.';
      _safeNotify();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      qiblaBearing = _bearingToKaaba(position.latitude, position.longitude);
      statusMessage = null;
    } catch (_) {
      statusMessage = 'Gagal mendapatkan lokasi. Coba lagi beberapa saat.';
    }

    _safeNotify();
  }

  Future<void> openLocationSettingsAndRefresh() async {
    await Geolocator.openLocationSettings();
    await initializeLocationAndQibla();
  }

  Future<void> openAppSettingsAndRefresh() async {
    await Geolocator.openAppSettings();
    await initializeLocationAndQibla();
  }

  double angleDiff(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  double toRad(double deg) => deg * math.pi / 180;

  String toDms(double decimal) {
    final absValue = decimal.abs();
    final degree = absValue.floor();
    final minuteRaw = (absValue - degree) * 60;
    final minute = minuteRaw.floor();
    var second = ((minuteRaw - minute) * 60).round();

    var d = degree;
    var m = minute;
    if (second == 60) {
      second = 0;
      m += 1;
    }
    if (m == 60) {
      m = 0;
      d += 1;
    }

    return '$d°${m.toString().padLeft(2, '0')}\'${second.toString().padLeft(2, '0')}"';
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.where(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      final selected = backCamera.isNotEmpty ? backCamera.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (_disposed) return;
      cameraController = controller;
    } catch (_) {
      statusMessage =
          'Kamera tidak tersedia. Kompas tetap bisa dipakai tanpa tampilan kamera.';
    }
  }

  void _startCompassStream() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      final value = event.heading;
      if (value == null || _disposed) return;
      heading = _normalize(value);
      _safeNotify();
    });
  }

  double _bearingToKaaba(double lat, double lon) {
    final phi1 = _toRad(lat);
    final phi2 = _toRad(_kaabaLat);
    final deltaLon = _toRad(_kaabaLon - lon);

    final y = math.sin(deltaLon);
    final x =
        math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(deltaLon);

    return _normalize(_toDeg(math.atan2(y, x)));
  }

  double _normalize(double value) {
    return (value % 360 + 360) % 360;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  double _toDeg(double rad) => rad * 180 / math.pi;
}
