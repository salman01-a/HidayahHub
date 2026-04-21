import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../controllers/qibla_controller.dart';

class QiblaView extends StatefulWidget {
  const QiblaView({super.key});

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView> {
  late final QiblaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QiblaController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        _controller.cameraController != null &&
        _controller.cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: cameraReady
                ? CameraPreview(_controller.cameraController!)
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
          if (_controller.heading != null)
            Text(
              '${_controller.heading!.round()}°',
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
    if (_controller.isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    final heading = _controller.heading;
    final qibla = _controller.qiblaBearing;

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

    final relativeQibla = _controller.angleDiff(heading, qibla);

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
                angle: _controller.toRad(relativeQibla),
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
        const SizedBox(height: 10),
        _buildCoordinateInfo(),
      ],
    );
  }

  Widget _buildCoordinateInfo() {
    String latitudeText() {
      final latitude = _controller.currentLatitude;
      if (latitude == null) return '--';
      return _controller.toDms(latitude);
    }

    String longitudeText() {
      final longitude = _controller.currentLongitude;
      if (longitude == null) return '--';
      return _controller.toDms(longitude);
    }

    final latitudeLabel = _controller.currentLatitude == null
        ? 'LS'
        : (_controller.currentLatitude! >= 0 ? 'LU' : 'LS');
    final longitudeLabel = _controller.currentLongitude == null
        ? 'BT'
        : (_controller.currentLongitude! >= 0 ? 'BT' : 'BB');

    Widget buildItem(String label, String value) {
      return Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildItem(latitudeLabel, latitudeText()),
          const SizedBox(width: 32),
          buildItem(longitudeLabel, longitudeText()),
        ],
      ),
    );
  }

  Widget _statusBanner() {
    final customStatus = _controller.statusMessage;
    if (_controller.isLoading) {
      return _buildBanner(
        message: 'Menyiapkan kamera, kompas, dan lokasi...',
        aligned: false,
      );
    }
    if (customStatus != null &&
        (_controller.qiblaBearing == null || _controller.heading == null)) {
      return _buildBanner(message: customStatus, aligned: false);
    }

    if (_controller.heading == null || _controller.qiblaBearing == null) {
      if (_controller.locationServiceDisabled) {
        return _buildBanner(
          message: customStatus ??
              'Aktifkan layanan lokasi untuk menentukan arah kiblat.',
          aligned: false,
          actionLabel: 'Aktifkan Lokasi',
          onActionPressed: _controller.openLocationSettingsAndRefresh,
        );
      }

      if (_controller.locationPermissionDeniedForever) {
        return _buildBanner(
          message:
              'Izin lokasi diblokir permanen. Buka pengaturan aplikasi untuk mengizinkan lokasi.',
          aligned: false,
          actionLabel: 'Buka Pengaturan',
          onActionPressed: _controller.openAppSettingsAndRefresh,
        );
      }

      return _buildBanner(
        message: 'Gerakkan ponsel untuk kalibrasi kompas.',
        aligned: false,
      );
    }

    if (_controller.isAligned) {
      return _buildBanner(
        message: 'Arah kiblat Anda sudah tepat. Silakan sholat menghadap arah ini.',
        aligned: true,
      );
    }

    final diff = _controller.angleDiff(
      _controller.heading!,
      _controller.qiblaBearing!,
    );
    final side = diff > 0 ? 'kanan' : 'kiri';

    return _buildBanner(
      message:
          'Putar sekitar ${diff.abs().toStringAsFixed(1)}° ke $side agar menghadap kiblat.',
      aligned: false,
    );
  }

  Widget _buildBanner({
    required String message,
    required bool aligned,
    String? actionLabel,
    Future<void> Function()? onActionPressed,
  }) {
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
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: () async {
                await onActionPressed();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
