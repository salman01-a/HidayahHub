import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/app_env.dart';
import '../models/nearby_mosque.dart';
import '../models/nearby_route.dart';

class NearbyMosqueService {
  NearbyMosqueService._();
  static final NearbyMosqueService instance = NearbyMosqueService._();

  Future<List<NearbyMosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    int limit = 20,
  }) async {
    // Overpass QL: cari amenity=place_of_worship dengan religion=muslim
    // dalam radius tertentu dari koordinat pengguna.
    // "out center" agar way/relation juga punya titik tengah.
    final query = '''
[out:json][timeout:15];
(
  node["amenity"="place_of_worship"]["religion"="muslim"]
    (around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"]
    (around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"="muslim"]
    (around:$radiusMeters,$latitude,$longitude);
);
out center body;
''';

    final uri = Uri.parse(AppEnv.overpassUrl);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
            'User-Agent': 'HidayahHub/1.0',
          },
          body: 'data=${Uri.encodeComponent(query)}',
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghubungi Overpass API (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? [];

    final mosques = <NearbyMosque>[];
    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        final item = NearbyMosque.fromOverpass(
          raw,
          userLatitude: latitude,
          userLongitude: longitude,
        );
        mosques.add(item);
      } catch (_) {
        continue;
      }
    }

    await _resolveAddresses(mosques, max: 5);

    mosques.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return mosques.length <= limit
        ? mosques
        : mosques.take(limit).toList(growable: false);
  }

  /// Reverse-geocode alamat menggunakan Nominatim (gratis, courtesy limit)
  Future<void> _resolveAddresses(List<NearbyMosque> mosques, {int max = 5}) async {
    int resolved = 0;
    for (int i = 0; i < mosques.length && resolved < max; i++) {
      if (mosques[i].hasResolvedAddress) continue;

      try {
        final uri = Uri.parse(
          '${AppEnv.nominatimReverseUrl}'
          '?lat=${mosques[i].latitude}'
          '&lon=${mosques[i].longitude}'
          '&format=json'
          '&zoom=18'
          '&addressdetails=1',
        );

        final resp = await http.get(
          uri,
          headers: {'User-Agent': 'HidayahHub/1.0'},
        ).timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.trim().isNotEmpty) {
            mosques[i] = mosques[i].copyWith(address: displayName);
            resolved++;
          }
        }
      } catch (_) {
        // Skip — alamat tetap dari tags OSM
      }
    }
  }

  /// Mengambil rute jalan kaki menggunakan OSRM 
  Future<NearbyRoute> getRoadRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final baseUrl = AppEnv.osrmRouteBaseUrl.replaceFirst('/driving', '/foot');

    final uri = Uri.parse(
      '$baseUrl/'
      '${start.longitude},${start.latitude}'
      ';${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=polyline&steps=false',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghubungi server rute (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'] as String?;

    if (code != 'Ok') {
      throw Exception('Rute tidak ditemukan (Status: $code)');
    }

    final route =
        (data['routes'] as List<dynamic>).first as Map<String, dynamic>;

    final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;
    final encodedGeometry = route['geometry'] as String;

    final routePoints = _decodePolyline(encodedGeometry);

    return NearbyRoute(
      points: routePoints,
      distanceKm: distanceMeters / 1000,
      durationMin: (durationSeconds / 60).round(),
    );
  }

  /// Helper untuk memecah Encoded Polyline menjadi daftar koordinat
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
