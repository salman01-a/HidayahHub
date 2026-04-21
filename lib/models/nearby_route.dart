import 'package:latlong2/latlong.dart';

class NearbyRoute {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;

  const NearbyRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });
}
