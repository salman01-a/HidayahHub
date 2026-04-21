import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  late final NearbyMosqueController _controller;

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _controller.mosques.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _primaryTeal,
        onRefresh: _controller.fetchNearbyMosques,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 14),
            if (_controller.loading && !hasData)
              const _LoadingBox()
            else if (_controller.error != null && !hasData)
              _ErrorBox(
                message: _controller.error!,
                onRetry: _controller.fetchNearbyMosques,
              )
            else if (!hasData)
              _EmptyBox(
                message:
                    _controller.infoMessage ?? 'Data masjid belum tersedia.',
              )
            else
              ..._controller.mosques.map(_buildMosqueCard),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.loading ? null : _controller.fetchNearbyMosques,
        backgroundColor: _deepTeal,
        foregroundColor: Colors.white,
        icon: _controller.loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location_rounded),
        label: const Text('Refresh Lokasi'),
      ),
    );
  }

  Future<void> _openNavigation(NearbyMosque mosque) async {
    final lat = mosque.latitude;
    final lon = mosque.longitude;

    final googleNavigationUri = Uri.parse('google.navigation:q=$lat,$lon');
    final googleMapsDirectionUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );

    var launched = false;
    if (await canLaunchUrl(googleNavigationUri)) {
      launched = await launchUrl(
        googleNavigationUri,
        mode: LaunchMode.externalApplication,
      );
    }

    if (!launched) {
      launched = await launchUrl(
        googleMapsDirectionUri,
        mode: LaunchMode.externalApplication,
      );
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka aplikasi peta.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildHeaderCard() {
    final lat = _controller.userLatitude;
    final lon = _controller.userLongitude;

    return Container(
      padding: const EdgeInsets.all(18),
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
            'Gunakan lokasi real-time untuk menemukan masjid terdekat di sekitar Anda.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [_radiusChip(1000), _radiusChip(3000), _radiusChip(5000)],
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
        onTap: () => _openNavigation(mosque),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: _primaryTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mosque.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF21324A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mosque.address,
                          style: const TextStyle(
                            color: Color(0xFF5E6D7E),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lat ${mosque.latitude.toStringAsFixed(6)} | Lon ${mosque.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Color(0xFF7A8896),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.navigation_rounded,
                    size: 17,
                    color: _primaryTeal,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Arah',
                    style: TextStyle(
                      color: _primaryTeal,
                      fontWeight: FontWeight.w800,
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

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mencari masjid di sekitar lokasi Anda...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
