import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/nearby_mosque_controller.dart';
import '../../models/nearby_mosque.dart';

class NearbyMosqueView extends StatefulWidget {
  const NearbyMosqueView({super.key});

  @override
  State<NearbyMosqueView> createState() => _NearbyMosqueViewState();
}

class _NearbyMosqueViewState extends State<NearbyMosqueView> {
  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _deepTeal = Color(0xFF0F5A4E);
  static const Color _bg = Color(0xFFF6F9FA);
  static const LatLng _fallbackCenter = LatLng(-7.7956, 110.3695);

  late final NearbyMosqueController _controller;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _controller = NearbyMosqueController();
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

    final lat = _controller.userLatitude;
    final lon = _controller.userLongitude;
    if (!_controller.navigationActive && lat != null && lon != null) {
      _mapController.move(LatLng(lat, lon), _preferredZoom());
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _controller.mosques.isNotEmpty;
    final center = _currentCenter();
    final mapMarkers = _buildMapMarkers();
    final hasActiveNavigation = _controller.navigationActive;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _buildHeaderCard(),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _preferredZoom(),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.hidayahhub.app',
                      ),
                      if (_controller.activeRoute.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _controller.activeRoute,
                              strokeWidth: 5,
                              color: const Color(0xFF1F8D7A),
                            ),
                          ],
                        ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: center,
                            radius: _controller.radiusMeters.toDouble(),
                            useRadiusInMeter: true,
                            color: _primaryTeal.withValues(alpha: 0.14),
                            borderStrokeWidth: 2,
                            borderColor: _primaryTeal.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                      MarkerLayer(markers: mapMarkers),
                    ],
                  ),
                ),
                if (_controller.loading)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Memuat lokasi...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasActiveNavigation)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: _buildNavigationPanel(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_controller.error != null && !hasData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ErrorBox(
                message: _controller.error!,
                onRetry: _controller.fetchNearbyMosques,
              ),
            )
          else if (!hasData)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _EmptyBox(
                message:
                    _controller.infoMessage ?? 'Data masjid belum tersedia.',
              ),
            )
          else
            SizedBox(
              height: 146,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: _controller.mosques.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final mosque = _controller.mosques[index];
                  return SizedBox(width: 280, child: _buildMosqueCard(mosque));
                },
              ),
            ),
        ],
      ),
    );
  }

  LatLng _currentCenter() {
    final lat = _controller.userLatitude;
    final lon = _controller.userLongitude;
    if (lat == null || lon == null) return _fallbackCenter;
    return LatLng(lat, lon);
  }

  double _preferredZoom() {
    switch (_controller.radiusMeters) {
      case 1000:
        return 14.2;
      case 2000: // tambahan untuk radius 2 km
        return 13.6;
      case 3000:
        return 13.0;
      case 5000:
        return 12.3;
      default:
        return 13.0;
    }
  }

  List<Marker> _buildMapMarkers() {
    final markers = <Marker>[];

    final userLat = _controller.userLatitude;
    final userLon = _controller.userLongitude;
    if (userLat != null && userLon != null) {
      markers.add(
        Marker(
          point: LatLng(userLat, userLon),
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final mosque in _controller.mosques) {
      final isSelected = _controller.activeDestination?.id == mosque.id;

      markers.add(
        Marker(
          point: LatLng(mosque.latitude, mosque.longitude),
          width: 52,
          height: 52,
          child: GestureDetector(
            onTap: () => _startInAppNavigation(mosque),
            child: Icon(
              Icons.location_on_rounded,
              size: 46,
              color: isSelected
                  ? const Color(0xFFE46735)
                  : const Color(0xFF0F5A4E),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _startInAppNavigation(NearbyMosque mosque) async {
    final userLat = _controller.userLatitude;
    final userLon = _controller.userLongitude;
    if (userLat == null || userLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi Anda belum tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Initial focus stays on current user location when navigation starts.
    _mapController.move(LatLng(userLat, userLon), 16.5);
    await _controller.startNavigation(mosque);

    if (!mounted) return;
    if (_controller.activeRoute.length > 1) {
      final bounds = LatLngBounds.fromPoints(_controller.activeRoute);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(36, 36, 36, 170),
        ),
      );
    }
  }

  void _stopInAppNavigation() {
    _controller.stopNavigation();
  }

  Widget _buildNavigationPanel() {
    final destination = _controller.activeDestination;
    final userLat = _controller.userLatitude;
    final userLon = _controller.userLongitude;
    if (destination == null || userLat == null || userLon == null) {
      return const SizedBox.shrink();
    }

    final distance = _controller.activeRouteDistanceKm;
    final duration = _controller.activeRouteDurationMin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Navigasi aktif: ${destination.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _controller.routeLoading
                      ? 'Memuat rute jalan...'
                      : (distance == null
                            ? 'Jarak belum tersedia'
                            : 'Rute ${distance.toStringAsFixed(2)} km'
                                  '${duration == null ? '' : ' · $duration menit'}'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                _mapController.move(LatLng(userLat, userLon), 16.5),
            icon: const Icon(Icons.my_location_rounded, color: Colors.white),
            tooltip: 'Fokus ke saya',
          ),
          TextButton(
            onPressed: _stopInAppNavigation,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final lat = _controller.userLatitude;
    final lon = _controller.userLongitude;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F5A4E), Color(0xFF1A7F6D), Color(0xFF35A598)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cari Masjid Terdekat (LBS)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Peta langsung tampil dan hasil otomatis disaring sesuai radius yang dipilih.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              _radiusChip(1000),
              _radiusChip(2000), // ubah dari 3000 menjadi 2000
              _radiusChip(3000), // ubah dari 5000 menjadi 3000
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _controller.loading
                  ? null
                  : _controller.fetchNearbyMosques,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _deepTeal,
              ),
              icon: _controller.loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: const Text(
                'Refresh Lokasi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lat == null || lon == null
                ? 'Koordinat saat ini: belum tersedia'
                : 'Koordinat: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          if (_controller.error != null && _controller.mosques.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _controller.error!,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _radiusChip(int radius) {
    final selected = _controller.radiusMeters == radius;
    return ChoiceChip(
      selected: selected,
      label: Text(radius >= 1000 ? '${radius ~/ 1000} km' : '$radius m'),
      onSelected: (_) => _controller.setRadiusAndReload(radius),
      backgroundColor: Colors.white.withValues(alpha: 0.5),
      selectedColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? _deepTeal : Colors.black,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
    );
  }

  Widget _buildMosqueCard(NearbyMosque mosque) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startInAppNavigation(mosque),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE7EA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: _primaryTeal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mosque.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF21324A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F6F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mosque.distanceLabel,
                      style: const TextStyle(
                        color: _deepTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  mosque.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5E6D7E),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.navigation_rounded, size: 16, color: _primaryTeal),
                  SizedBox(width: 4),
                  Text(
                    'Ketuk untuk navigasi',
                    style: TextStyle(
                      color: _primaryTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D7D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tidak bisa memuat data masjid',
            style: TextStyle(
              color: Color(0xFFB3261E),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF5E6D7E),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
