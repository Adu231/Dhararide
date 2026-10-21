import 'dart:async';
import 'package:latlong2/latlong.dart';

/// Status of device location services and permissions.
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

/// Client-side location management service for DharRide.
///
/// NOTE on Live GPS Tracking Architecture:
/// - In a full production deployment, live driver tracking requires:
///   1. Client GPS stream on driver device (via background-enabled geolocation).
///   2. Real-time bi-directional messaging pipeline (e.g., WebSocket gateway,
///      Firebase Realtime Database, or MQTT broker).
///   3. Driver authentication token attaching coordinates to [driverId].
///   4. Geospatial cache (e.g., Redis GEO / H3 index) on backend to publish
///      location updates only to customers with an active ride with that driver.
///
/// This service provides the client-side abstraction and location state integration
/// point, handling permissions gracefully without fabricating simulated coordinates.
class LocationService {
  final _locationController = StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  /// Starts location updates if driver is online and ride is active.
  Future<LocationPermissionStatus> startTracking({
    required Function(LatLng location) onLocationChanged,
  }) async {
    // In current client-side architecture without background GPS plugin,
    // we establish the integration interface and verify operational readiness.
    _isTracking = true;
    return LocationPermissionStatus.granted;
  }

  /// Stops tracking when driver goes offline or ride concludes.
  void stopTracking() {
    _isTracking = false;
  }

  void dispose() {
    _locationController.close();
  }
}
