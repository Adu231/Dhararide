import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../map/map_config.dart';

/// Status of device location services and runtime permissions.
enum LocationPermissionStatus {
  initial,
  loading,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  error,
}

/// Reactive state holding the customer's device GPS coordinates, address, and permission status.
class LocationState {
  final LocationPermissionStatus permissionStatus;
  final LatLng userLocation;
  final String? readableAddress;
  final String? errorMessage;
  final bool hasRealGps;

  const LocationState({
    required this.permissionStatus,
    required this.userLocation,
    this.readableAddress,
    this.errorMessage,
    this.hasRealGps = false,
  });

  bool get isGranted => permissionStatus == LocationPermissionStatus.granted && hasRealGps;
  bool get isLoading => permissionStatus == LocationPermissionStatus.loading;

  LocationState copyWith({
    LocationPermissionStatus? permissionStatus,
    LatLng? userLocation,
    String? readableAddress,
    String? errorMessage,
    bool? hasRealGps,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      userLocation: userLocation ?? this.userLocation,
      readableAddress: readableAddress ?? this.readableAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      hasRealGps: hasRealGps ?? this.hasRealGps,
    );
  }
}

/// State notifier managing real device GPS acquisition, runtime permissions, and reverse geocoding.
class LocationNotifier extends Notifier<LocationState> {
  final http.Client _httpClient = http.Client();

  @override
  LocationState build() {
    return const LocationState(
      permissionStatus: LocationPermissionStatus.initial,
      userLocation: MapConfig.dharashivCenter,
      readableAddress: 'Dharashiv Center',
      hasRealGps: false,
    );
  }

  /// Requests runtime Android permissions and acquires real device latitude & longitude.
  ///
  /// Returns `true` if genuine device coordinates were obtained, `false` otherwise.
  Future<bool> requestAndFetchCurrentLocation() async {
    state = state.copyWith(
      permissionStatus: LocationPermissionStatus.loading,
      errorMessage: null,
    );

    try {
      // 1. Check if device location services (GPS hardware) are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        state = state.copyWith(
          permissionStatus: LocationPermissionStatus.serviceDisabled,
          hasRealGps: false,
          errorMessage: 'Device location services are turned off. Please turn on GPS.',
        );
        return false;
      }

      // 2. Check and request runtime permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            permissionStatus: LocationPermissionStatus.denied,
            hasRealGps: false,
            errorMessage: 'Location permission was denied. Please grant permission to detect current pickup.',
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          permissionStatus: LocationPermissionStatus.permanentlyDenied,
          hasRealGps: false,
          errorMessage: 'Location permission is permanently denied. Please allow it in App Settings.',
        );
        return false;
      }

      // 3. Retrieve actual GPS coordinates from device
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } on TimeoutException {
        // Fallback to last known position if current fix timed out
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        state = state.copyWith(
          permissionStatus: LocationPermissionStatus.error,
          hasRealGps: false,
          errorMessage: 'Unable to acquire GPS fix. Please verify device GPS signal.',
        );
        return false;
      }

      final latLng = LatLng(position.latitude, position.longitude);

      // 4. Reverse-geocode to a human-readable address
      final address = await _reverseGeocode(position.latitude, position.longitude);

      state = state.copyWith(
        permissionStatus: LocationPermissionStatus.granted,
        userLocation: latLng,
        readableAddress: address,
        hasRealGps: true,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        permissionStatus: LocationPermissionStatus.error,
        hasRealGps: false,
        errorMessage: 'Location error: $e',
      );
      return false;
    }
  }

  /// Reverse-geocodes coordinates into a readable Dharashiv street/area name using OpenStreetMap.
  Future<String> _reverseGeocode(double latitude, double longitude) async {
    final defaultLabel = 'Current Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await _httpClient.get(
        url,
        headers: {
          'User-Agent': 'DharRide-Flutter-App/1.0 (contact: support@dharride.demo)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'];
          final city = address['city'] ?? address['town'] ?? address['district'] ?? 'Dharashiv';

          if (road != null) {
            return '$road, $city';
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          // Take first two segments of display name for clean display
          final parts = displayName.split(',');
          if (parts.length >= 2) {
            return '${parts[0].trim()}, ${parts[1].trim()}';
          }
          return parts[0].trim();
        }
      }
    } catch (_) {
      // Offline or network error during reverse geocode; return clean coordinate string
    }

    return defaultLabel;
  }

  /// Opens the device's location settings page if GPS is turned off.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Opens the application details settings page if permission is permanently denied.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Backward-compatible requestPermission alias.
  Future<void> requestPermission() async {
    await requestAndFetchCurrentLocation();
  }

  /// Sets permission status explicitly, useful for automated testing and deterministic state simulation.
  void setPermissionStatus(LocationPermissionStatus status) {
    state = state.copyWith(permissionStatus: status);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
