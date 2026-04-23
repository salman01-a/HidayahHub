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

  factory NearbyMosque.fromGooglePlaces(
    Map<String, dynamic> data, {
    required double userLatitude,
    required double userLongitude,
  }) {
    final lat = data['geometry']?['location']?['lat'] as double?;
    final lon = data['geometry']?['location']?['lng'] as double?;

    if (lat == null || lon == null) {
      throw const FormatException('Lokasi masjid tidak valid dari Google Maps');
    }

    final name = data['name'] as String? ?? 'Masjid Tanpa Nama';
    final address = data['vicinity'] as String? ?? unknownAddress;
    final placeId = data['place_id'] as String? ?? '';

    final distance = Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      lat,
      lon,
    );

    return NearbyMosque(
      id: placeId,
      name: name,
      address: address,
      latitude: lat,
      longitude: lon,
      distanceMeters: distance,
    );
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
