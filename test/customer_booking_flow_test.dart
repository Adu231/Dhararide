import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dharride/core/services/customer_driver_location_service.dart';
import 'package:dharride/data/demo/demo_data.dart';
import 'package:dharride/data/models/enums.dart';
import 'package:dharride/data/models/location_model.dart';
import 'package:dharride/data/models/user_model.dart';
import 'package:dharride/data/repositories/ride_repository.dart';

void main() {
  group('CustomerDriverLocationService Tests (Keyless Maps Navigation)', () {
    test('Correctly retrieves coordinates for assigned driver with GPS', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(customerDriverLocationServiceProvider);
      final result = service.getAssignedDriverLocation(DemoData.demoDriver.id);

      expect(result.isAssigned, isTrue);
      expect(result.hasCoordinates, isTrue);
      expect(result.isValid, isTrue);
      expect(result.latitude, equals(18.1870));
      expect(result.longitude, equals(76.0415));
    });

    test('Constructs keyless Google Maps directions URL with travelmode=driving', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(customerDriverLocationServiceProvider);
      final url = service.buildGoogleMapsDirectionsUrl(latitude: 18.1870, longitude: 76.0415);

      expect(url, equals('https://www.google.com/maps/dir/?api=1&destination=18.187,76.0415&travelmode=driving'));
      expect(url.contains('key='), isFalse); // Verify NO Google Maps Platform API key required
    });

    test('Gracefully handles unassigned or empty driver ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(customerDriverLocationServiceProvider);
      final nullResult = service.getAssignedDriverLocation(null);
      final emptyResult = service.getAssignedDriverLocation('');

      expect(nullResult.isAssigned, isFalse);
      expect(nullResult.isValid, isFalse);
      expect(emptyResult.isAssigned, isFalse);
      expect(emptyResult.isValid, isFalse);
    });

    test('Gracefully handles non-existent driver ID without crashing or fabricating GPS', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(customerDriverLocationServiceProvider);
      final result = service.getAssignedDriverLocation('drv_unknown_999');

      expect(result.isAssigned, isTrue);
      expect(result.hasCoordinates, isFalse);
      expect(result.isValid, isFalse);
      expect(result.latitude, isNull);
      expect(result.longitude, isNull);
    });
  });

  group('Customer Ride Booking Flow Tests', () {
    test('Ride creation stores pickup, destination, fare and payment method', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const customer = UserModel(
        id: 'cust_test_1',
        name: 'Aditya Patil',
        phone: '+91 98220 12345',
        role: UserRole.customer,
      );

      final pickup = DemoData.popularPlaces[0].toLocationPoint();
      final destination = DemoData.popularPlaces[2].toLocationPoint();

      final rideRepo = container.read(rideRepositoryProvider.notifier);
      final ride = rideRepo.createRideRequest(
        customer: customer,
        pickup: pickup,
        destination: destination,
        suggestedFare: 35.0,
        paymentMethod: PaymentMethod.onlineUpi,
      );

      expect(ride.id.startsWith('RIDE-'), isTrue);
      expect(ride.customerId, equals('cust_test_1'));
      expect(ride.suggestedFare, equals(35.0));
      expect(ride.paymentMethod, equals(PaymentMethod.onlineUpi));
      expect(ride.status, equals(RideStatus.searching));

      final state = container.read(rideRepositoryProvider);
      expect(state.activeRide?.id, equals(ride.id));
    });

    test('Driver acceptance updates status to driverAccepted with driver info', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const customer = UserModel(
        id: 'cust_test_1',
        name: 'Aditya Patil',
        phone: '+91 98220 12345',
        role: UserRole.customer,
      );

      final pickup = DemoData.popularPlaces[0].toLocationPoint();
      final destination = DemoData.popularPlaces[2].toLocationPoint();

      final rideRepo = container.read(rideRepositoryProvider.notifier);
      final ride = rideRepo.createRideRequest(
        customer: customer,
        pickup: pickup,
        destination: destination,
        suggestedFare: 20.0,
      );

      rideRepo.driverAcceptRide(ride.id, DemoData.demoDriver);

      final state = container.read(rideRepositoryProvider);
      expect(state.activeRide?.status, equals(RideStatus.driverAccepted));
      expect(state.activeRide?.driverId, equals(DemoData.demoDriver.id));
      expect(state.activeRide?.driverName, equals(DemoData.demoDriver.name));
      expect(state.activeRide?.autoNumber, equals(DemoData.demoDriver.autoNumber));
    });

    test('Ride completion and cancellation work smoothly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const customer = UserModel(
        id: 'cust_test_1',
        name: 'Aditya Patil',
        phone: '+91 98220 12345',
        role: UserRole.customer,
      );

      final pickup = DemoData.popularPlaces[0].toLocationPoint();
      final destination = DemoData.popularPlaces[2].toLocationPoint();

      final rideRepo = container.read(rideRepositoryProvider.notifier);
      rideRepo.createRideRequest(
        customer: customer,
        pickup: pickup,
        destination: destination,
      );

      rideRepo.completeActiveRide();
      expect(container.read(rideRepositoryProvider).activeRide?.status, equals(RideStatus.rideCompleted));

      rideRepo.cancelActiveRide('Test cancel');
      expect(container.read(rideRepositoryProvider).activeRide?.status, equals(RideStatus.cancelled));
    });
  });
}
