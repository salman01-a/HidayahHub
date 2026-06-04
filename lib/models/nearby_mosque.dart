import 'package:geolocator/geolocator.dart';

class NearbyMosque {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceMeters;

  const NearbyMosque({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  static const String unknownAddress = 'Alamat belum tersedia';

  /// Parse data dari Overpass API (OpenStreetMap).
  factory NearbyMosque.fromOverpass(
    Map<String, dynamic> element, {
    required double userLatitude,
    required double userLongitude,
    String? resolvedAddress,
  }) {
    final double? lat;
    final double? lon;

    if (element.containsKey('lat') && element.containsKey('lon')) {
      lat = (element['lat'] as num?)?.toDouble();
      lon = (element['lon'] as num?)?.toDouble();
    } else if (element['center'] is Map<String, dynamic>) {
      final center = element['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num?)?.toDouble();
      lon = (center['lon'] as num?)?.toDouble();
    } else {
      lat = null;
      lon = null;
    }

    if (lat == null || lon == null) {
      throw const FormatException('Lokasi masjid tidak valid dari Overpass');
    }

    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final name = (tags['name'] as String?)?.trim().isNotEmpty == true
        ? tags['name'] as String
        : 'Masjid Tanpa Nama';

    // Compose address from OSM tags if Nominatim address not provided
    final address = resolvedAddress ??
        _composeAddressFromTags(tags);

    final osmId = element['id']?.toString() ?? '';

    final distance = Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      lat,
      lon,
    );

    return NearbyMosque(
      id: osmId,
      name: name,
      address: address,
      latitude: lat,
      longitude: lon,
      distanceMeters: distance,
    );
  }

  /// Build a human-readable address from OSM tags.
  static String _composeAddressFromTags(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street'] as String?;
    final houseNumber = tags['addr:housenumber'] as String?;
    final village = tags['addr:village'] as String?;
    final city = tags['addr:city'] as String?;

    if (street != null && street.trim().isNotEmpty) {
      final streetPart = houseNumber != null && houseNumber.trim().isNotEmpty
          ? '$street $houseNumber'
          : street;
      parts.add(streetPart);
    }
    if (village != null && village.trim().isNotEmpty) parts.add(village);
    if (city != null && city.trim().isNotEmpty) parts.add(city);

    return parts.isNotEmpty ? parts.join(', ') : unknownAddress;
  }

  bool get hasResolvedAddress =>
      address.trim().isNotEmpty && address != unknownAddress;

  NearbyMosque copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceMeters,
  }) {
    return NearbyMosque(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${distanceMeters.toStringAsFixed(0)} m';
  }
}
