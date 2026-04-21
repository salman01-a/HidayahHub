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

  factory NearbyMosque.fromOverpassElement(
    Map<String, dynamic> element, {
    required double userLatitude,
    required double userLongitude,
  }) {
    final tags = element['tags'];
    final type = element['type'] as String? ?? 'node';
    final osmId = (element['id'] as num?)?.toString() ?? '';

    final lat = (element['lat'] as num?)?.toDouble() ??
        (element['center']?['lat'] as num?)?.toDouble();
    final lon = (element['lon'] as num?)?.toDouble() ??
        (element['center']?['lon'] as num?)?.toDouble();

    if (lat == null || lon == null) {
      throw const FormatException('Lokasi masjid tidak valid');
    }

    final tagMap = tags is Map<String, dynamic>
        ? tags
        : const <String, dynamic>{};

    final distance = Geolocator.distanceBetween(userLatitude, userLongitude, lat, lon);

    return NearbyMosque(
      id: '$type-$osmId',
      name: (tagMap['name'] as String?)?.trim().isNotEmpty == true
          ? (tagMap['name'] as String).trim()
          : 'Masjid Tanpa Nama',
      address: _composeAddress(tagMap),
      latitude: lat,
      longitude: lon,
      distanceMeters: distance,
    );
  }

  bool get hasResolvedAddress => address.trim().isNotEmpty && address != unknownAddress;

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

  static String _composeAddress(Map<String, dynamic> tags) {
    final street = (tags['addr:street'] as String?)?.trim() ?? '';
    final suburb = (tags['addr:suburb'] as String?)?.trim() ?? '';
    final village = (tags['addr:village'] as String?)?.trim() ?? '';
    final city = (tags['addr:city'] as String?)?.trim() ??
        (tags['addr:town'] as String?)?.trim() ??
        (tags['addr:county'] as String?)?.trim() ?? '';

    final segments = <String>[street, suburb, village, city]
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (segments.isEmpty) {
      return unknownAddress;
    }

    return segments.join(', ');
  }
}
