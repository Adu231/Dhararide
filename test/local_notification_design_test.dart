import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dharride/core/brand/brand_config.dart';
import 'package:dharride/core/services/local_notification_service.dart';
import 'package:dharride/data/models/enums.dart';
import 'package:dharride/data/models/notification_model.dart';

void main() {
  group('LocalNotificationService Target Design Verification', () {
    late LocalNotificationService service;

    setUp(() {
      service = LocalNotificationService();
    });

    const sampleRideNotification = NotificationModel(
      id: 'test_ride_accepted',
      type: NotificationType.rideAccepted,
      category: NotificationCategory.rides,
      titleEn: 'Ride Accepted!',
      titleMr: 'राइड स्वीकारली!',
      bodyEn: 'Ramesh Shinde accepted your ride.',
      bodyMr: 'रमेश शिंदे यांनी तुमची राइड स्वीकारली.',
      driverName: 'Ramesh Shinde',
      autoNumber: 'MH-25-AZ-4589',
      fare: 120.0,
      pickupAddress: 'Dharashiv Central Bus Stand',
      destinationAddress: 'Government Civil Hospital',
    );

    test('rideAccepted actions order has Call Driver first, View Ride second for Customer', () {
      final actionsEn = service.getActionsForNotification(
        type: NotificationType.rideAccepted,
        role: UserRole.customer,
        isMr: false,
        notification: sampleRideNotification,
      );

      expect(actionsEn.length, 2);
      expect(actionsEn[0].id, LocalNotificationService.actionCallDriver);
      expect(actionsEn[0].title, 'Call Driver');
      expect(actionsEn[1].id, LocalNotificationService.actionViewRide);
      expect(actionsEn[1].title, 'View Ride');

      final actionsMr = service.getActionsForNotification(
        type: NotificationType.rideAccepted,
        role: UserRole.customer,
        isMr: true,
        notification: sampleRideNotification,
      );

      expect(actionsMr.length, 2);
      expect(actionsMr[0].id, LocalNotificationService.actionCallDriver);
      expect(actionsMr[0].title, 'चालकाला कॉल');
      expect(actionsMr[1].id, LocalNotificationService.actionViewRide);
      expect(actionsMr[1].title, 'राइड पहा');
    });

    test('rideAccepted actions order has Call Customer first, View Pickup second for Driver', () {
      final actions = service.getActionsForNotification(
        type: NotificationType.rideAccepted,
        role: UserRole.driver,
        isMr: false,
        notification: sampleRideNotification,
      );

      expect(actions.length, 2);
      expect(actions[0].id, LocalNotificationService.actionCallCustomer);
      expect(actions[0].title, 'Call Customer');
      expect(actions[1].id, LocalNotificationService.actionViewRide);
      expect(actions[1].title, 'View Pickup');
    });

    test('driverArriving and driverArrived actions order has Call Driver first for Customer', () {
      for (final type in [NotificationType.driverArriving, NotificationType.driverArrived]) {
        final actions = service.getActionsForNotification(
          type: type,
          role: UserRole.customer,
          isMr: false,
          notification: sampleRideNotification,
        );
        expect(actions.first.id, LocalNotificationService.actionCallDriver);
        expect(actions.first.title, 'Call Driver');
      }
    });

    test('newRideRequest actions has Accept and Decline for Driver', () {
      final actions = service.getActionsForNotification(
        type: NotificationType.newRideRequest,
        role: UserRole.driver,
        isMr: false,
        notification: sampleRideNotification,
      );

      expect(actions.length, 2);
      expect(actions[0].id, LocalNotificationService.actionAcceptRide);
      expect(actions[0].title, 'Accept');
      expect(actions[1].id, LocalNotificationService.actionRejectRide);
      expect(actions[1].title, 'Decline');
    });

    test('rideCompleted actions has View Details for Customer, View Earnings & Dashboard for Driver', () {
      final custActions = service.getActionsForNotification(
        type: NotificationType.rideCompleted,
        role: UserRole.customer,
        isMr: false,
        notification: sampleRideNotification,
      );
      expect(custActions.length, 1);
      expect(custActions[0].id, LocalNotificationService.actionViewReceipt);
      expect(custActions[0].title, 'View Details');

      final driverActions = service.getActionsForNotification(
        type: NotificationType.rideCompleted,
        role: UserRole.driver,
        isMr: false,
        notification: sampleRideNotification,
      );
      expect(driverActions.length, 2);
      expect(driverActions[0].id, LocalNotificationService.actionViewEarnings);
      expect(driverActions[0].title, 'View Earnings');
      expect(driverActions[1].id, LocalNotificationService.actionDriverHome);
      expect(driverActions[1].title, 'Dashboard');
    });

    test('DharRide branding uses accent yellow #FFC107', () {
      expect(BrandConfig.accentYellow, const Color(0xFFFFC107));
    });
  });
}

