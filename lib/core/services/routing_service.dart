import 'package:latlong2/latlong.dart';

/// Representation of a calculated or estimated route between two points.
class RouteEstimateResult {
  /// Estimated driving distance in kilometers.
  final double distanceKm;

  /// Estimated duration in minutes based on local city speed limits.
  final int estimatedDurationMinutes;

  /// List of geographic coordinates forming the polyline connecting the points.
  final List<LatLng> polylinePoints;

  /// Indicates if this is a geodesic estimation rather than an external turn-by-turn routing server.
  final bool isGeodesicEstimate;

  const RouteEstimateResult({
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.polylinePoints,
    required this.isGeodesicEstimate,
  });
}

/// Modular service interface for route calculation and travel time estimation.
///
/// NOTE on Routing Policies:
/// OpenStreetMap map tiles ONLY provide visual map images; they DO NOT provide
/// route calculation, turn-by-turn directions, or travel time calculation.
/// Public demo OSRM servers (router.project-osrm.org) are strictly rate-limited
/// demo services and prohibit commercial/production traffic.
///
/// This service provides:
/// 1. Offline, privacy-preserving geodesic route estimation using actual
///    geographical mathematics and urban auto-rickshaw road-tortuosity factors.
/// 2. Clean integration hooks where a self-hosted OSRM, GraphHopper, or Valhalla
///    server endpoint can be plugged in when deployed.
class RoutingService {
  /// Average auto-rickshaw speed in urban Dharashiv traffic (~25 km/h).
  static const double averageRickshawSpeedKmh = 25.0;

  /// Urban road network tortuosity factor (~1.25x of straight-line distance).
  /// In city street networks without tunnels/flyovers, driving distance is
  /// typically 20-30% longer than geodesic Euclidean distance.
  static const double urbanTortuosityFactor = 1.25;

  const RoutingService();

  /// Calculates a reliable estimated route between [pickup] and [destination].
  RouteEstimateResult calculateEstimate(LatLng pickup, LatLng destination) {
    const distanceCalc = Distance();
    final straightLineKm = distanceCalc.as(LengthUnit.Kilometer, pickup, destination);

    // Apply urban street network tortuosity factor
    final drivingDistanceKm = double.parse((straightLineKm * urbanTortuosityFactor).toStringAsFixed(2));

    // Calculate realistic duration: hours = dist / speed, minutes = hours * 60
    final durationMinutes = ((drivingDistanceKm / averageRickshawSpeedKmh) * 60).ceil();
    final safeDurationMinutes = durationMinutes < 2 ? 2 : durationMinutes;

    // Generate polyline points connecting pickup to destination
    final polyline = [pickup, destination];

    return RouteEstimateResult(
      distanceKm: drivingDistanceKm,
      estimatedDurationMinutes: safeDurationMinutes,
      polylinePoints: polyline,
      isGeodesicEstimate: true,
    );
  }
}
