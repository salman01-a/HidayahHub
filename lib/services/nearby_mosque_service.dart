import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_env.dart';
import '../models/nearby_mosque.dart';
import '../models/nearby_route.dart';

class NearbyMosqueService {
  NearbyMosqueService._();
  static final NearbyMosqueService instance = NearbyMosqueService._();
  static const List<String> _fallbackOverpassUrls = <String>[
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  final Map<String, String> _reverseCache = <String, String>{};

  Future<List<NearbyMosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    int limit = 20,
  }) async {
    final query =
        '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

    final response = await _fetchOverpass(query);
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data masjid (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response lokasi masjid tidak valid');
    }

    final rawElements = decoded['elements'];
    if (rawElements is! List) {
      return const <NearbyMosque>[];
    }

    final mosques = <NearbyMosque>[];
    final seenIds = <String>{};

    for (final raw in rawElements) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        final item = NearbyMosque.fromOverpassElement(
          raw,
          userLatitude: latitude,
          userLongitude: longitude,
        );
        if (seenIds.add(item.id)) {
          mosques.add(item);
        }
      } catch (_) {
        continue;
      }
    }

    mosques.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    final trimmed = mosques.length <= limit
        ? mosques
        : mosques.take(limit).toList(growable: false);

    return _enrichAddressWithReverseGeocoding(trimmed);
  }

  Future<http.Response> _fetchOverpass(String query) async {
    final endpoints = <String>{
      AppEnv.overpassUrl,
      ..._fallbackOverpassUrls,
    };

    http.Response? lastResponse;

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'User-Agent': 'HidayahHub/1.0',
                'Accept': 'application/json, text/plain;q=0.9, */*;q=0.8',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          return response;
        }

        lastResponse = response;
      } catch (_) {
        continue;
      }
    }

    if (lastResponse != null) {
      return lastResponse;
    }

    throw Exception('Gagal terhubung ke layanan data masjid');
  }

  Future<List<NearbyMosque>> _enrichAddressWithReverseGeocoding(
    List<NearbyMosque> mosques,
  ) async {
    final enriched = <NearbyMosque>[];

    for (final mosque in mosques) {
      if (mosque.hasResolvedAddress) {
        enriched.add(mosque);
        continue;
      }

      final resolved = await _reverseGeocode(
        latitude: mosque.latitude,
        longitude: mosque.longitude,
      );

      if (resolved == null || resolved.trim().isEmpty) {
        enriched.add(mosque);
        continue;
      }

      enriched.add(mosque.copyWith(address: resolved));
    }

    return enriched;
  }

  Future<NearbyRoute> getRoadRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      '${AppEnv.osrmRouteBaseUrl}/'
      '${start.longitude},${start.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Routing gagal dimuat (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('Rute tidak ditemukan');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      throw Exception('Geometri rute kosong');
    }

    final routePoints = coordinates
        .map((coord) {
          final pair = coord as List<dynamic>;
          return LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
        })
        .toList(growable: false);

    final distanceKm = ((route['distance'] as num?)?.toDouble() ?? 0) / 1000;
    final durationMin = (((route['duration'] as num?)?.toDouble() ?? 0) / 60)
        .round();

    return NearbyRoute(
      points: routePoints,
      distanceKm: distanceKm,
      durationMin: durationMin,
    );
  }

  Future<String?> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    final cached = _reverseCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.parse(AppEnv.nominatimReverseUrl).replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'id',
      },
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'HidayahHub/1.0', 
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final displayName = (decoded['display_name'] as String?)?.trim();
      if (displayName == null || displayName.isEmpty) {
        return null;
      }

      _reverseCache[cacheKey] = displayName;
      return displayName;
    } catch (_) {
      return null;
    }
  }
}
