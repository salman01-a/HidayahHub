import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaView extends StatefulWidget {
  const QiblaView({super.key});

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView> {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLon = 39.8262;

  CameraController? _cameraController;
  StreamSubscription<CompassEvent>? _compassSub;

  double? _heading;
  double? _qiblaBearing;
  bool _isLoading = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    await _initializeCamera();
    await _initializeLocationAndQibla();
    _startCompassStream();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
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

      if (!mounted) return;
      _cameraController = controller;
    } catch (_) {
      _statusMessage =
          'Kamera tidak tersedia. Kompas tetap bisa dipakai tanpa tampilan kamera.';
    }
  }

  Future<void> _initializeLocationAndQibla() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusMessage = 'Aktifkan layanan lokasi untuk menentukan arah kiblat.';
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _statusMessage = 'Izin lokasi diperlukan agar arah kiblat akurat.';
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _qiblaBearing = _bearingToKaaba(position.latitude, position.longitude);
    } catch (_) {
      _statusMessage = 'Gagal mendapatkan lokasi. Coba lagi beberapa saat.';
    }
  }

  void _startCompassStream() {
    _compassSub = FlutterCompass.events?.listen((event) {
      final heading = event.heading;
      if (heading == null || !mounted) return;
      setState(() {
        _heading = _normalize(heading);
      });
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

  double _angleDiff(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  bool get _isAligned {
    if (_heading == null || _qiblaBearing == null) return false;
    return _angleDiff(_heading!, _qiblaBearing!).abs() <= 8;
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: cameraReady
                ? CameraPreview(_cameraController!)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0C1B2A), Color(0xFF15364C)],
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                const Spacer(),
                _compassDial(),
                const SizedBox(height: 18),
                _statusBanner(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Penunjuk Arah Kiblat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          if (_heading != null)
            Text(
              '${_heading!.round()}°',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _compassDial() {
    if (_isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    final heading = _heading;
    final qibla = _qiblaBearing;

    if (heading == null || qibla == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Kompas atau lokasi belum siap.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    }

    final relativeQibla = _angleDiff(heading, qibla);

    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2,
                  ),
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
              Transform.rotate(
                angle: _toRad(relativeQibla),
                child: const Icon(
                  Icons.navigation_rounded,
                  size: 92,
                  color: Color(0xFF55E1B8),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Arah Kiblat ${qibla.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _statusBanner() {
    final customStatus = _statusMessage;
    if (_isLoading) {
      return _buildBanner(
        message: 'Menyiapkan kamera, kompas, dan lokasi...',
        aligned: false,
      );
    }
    if (customStatus != null && (_qiblaBearing == null || _heading == null)) {
      return _buildBanner(message: customStatus, aligned: false);
    }

    if (_heading == null || _qiblaBearing == null) {
      return _buildBanner(
        message: 'Gerakkan ponsel untuk kalibrasi kompas.',
        aligned: false,
      );
    }

    if (_isAligned) {
      return _buildBanner(
        message: 'Arah kiblat Anda sudah tepat. Silakan sholat menghadap arah ini.',
        aligned: true,
      );
    }

    final diff = _angleDiff(_heading!, _qiblaBearing!);
    final side = diff > 0 ? 'kanan' : 'kiri';

    return _buildBanner(
      message:
          'Putar sekitar ${diff.abs().toStringAsFixed(1)}° ke $side agar menghadap kiblat.',
      aligned: false,
    );
  }

  Widget _buildBanner({required String message, required bool aligned}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: aligned
            ? const Color(0xFF0E7A57).withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: aligned
              ? const Color(0xFF63F0C2)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            aligned ? Icons.check_circle_rounded : Icons.explore_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
