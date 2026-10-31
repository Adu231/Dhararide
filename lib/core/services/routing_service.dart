import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum RoutingStatus {
  success,
  networkError,
  timeout,
  noRouteFound,
  rateLimited,
}

/// Representation of a calculated or estimated route between two points.
class RouteEstimateResult {
  /// Driving distance in kilometers.
  final double distanceKm;

  /// Estimated duration in minutes based on real route or city speed limits.
  final int estimatedDurationMinutes;

  /// List of geographic coordinates forming the polyline connecting the points.
  final List<LatLng> polylinePoints;

  /// Indicates if this is a genuine road-route geometry from a routing server.
  final bool isRealRoadRoute;

  /// Indicates if this was computed as an offline fallback.
  final bool isGeodesicEstimate;

  /// Status of the routing operation.
  final RoutingStatus status;

  /// User-friendly message explaining any issues encountered during routing.
  final String? errorMessage;

  const RouteEstimateResult({
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.polylinePoints,
    this.isRealRoadRoute = true,
    this.isGeodesicEstimate = false,
    this.status = RoutingStatus.success,
    this.errorMessage,
  });

  bool get isSuccess => status == RoutingStatus.success;
}

/// Modular service interface for real road-route calculation and travel time estimation.
///
/// Production Architecture & Policy Note:
/// - OpenStreetMap map tiles ONLY provide raster/vector images; they do NOT calculate routes.
/// - This service queries the public OSRM driving engine (router.project-osrm.org) for development
///   and testing with driving profile, geojson geometry, and distance in meters.
/// - In a production deployment, replace the baseUrl with a self-hosted OSRM, Valhalla,
///   or GraphHopper instance running within Maharashtra/India infrastructure to satisfy
///   commercial SLA and latency requirements.
class RoutingService {
  /// OSRM base URL endpoint. Configurable for self-hosted instances.
  final String osrmBaseUrl;

  /// HTTP client interface for dependency injection & mock testing.
  final http.Client? client;

  /// Average auto-rickshaw speed in urban Dharashiv traffic (~25 km/h) used for offline estimates.
  static const double averageRickshawSpeedKmh = 25.0;

  /// Urban road network tortuosity factor (~1.25x of straight-line distance).
  static const double urbanTortuosityFactor = 1.25;

  const RoutingService({
    this.osrmBaseUrl = 'https://router.project-osrm.org',
    this.client,
  });

  http.Client get _httpClient => client ?? http.Client();

  /// Calculates the actual road route, distance in meters, duration, and road geometry
  /// between [pickup] and [destination] coordinates using OSRM driving profile.
  Future<RouteEstimateResult> calculateRoadRoute(LatLng pickup, LatLng destination) async {
    // Edge case: pickup and destination are identical
    if (pickup.latitude == destination.latitude && pickup.longitude == destination.longitude) {
      return RouteEstimateResult(
        distanceKm: 0.0,
        estimatedDurationMinutes: 1,
        polylinePoints: [pickup],
        isRealRoadRoute: true,
        status: RoutingStatus.success,
      );
    }

    final url = Uri.parse(
      '$osrmBaseUrl/route/v1/driving/'
      '${pickup.longitude},${pickup.latitude};${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await _httpClient.get(
        url,
        headers: {
          'User-Agent': 'DharRide-Flutter-App/1.0 (contact: support@dharride.demo)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['code'] as String?;

        if (code == 'Ok') {
          final routes = data['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            final distanceMeters = (route['distance'] as num).toDouble();
            final durationSeconds = (route['duration'] as num).toDouble();
            final geometry = route['geometry'] as Map<String, dynamic>?;

            final distanceKm = double.parse((distanceMeters / 1000.0).toStringAsFixed(2));
            final durationMinutes = ((durationSeconds / 60.0).ceil()).clamp(1, 180);

            final polylinePoints = <LatLng>[];
            if (geometry != null && geometry['coordinates'] != null) {
              final coordinates = geometry['coordinates'] as List<dynamic>;
              for (final coord in coordinates) {
                if (coord is List && coord.length >= 2) {
                  final lon = (coord[0] as num).toDouble();
                  final lat = (coord[1] as num).toDouble();
                  polylinePoints.add(LatLng(lat, lon));
                }
              }
            }

            // Fallback to end-points if polyline was empty
            if (polylinePoints.isEmpty) {
              polylinePoints.addAll([pickup, destination]);
            }

            return RouteEstimateResult(
              distanceKm: distanceKm,
              estimatedDurationMinutes: durationMinutes,
              polylinePoints: polylinePoints,
              isRealRoadRoute: true,
              isGeodesicEstimate: false,
              status: RoutingStatus.success,
            );
          }
        }

        return _createOfflineFallback(
          pickup,
          destination,
          status: RoutingStatus.noRouteFound,
          message: 'No road route found between selected points. Showing estimated distance.',
        );
      } else if (response.statusCode == 429) {
        return _createOfflineFallback(
          pickup,
          destination,
          status: RoutingStatus.rateLimited,
          message: 'Routing service rate limit reached. Showing offline estimate.',
        );
      } else {
        return _createOfflineFallback(
          pickup,
          destination,
          status: RoutingStatus.networkError,
          message: 'Routing server responded with status ${response.statusCode}.',
        );
      }
    } on TimeoutException {
      return _createOfflineFallback(
        pickup,
        destination,
        status: RoutingStatus.timeout,
        message: 'Routing service timed out. Using estimated road distance.',
      );
    } catch (e) {
      return _createOfflineFallback(
        pickup,
        destination,
        status: RoutingStatus.networkError,
        message: 'Network error connecting to routing service: $e',
      );
    }
  }

  /// Synchronous fallback calculation preserving backward compatibility for immediate render.
  RouteEstimateResult calculateEstimate(LatLng pickup, LatLng destination) {
    return _createOfflineFallback(pickup, destination);
  }

  /// Creates a realistic offline estimate using geodesics and urban tortuosity.
  RouteEstimateResult _createOfflineFallback(
    LatLng pickup,
    LatLng destination, {
    RoutingStatus status = RoutingStatus.success,
    String? message,
  }) {
    const distanceCalc = Distance();
    final straightLineKm = distanceCalc.as(LengthUnit.Kilometer, pickup, destination);

    final drivingDistanceKm = double.parse((straightLineKm * urbanTortuosityFactor).toStringAsFixed(2));
    final durationMinutes = ((drivingDistanceKm / averageRickshawSpeedKmh) * 60).ceil();
    final safeDurationMinutes = durationMinutes < 2 ? 2 : durationMinutes;

    return RouteEstimateResult(
      distanceKm: drivingDistanceKm,
      estimatedDurationMinutes: safeDurationMinutes,
      polylinePoints: [pickup, destination],
      isRealRoadRoute: false,
      isGeodesicEstimate: true,
      status: status,
      errorMessage: message,
    );
  }
}
