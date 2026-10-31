import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/driver_model.dart';
import '../../data/repositories/driver_repository.dart';

/// Represents the status and coordinates of an assigned driver for customer-side consumption.
class DriverLocationResult {
  final bool isAssigned;
  final bool hasCoordinates;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;
  final bool isStale;
  final String? message;

  const DriverLocationResult({
    required this.isAssigned,
    required this.hasCoordinates,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.isStale = false,
    this.message,
  });

  bool get isValid => isAssigned && hasCoordinates && latitude != null && longitude != null;
}

/// Customer-side service responsible for:
/// 1. Safely querying the assigned driver's location from the repository.
/// 2. Validating coordinate bounds without fabricating data.
/// 3. Constructing official, keyless Google Maps URLs for driver navigation, pickup navigation, and drop navigation.
/// 4. Opening URLs via external application (Google Maps) or browser fallback.
class CustomerDriverLocationService {
  final Ref _ref;

  CustomerDriverLocationService(this._ref);

  /// Retrieves the latest known location of the driver assigned to an active booking.
  DriverLocationResult getAssignedDriverLocation(String? driverId) {
    if (driverId == null || driverId.isEmpty) {
      return const DriverLocationResult(
        isAssigned: false,
        hasCoordinates: false,
        message: 'No driver is currently assigned to this booking.',
      );
    }

    final allDrivers = _ref.read(driverRepositoryProvider);
    final driver = allDrivers.cast<DriverModel?>().firstWhere(
          (d) => d?.id == driverId,
          orElse: () => null,
        );

    if (driver == null) {
      return const DriverLocationResult(
        isAssigned: true,
        hasCoordinates: false,
        message: 'Assigned driver record not found in system.',
      );
    }

    final lat = driver.currentLatitude;
    final lng = driver.currentLongitude;

    // Validate coordinates are present and within valid latitude/longitude ranges
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0) || lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
      return const DriverLocationResult(
        isAssigned: true,
        hasCoordinates: false,
        message: 'Driver location is not available yet. Waiting for driver GPS update.',
      );
    }

    // Check staleness (if last update was more than 15 minutes ago)
    bool isStale = false;
    if (driver.lastLocationUpdate != null) {
      final diff = DateTime.now().difference(driver.lastLocationUpdate!);
      if (diff.inMinutes > 15) {
        isStale = true;
      }
    }

    return DriverLocationResult(
      isAssigned: true,
      hasCoordinates: true,
      latitude: lat,
      longitude: lng,
      lastUpdated: driver.lastLocationUpdate,
      isStale: isStale,
      message: isStale ? 'Driver coordinates may be delayed.' : null,
    );
  }

  /// Builds a keyless Google Maps directions URL with driving travel mode.
  /// Example: https://www.google.com/maps/dir/?api=1&destination=18.1870,76.0415&travelmode=driving
  String buildGoogleMapsDirectionsUrl({required double latitude, required double longitude}) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
  }

  /// Launches a Google Maps URL, falling back to browser if the Google Maps app is not installed.
  Future<bool> launchNavigationUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      // First try launching directly in external application (e.g. Google Maps app)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Fallback: try platform default / browser
      return await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      // Final fallback
      try {
        return await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
      } catch (_) {
        return false;
      }
    }
  }

  /// Opens Google Maps pointing to the assigned driver's location.
  Future<bool> openDriverLocationInGoogleMaps(String? driverId) async {
    final location = getAssignedDriverLocation(driverId);
    if (!location.isValid) return false;
    final url = buildGoogleMapsDirectionsUrl(
      latitude: location.latitude!,
      longitude: location.longitude!,
    );
    return await launchNavigationUrl(url);
  }

  /// Opens Google Maps pointing to a destination or pickup location.
  Future<bool> openLocationInGoogleMaps({required double latitude, required double longitude}) async {
    final url = buildGoogleMapsDirectionsUrl(latitude: latitude, longitude: longitude);
    return await launchNavigationUrl(url);
  }
}

final customerDriverLocationServiceProvider = Provider<CustomerDriverLocationService>((ref) {
  return CustomerDriverLocationService(ref);
});
