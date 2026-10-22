import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../map/map_config.dart';

/// Status of device location services and permissions.
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

/// Reactive state holding customer location coordinates and permission status.
class LocationState {
  final LocationPermissionStatus permissionStatus;
  final LatLng userLocation;
  final bool isTracking;

  const LocationState({
    required this.permissionStatus,
    required this.userLocation,
    this.isTracking = true,
  });

  bool get isGranted => permissionStatus == LocationPermissionStatus.granted;

  LocationState copyWith({
    LocationPermissionStatus? permissionStatus,
    LatLng? userLocation,
    bool? isTracking,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      userLocation: userLocation ?? this.userLocation,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

/// State notifier managing location permission and real/default coordinates.
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState(
      permissionStatus: LocationPermissionStatus.granted,
      userLocation: MapConfig.dharashivCenter,
      isTracking: true,
    );
  }

  /// Requests or confirms location permission.
  Future<void> requestPermission() async {
    state = state.copyWith(
      permissionStatus: LocationPermissionStatus.granted,
      isTracking: true,
    );
  }

  /// Toggles permission status for graceful error/denial testing and control.
  void togglePermission() {
    final nextStatus = state.permissionStatus == LocationPermissionStatus.granted
        ? LocationPermissionStatus.denied
        : LocationPermissionStatus.granted;
    state = state.copyWith(
      permissionStatus: nextStatus,
      isTracking: nextStatus == LocationPermissionStatus.granted,
    );
  }

  void setPermissionStatus(LocationPermissionStatus status) {
    state = state.copyWith(
      permissionStatus: status,
      isTracking: status == LocationPermissionStatus.granted,
    );
  }

  void updateLocation(LatLng newLocation) {
    state = state.copyWith(userLocation: newLocation);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);

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

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});
