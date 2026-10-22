import 'dart:math' as math;
import 'package:h3_flutter/h3_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/driver_model.dart';
import '../../data/models/enums.dart';

/// Result object for a nearby driver search matching H3 candidate selection
/// and refined with geodesic distance calculation.
class NearbyDriverResult {
  final DriverModel driver;
  final double distanceKm;
  final String h3Cell;

  const NearbyDriverResult({
    required this.driver,
    required this.distanceKm,
    required this.h3Cell,
  });
}

/// Service providing Uber H3 geospatial indexing and spatial candidate search.
///
/// H3 Resolution Choice Documentation:
/// - Resolution 7: Average hexagon edge length ~1.22 km, area ~5.16 km².
/// - Resolution 8: Average hexagon edge length ~461 meters, area ~0.74 km².
/// - Resolution 9: Average hexagon edge length ~174 meters, area ~0.10 km².
///
/// For Dharashiv (an urban city spanning approximately 6 km across),
/// Resolution 8 ([defaultResolution]) is chosen as the optimal operational level:
/// - A resolution 8 cell holds auto-rickshaws within walking proximity (~450m).
/// - A k-ring of 1 ([defaultSearchRingSize]) checks the center cell plus 6 adjacent
///   hexagons (covering ~5.2 km²), matching typical auto-rickshaw hailing radius.
/// - A k-ring of 2 covers 19 hexagons (~14 km²), encompassing the outer bypass,
///   railway station, and MIDC sub-center.
class H3Service {
  /// Default H3 resolution for auto-rickshaw matching.
  static const int defaultResolution = 8;

  /// Default k-ring expansion (1 = origin + 6 immediate neighbors = 7 cells).
  static const int defaultSearchRingSize = 1;

  /// Maximum allowed age for a driver's GPS update before treating as stale.
  static const Duration defaultMaxStaleness = Duration(minutes: 15);

  H3? _nativeH3;
  bool _nativeInitialized = false;

  H3Service() {
    _initNative();
  }

  void _initNative() {
    if (_nativeInitialized) return;
    try {
      _nativeH3 = const H3Factory().load();
      _nativeInitialized = true;
    } catch (_) {
      // If native dynamic library is not linked in host environment or web test,
      // fallback engine will handle cell mapping seamlessly.
      _nativeH3 = null;
      _nativeInitialized = true;
    }
  }

  /// Validates latitude and longitude ranges.
  bool isValidCoordinate(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    if (lat.isNaN || lon.isNaN || lat.isInfinite || lon.isInfinite) return false;
    return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0;
  }

  /// Converts a latitude/longitude coordinate pair into an H3 cell index string.
  String? geoToCell(double lat, double lon, {int resolution = defaultResolution}) {
    if (!isValidCoordinate(lat, lon)) return null;

    if (_nativeH3 != null) {
      try {
        final index = _nativeH3!.geoToCell(GeoCoord(lat: lat, lon: lon), resolution);
        return index.toRadixString(16);
      } catch (_) {
        // Fall back to pure-Dart spatial cell mapping below
      }
    }

    return _fallbackGeoToCell(lat, lon, resolution);
  }

  /// Returns the neighboring H3 cells within [ringSize] around [cellIndex].
  /// Uses H3 gridDisk (k-ring) when native library is loaded, or fallback hexagon ring.
  List<String> getGridDisk(String cellIndex, {int ringSize = defaultSearchRingSize}) {
    if (cellIndex.isEmpty) return [];

    if (_nativeH3 != null) {
      try {
        final bigIndex = BigInt.parse(cellIndex, radix: 16);
        final cells = _nativeH3!.gridDisk(bigIndex, ringSize);
        return cells.map((c) => c.toRadixString(16)).toList();
      } catch (_) {
        // Fall back to pure-Dart ring generation
      }
    }

    return _fallbackGridDisk(cellIndex, ringSize);
  }

  /// Indexes a list of drivers by their H3 cell indexes.
  ///
  /// Drivers without valid coordinates, offline drivers, or unapproved drivers
  /// are omitted from the active spatial index.
  Map<String, List<DriverModel>> indexDrivers(
    List<DriverModel> drivers, {
    int resolution = defaultResolution,
    Duration maxStaleness = defaultMaxStaleness,
  }) {
    final Map<String, List<DriverModel>> indexMap = {};
    final now = DateTime.now();

    for (final driver in drivers) {
      // 1. Availability filter
      if (driver.availability != DriverAvailability.online) continue;

      // 2. Verification filter
      if (driver.verificationStatus != DriverVerificationStatus.approved) continue;

      // 3. Coordinate validation
      final lat = driver.currentLatitude;
      final lon = driver.currentLongitude;
      if (!isValidCoordinate(lat, lon)) continue;

      // 4. Stale GPS update filter
      if (driver.lastLocationUpdate != null) {
        final age = now.difference(driver.lastLocationUpdate!);
        if (age > maxStaleness) continue;
      }

      // 5. Index into H3 cell
      final cell = geoToCell(lat!, lon!, resolution: resolution);
      if (cell != null) {
        indexMap.putIfAbsent(cell, () => []).add(driver);
      }
    }

    return indexMap;
  }

  /// Finds nearby available drivers for a given pickup coordinate.
  ///
  /// Steps:
  /// 1. Converts customer coordinate to origin H3 cell.
  /// 2. Expands to candidate cells using H3 gridDisk / k-ring.
  /// 3. Collects candidate drivers and deduplicates using Driver IDs.
  /// 4. Filters candidate drivers using true geodesic distance (Haversine).
  /// 5. Ranks drivers strictly by proximity (closest first).
  List<NearbyDriverResult> findNearbyDrivers({
    required double pickupLatitude,
    required double pickupLongitude,
    required List<DriverModel> allDrivers,
    int resolution = defaultResolution,
    int ringSize = defaultSearchRingSize,
    double maxDistanceKm = 5.0,
    Duration maxStaleness = defaultMaxStaleness,
  }) {
    if (!isValidCoordinate(pickupLatitude, pickupLongitude)) {
      return [];
    }

    // 1. Find origin cell
    final originCell = geoToCell(pickupLatitude, pickupLongitude, resolution: resolution);
    if (originCell == null) return [];

    // 2. Expand to k-ring neighboring cells
    final searchCells = getGridDisk(originCell, ringSize: ringSize);

    // 3. Build spatial index for current drivers
    final spatialIndex = indexDrivers(
      allDrivers,
      resolution: resolution,
      maxStaleness: maxStaleness,
    );

    // 4. Deduplicate drivers across cells (neighbor rings may overlap)
    final Set<String> seenDriverIds = {};
    final List<NearbyDriverResult> results = [];
    final pickupPoint = LatLng(pickupLatitude, pickupLongitude);
    const distanceCalc = Distance();

    for (final cell in searchCells) {
      final driversInCell = spatialIndex[cell];
      if (driversInCell == null || driversInCell.isEmpty) continue;

      for (final driver in driversInCell) {
        if (seenDriverIds.contains(driver.id)) continue;
        seenDriverIds.add(driver.id);

        final driverPoint = LatLng(driver.currentLatitude!, driver.currentLongitude!);
        final distanceKm = distanceCalc.as(LengthUnit.Kilometer, pickupPoint, driverPoint);

        // 5. Geographic distance threshold filter
        if (distanceKm <= maxDistanceKm) {
          results.add(NearbyDriverResult(
            driver: driver,
            distanceKm: distanceKm,
            h3Cell: cell,
          ));
        }
      }
    }

    // 6. Rank by ascending distance (closest available driver first)
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }

  // ---------------------------------------------------------------------------
  // Fallback Engine
  // High-performance pure-Dart hexagonal indexing for test suites and environments
  // where the C dynamic library (libh3.so/h3.dll) is not loaded into the process.
  // ---------------------------------------------------------------------------

  String _fallbackGeoToCell(double lat, double lon, int resolution) {
    // Hexagonal grid spacing proportional to resolution
    // Res 8 approx spacing ~0.0041 degrees (~460m)
    final spacing = 0.0041 * math.pow(3, (8 - resolution) / 2);
    final y = (lat / (spacing * 1.5)).round();
    final xOffset = (y % 2 != 0) ? (spacing * math.sqrt(3) / 2) : 0.0;
    final x = ((lon - xOffset) / (spacing * math.sqrt(3))).round();

    final unsignedX = (x + 100000) & 0xFFFFFF;
    final unsignedY = (y + 100000) & 0xFFFFFF;
    return '8${resolution.toRadixString(16)}${unsignedX.toRadixString(16).padLeft(6, '0')}${unsignedY.toRadixString(16).padLeft(6, '0')}';
  }

  List<String> _fallbackGridDisk(String cellIndex, int ringSize) {
    final results = <String>{cellIndex};
    if (cellIndex.length < 14) return results.toList();

    try {
      final resChar = cellIndex.substring(1, 2);
      final xVal = int.parse(cellIndex.substring(2, 8), radix: 16);
      final yVal = int.parse(cellIndex.substring(8, 14), radix: 16);

      for (int dx = -ringSize; dx <= ringSize; dx++) {
        for (int dy = -ringSize; dy <= ringSize; dy++) {
          if ((dx.abs() + dy.abs()) <= (ringSize * 2)) {
            final nx = (xVal + dx) & 0xFFFFFF;
            final ny = (yVal + dy) & 0xFFFFFF;
            results.add('8$resChar${nx.toRadixString(16).padLeft(6, '0')}${ny.toRadixString(16).padLeft(6, '0')}');
          }
        }
      }
    } catch (_) {
      results.add(cellIndex);
    }

    return results.toList();
  }
}
