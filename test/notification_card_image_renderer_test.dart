import 'package:flutter_test/flutter_test.dart';
import 'package:dharride/core/services/notification_card_image_renderer.dart';
import 'package:dharride/data/demo/demo_data.dart';
import 'package:dharride/data/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationCardImageRenderer Tests', () {
    test('Renders valid PNG bitmap for rideCompleted (User Screenshot replica)', () async {
      final notif = DemoData.demoNotifications.firstWhere(
        (n) => n.type == NotificationType.rideCompleted,
        orElse: () => DemoData.demoNotifications.first,
      );

      final bytes = await NotificationCardImageRenderer.renderCardBitmap(
        type: NotificationType.rideCompleted,
        role: UserRole.driver,
        isMr: false,
        notification: notif,
      );

      expect(bytes, isNotEmpty);
      // Valid PNG signature: [0x89, 0x50, 0x4E, 0x47]
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });

    test('Renders valid PNG bitmaps for all 7 Notification Types', () async {
      const types = [
        NotificationType.newRideRequest,
        NotificationType.rideAccepted,
        NotificationType.driverArriving,
        NotificationType.driverArrived,
        NotificationType.rideStarted,
        NotificationType.rideCompleted,
        NotificationType.rideCancelled,
      ];

      for (final type in types) {
        final notif = DemoData.demoNotifications.firstWhere(
          (n) => n.type == type,
          orElse: () => DemoData.demoNotifications.first,
        );

        final bytesEn = await NotificationCardImageRenderer.renderCardBitmap(
          type: type,
          role: UserRole.customer,
          isMr: false,
          notification: notif,
        );
        expect(bytesEn.length, greaterThan(100));

        final bytesMr = await NotificationCardImageRenderer.renderCardBitmap(
          type: type,
          role: UserRole.driver,
          isMr: true,
          notification: notif,
        );
        expect(bytesMr.length, greaterThan(100));
      }
    });
  });
}

