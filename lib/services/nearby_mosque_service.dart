import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/app_env.dart';
import '../models/nearby_mosque.dart';
import '../models/nearby_route.dart';

class NearbyMosqueService {
  NearbyMosqueService._();
  static final NearbyMosqueService instance = NearbyMosqueService._();

  /// Mencari masjid menggunakan Google Places API
  Future<List<NearbyMosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    int limit = 20,
  }) async {
    final apiKey = AppEnv.googleMapsApiKey; 
    
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$latitude,$longitude'
      '&radius=$radiusMeters'
      '&type=mosque'
      '&key=$apiKey'
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghubungi Google Maps API (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final status = decoded['status'] as String?;

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Error dari Google Maps: $status');
    }

    final results = decoded['results'] as List<dynamic>? ?? [];
    final mosques = <NearbyMosque>[];

    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        final item = NearbyMosque.fromGooglePlaces(
          raw,
          userLatitude: latitude,
          userLongitude: longitude,
        );
        mosques.add(item);
      } catch (_) {
        continue;
      }
    }

    mosques.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return mosques.length <= limit
        ? mosques
        : mosques.take(limit).toList(growable: false);
  }

  /// Mengambil rute jalan kaki menggunakan Google Directions API
  Future<NearbyRoute> getRoadRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final apiKey = AppEnv.googleMapsApiKey;
    
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${start.latitude},${start.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=walking' 
      '&key=$apiKey'
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghubungi server rute (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status != 'OK') {
      throw Exception('Rute tidak ditemukan (Status: $status)');
    }

    final route = (data['routes'] as List<dynamic>).first as Map<String, dynamic>;
    final leg = (route['legs'] as List<dynamic>).first as Map<String, dynamic>;
    
    final distanceMeters = (leg['distance']['value'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (leg['duration']['value'] as num?)?.toDouble() ?? 0;
    final encodedPolyline = route['overview_polyline']['points'] as String;
    
    final routePoints = _decodePolyline(encodedPolyline);

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