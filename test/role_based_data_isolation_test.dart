import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dharride/data/demo/demo_data.dart';
import 'package:dharride/data/models/enums.dart';
import 'package:dharride/data/models/location_model.dart';
import 'package:dharride/data/models/notification_model.dart';
import 'package:dharride/data/models/user_model.dart';
import 'package:dharride/data/repositories/ride_repository.dart';
import 'package:dharride/data/repositories/user_repository.dart';
import 'package:dharride/data/repositories/driver_repository.dart';
import 'package:dharride/data/session/session_manager.dart';
import 'package:dharride/core/services/local_notification_service.dart';

void main() {
  group('Role-Based User Data Isolation Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Customers only access their own ride history', () {
      final rideRepo = container.read(rideRepositoryProvider.notifier);

      // Customer 1: Aditya Patil
      final cust1Rides = rideRepo.getRidesForCustomer(DemoData.demoCustomer.id);
      expect(cust1Rides.isNotEmpty, isTrue);
      for (final r in cust1Rides) {
        expect(r.customerId, equals(DemoData.demoCustomer.id));
      }
      expect(cust1Rides.any((r) => r.customerId == DemoData.demoCustomer2.id), isFalse);

      // Customer 2: Pooja Kulkarni
      final cust2Rides = rideRepo.getRidesForCustomer(DemoData.demoCustomer2.id);
      expect(cust2Rides.isNotEmpty, isTrue);
      for (final r in cust2Rides) {
        expect(r.customerId, equals(DemoData.demoCustomer2.id));
      }
      expect(cust2Rides.any((r) => r.customerId == DemoData.demoCustomer.id), isFalse);

      // Newly registered or empty customer
      final newCustRides = rideRepo.getRidesForCustomer('usr_new_999');
      expect(newCustRides.isEmpty, isTrue);
    });

    test('Drivers only access their assigned rides and earnings', () {
      final rideRepo = container.read(rideRepositoryProvider.notifier);

      // Driver 1: Ramesh Shinde (drv_01)
      final drv1Rides = rideRepo.getRidesForDriver(DemoData.demoDriver.id);
      expect(drv1Rides.isNotEmpty, isTrue);
      for (final r in drv1Rides) {
        expect(r.driverId, equals(DemoData.demoDriver.id));
      }
      expect(drv1Rides.any((r) => r.driverId == DemoData.demoDriver2.id), isFalse);

      // Driver 2: Santosh Gaikwad (drv_03)
      final drv2Rides = rideRepo.getRidesForDriver(DemoData.demoDriver2.id);
      expect(drv2Rides.isNotEmpty, isTrue);
      for (final r in drv2Rides) {
        expect(r.driverId, equals(DemoData.demoDriver2.id));
      }
      expect(drv2Rides.any((r) => r.driverId == DemoData.demoDriver.id), isFalse);

      // Newly registered driver has no completed rides initially
      final newDrvRides = rideRepo.getRidesForDriver('drv_new_999');
      expect(newDrvRides.isEmpty, isTrue);
    });

    test('Driver earnings are calculated dynamically and isolated per driver', () {
      final rideRepo = container.read(rideRepositoryProvider.notifier);

      final drv1Earnings = rideRepo.calculateDriverEarnings(DemoData.demoDriver.id);
      expect(drv1Earnings['totalEarnings'], greaterThan(0.0));
      expect(drv1Earnings['commissionPaid'], equals(0.0)); // 0% commission policy

      final drv2Earnings = rideRepo.calculateDriverEarnings(DemoData.demoDriver2.id);
      expect(drv2Earnings['totalEarnings'], greaterThan(0.0));
      expect(drv2Earnings['commissionPaid'], equals(0.0));

      final newDrvEarnings = rideRepo.calculateDriverEarnings('drv_unassigned');
      expect(newDrvEarnings['totalEarnings'], equals(0.0));
      expect(newDrvEarnings['totalRidesCount'], equals(0));
    });

    test('Active ride ownership check prevents unauthorized access', () {
      final rideRepo = container.read(rideRepositoryProvider.notifier);

      const cust1 = DemoData.demoCustomer;
      const cust2 = DemoData.demoCustomer2;

      // Customer 1 books a ride
      final ride = rideRepo.createRideRequest(
        customer: cust1,
        pickup: const LocationPointModel(address: 'Bus Stand', placeName: 'Central Bus Stand'),
        destination: const LocationPointModel(address: 'Hospital', placeName: 'Civil Hospital'),
        suggestedFare: 25.0,
      );

      // Customer 1 is owner
      expect(rideRepo.getActiveRideForCustomer(cust1.id)?.id, equals(ride.id));
      // Customer 2 is NOT owner, must get null
      expect(rideRepo.getActiveRideForCustomer(cust2.id), isNull);

      // Driver 1 accepts the ride
      rideRepo.driverAcceptRide(ride.id, DemoData.demoDriver);

      // Driver 1 is assigned
      expect(rideRepo.getActiveRideForDriver(DemoData.demoDriver.id)?.id, equals(ride.id));
      // Driver 2 is NOT assigned, must get null
      expect(rideRepo.getActiveRideForDriver(DemoData.demoDriver2.id), isNull);
    });

    test('Session reset clears driver and active ride to prevent state leakage', () {
      // 1. Log in as driver
      container.read(currentUserProvider.notifier).login(DemoData.demoDriverUser);
      container.read(currentDriverProvider.notifier).setDriver(DemoData.demoDriver);

      expect(container.read(currentUserProvider), isNotNull);
      expect(container.read(currentDriverProvider), isNotNull);

      // 2. Perform clean logout
      container.read(currentUserProvider.notifier).logout();
      container.read(currentDriverProvider.notifier).setDriver(null);
      container.read(rideRepositoryProvider.notifier).clearActiveRide();

      // 3. Verify complete cleanup
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(currentDriverProvider), isNull);
      expect(container.read(rideRepositoryProvider).activeRide, isNull);
    });

    test('LocalNotificationService produces role-appropriate action buttons', () {
      final service = LocalNotificationService();

      const sampleNotif = NotificationModel(
        id: 'test_notif',
        type: NotificationType.rideAccepted,
        titleEn: 'Ride Accepted',
        titleMr: 'राइड स्वीकारली',
        bodyEn: 'Ramesh accepted',
        bodyMr: 'रमेश यांनी स्वीकारली',
      );

      // Customer actions for rideAccepted: [View Ride, Call Driver]
      final custActions = service.getActionsForNotification(
        type: NotificationType.rideAccepted,
        role: UserRole.customer,
        isMr: false,
        notification: sampleNotif,
      );
      expect(custActions.any((a) => a.id == LocalNotificationService.actionCallDriver), isTrue);

      // Driver actions for rideAccepted: [View Pickup, Call Customer]
      final drvActions = service.getActionsForNotification(
        type: NotificationType.rideAccepted,
        role: UserRole.driver,
        isMr: false,
        notification: sampleNotif,
      );
      expect(drvActions.any((a) => a.id == LocalNotificationService.actionCallCustomer), isTrue);

      // Driver actions for newRideRequest: [Accept, Decline]
      final drvNewRequestActions = service.getActionsForNotification(
        type: NotificationType.newRideRequest,
        role: UserRole.driver,
        isMr: false,
        notification: sampleNotif,
      );
      expect(drvNewRequestActions.any((a) => a.id == LocalNotificationService.actionAcceptRide), isTrue);
      expect(drvNewRequestActions.any((a) => a.id == LocalNotificationService.actionRejectRide), isTrue);
    });
  });
}

