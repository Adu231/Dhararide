import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dharride/core/services/h3_service.dart';
import 'package:dharride/core/services/routing_service.dart';
import 'package:dharride/data/models/driver_model.dart';
import 'package:dharride/data/models/enums.dart';

void main() {
  group('H3Service Tests', () {
    late H3Service h3Service;

    setUp(() {
      h3Service = H3Service();
    });

    test('Validates geographic coordinates correctly', () {
      expect(h3Service.isValidCoordinate(18.1865, 76.0410), isTrue);
      expect(h3Service.isValidCoordinate(-90.0, 180.0), isTrue);
      expect(h3Service.isValidCoordinate(91.0, 76.0410), isFalse);
      expect(h3Service.isValidCoordinate(18.1865, 181.0), isFalse);
      expect(h3Service.isValidCoordinate(null, 76.0410), isFalse);
      expect(h3Service.isValidCoordinate(double.nan, 76.0410), isFalse);
    });

    test('Generates H3 cell index for Dharashiv coordinates at Resolution 8', () {
      // Dharashiv Central Bus Stand
      final cellBusStand = h3Service.geoToCell(18.1865, 76.0410, resolution: 8);
      expect(cellBusStand, isNotNull);
      expect(cellBusStand!.isNotEmpty, isTrue);

      // Nearby point (~100m away) should generate same or immediately adjacent cell
      final cellNearby = h3Service.geoToCell(18.1868, 76.0412, resolution: 8);
      expect(cellNearby, isNotNull);

      // Distant point should generate a different cell
      final cellDistant = h3Service.geoToCell(18.5204, 73.8567, resolution: 8); // Pune
      expect(cellBusStand != cellDistant, isTrue);
    });

    test('Expands H3 cell with gridDisk (k-ring) neighbors without duplicates', () {
      final originCell = h3Service.geoToCell(18.1865, 76.0410, resolution: 8)!;
      final disk1 = h3Service.getGridDisk(originCell, ringSize: 1);

      expect(disk1.contains(originCell), isTrue);
      expect(disk1.length, greaterThanOrEqualTo(7)); // center + 6 neighbors
      // Ensure all cells in disk are unique
      expect(disk1.toSet().length, equals(disk1.length));

      final disk2 = h3Service.getGridDisk(originCell, ringSize: 2);
      expect(disk2.length, greaterThan(disk1.length));
    });

    test('Indexes drivers and ignores offline, unapproved, and stale drivers', () {
      final now = DateTime.now();

      final drivers = [
        // 1. Online, approved, fresh location (Should be indexed)
        DriverModel(
          id: 'drv_valid_1',
          userId: 'u1',
          name: 'Driver One',
          phone: '9000000001',
          autoNumber: 'MH-25-A-1111',
          upiId: 'd1@upi',
          verificationStatus: DriverVerificationStatus.approved,
          availability: DriverAvailability.online,
          currentLatitude: 18.1870,
          currentLongitude: 76.0415,
          lastLocationUpdate: now,
        ),
        // 2. Offline driver (Must be ignored)
        DriverModel(
          id: 'drv_offline',
          userId: 'u2',
          name: 'Driver Offline',
          phone: '9000000002',
          autoNumber: 'MH-25-A-2222',
          upiId: 'd2@upi',
          verificationStatus: DriverVerificationStatus.approved,
          availability: DriverAvailability.offline,
          currentLatitude: 18.1870,
          currentLongitude: 76.0415,
          lastLocationUpdate: now,
        ),
        // 3. Pending verification driver (Must be ignored)
        DriverModel(
          id: 'drv_pending',
          userId: 'u3',
          name: 'Driver Pending',
          phone: '9000000003',
          autoNumber: 'MH-25-A-3333',
          upiId: 'd3@upi',
          verificationStatus: DriverVerificationStatus.pending,
          availability: DriverAvailability.online,
          currentLatitude: 18.1870,
          currentLongitude: 76.0415,
          lastLocationUpdate: now,
        ),
        // 4. Stale GPS location older than 30 minutes (Must be ignored)
        DriverModel(
          id: 'drv_stale',
          userId: 'u4',
          name: 'Driver Stale',
          phone: '9000000004',
          autoNumber: 'MH-25-A-4444',
          upiId: 'd4@upi',
          verificationStatus: DriverVerificationStatus.approved,
          availability: DriverAvailability.online,
          currentLatitude: 18.1870,
          currentLongitude: 76.0415,
          lastLocationUpdate: now.subtract(const Duration(hours: 1)),
        ),
        // 5. Missing GPS coordinates (Must be ignored)
        const DriverModel(
          id: 'drv_no_coords',
          userId: 'u5',
          name: 'Driver No GPS',
          phone: '9000000005',
          autoNumber: 'MH-25-A-5555',
          upiId: 'd5@upi',
          verificationStatus: DriverVerificationStatus.approved,
          availability: DriverAvailability.online,
        ),
      ];

      final indexMap = h3Service.indexDrivers(drivers);
      final allIndexedDrivers = indexMap.values.expand((list) => list).toList();

      expect(allIndexedDrivers.length, equals(1));
      expect(allIndexedDrivers.first.id, equals('drv_valid_1'));
    });

    test('Finds and ranks nearby drivers by actual distance, avoiding duplicates', () {
      final now = DateTime.now();

      final drivers = [
        // Driver A: ~600m away (at Kapad Market)
        DriverModel(
          id: 'drv_closer',
          userId: 'u1',
          name: 'Closer Driver',
          phone: '9000000001',
          autoNumber: 'MH-25-A-1111',
          upiId: 'd1@upi',
          verificationStatus: DriverVerificationStatus.approved,
          availability: DriverAvailability.online,
          currentLatitude: 18.1880,
          currentLongitude: 76.0450,
          lastLocationUpdate: now,
        ),
        // Driver B: ~1.5km away (at Civil Hospital)
        DriverModel(
          id: 'drv_further',
          userId: 'u2',
          name: 'Further Driver',
          phone: '9000000002',
          autoNumber: 'MH-25-A-2222',
          upiId: 'd2@upi',
          verificationStatus: DriverVerificationStatus.approved,
          availability: DriverAvailability.online,
          currentLatitude: 18.1810,
          currentLongitude: 76.0380,
          lastLocationUpdate: now,
        ),
      ];

      // Pickup at Central Bus Stand (18.1865, 76.0410)
      final results = h3Service.findNearbyDrivers(
        pickupLatitude: 18.1865,
        pickupLongitude: 76.0410,
        allDrivers: drivers,
        ringSize: 2,
        maxDistanceKm: 5.0,
      );

      expect(results.length, equals(2));
      // Closest driver must be ranked first
      expect(results[0].driver.id, equals('drv_closer'));
      expect(results[1].driver.id, equals('drv_further'));
      expect(results[0].distanceKm, lessThan(results[1].distanceKm));
    });
  });

  group('RoutingService Tests', () {
    test('Calculates realistic driving distance with tortuosity factor', () {
      const routing = RoutingService();
      const pickup = LatLng(18.1865, 76.0410); // Bus Stand
      const dest = LatLng(18.1810, 76.0380); // Civil Hospital

      final result = routing.calculateEstimate(pickup, dest);
      expect(result.distanceKm, greaterThan(0.5));
      expect(result.distanceKm, lessThan(3.0));
      expect(result.estimatedDurationMinutes, greaterThanOrEqualTo(2));
      expect(result.polylinePoints.length, equals(2));
      expect(result.isGeodesicEstimate, isTrue);
    });
  });
}
