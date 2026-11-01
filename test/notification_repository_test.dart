import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dharride/data/models/enums.dart';
import 'package:dharride/data/models/notification_model.dart';
import 'package:dharride/data/repositories/notification_repository.dart';

void main() {
  group('NotificationRepository tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial repository state contains mock notifications with unread count', () {
      final state = container.read(notificationRepositoryProvider);
      expect(state.notifications.isNotEmpty, true);
      expect(state.unreadCount, greaterThan(0));
      expect(state.activeFilter, NotificationCategory.all);
    });

    test('Category filtering works correctly', () {
      final notifier = container.read(notificationRepositoryProvider.notifier);

      notifier.setFilter(NotificationCategory.rides);
      var state = container.read(notificationRepositoryProvider);
      expect(state.activeFilter, NotificationCategory.rides);
      for (final n in state.filteredNotifications) {
        expect(n.category, NotificationCategory.rides);
      }

      notifier.setFilter(NotificationCategory.alerts);
      state = container.read(notificationRepositoryProvider);
      expect(state.activeFilter, NotificationCategory.alerts);
      for (final n in state.filteredNotifications) {
        expect(n.category, NotificationCategory.alerts);
      }

      notifier.setFilter(NotificationCategory.all);
      state = container.read(notificationRepositoryProvider);
      expect(state.filteredNotifications.length, state.allCount);
    });

    test('markAsRead marks specific notification as read', () {
      final notifier = container.read(notificationRepositoryProvider.notifier);
      final initialUnread = container.read(notificationRepositoryProvider).unreadCount;

      notifier.markAsRead('notif_new_request');
      final updated = container.read(notificationRepositoryProvider);
      final item = updated.notifications.firstWhere((n) => n.id == 'notif_new_request');
      expect(item.isRead, true);
      expect(updated.unreadCount, initialUnread - 1);
    });

    test('markAllAsRead marks every notification as read', () {
      final notifier = container.read(notificationRepositoryProvider.notifier);
      notifier.markAllAsRead();

      final state = container.read(notificationRepositoryProvider);
      expect(state.unreadCount, 0);
      expect(state.notifications.every((n) => n.isRead), true);
    });

    test('clearNotification removes single notification', () {
      final notifier = container.read(notificationRepositoryProvider.notifier);
      final initialCount = container.read(notificationRepositoryProvider).allCount;

      notifier.clearNotification('notif_new_request');
      final state = container.read(notificationRepositoryProvider);
      expect(state.allCount, initialCount - 1);
      expect(state.notifications.any((n) => n.id == 'notif_new_request'), false);
    });

    test('clearAll removes all notifications and resetToMockData restores them', () {
      final notifier = container.read(notificationRepositoryProvider.notifier);

      notifier.clearAll();
      var state = container.read(notificationRepositoryProvider);
      expect(state.allCount, 0);
      expect(state.filteredNotifications.isEmpty, true);

      notifier.resetToMockData();
      state = container.read(notificationRepositoryProvider);
      expect(state.allCount, greaterThan(0));
    });

    test('addNotification adds item to the beginning of the list', () {
      final notifier = container.read(notificationRepositoryProvider.notifier);
      const testItem = NotificationModel(
        id: 'custom_test_1',
        type: NotificationType.driverArrived,
        titleEn: 'Driver Arrived',
        titleMr: 'चालक आला',
        bodyEn: 'Test body',
        bodyMr: 'टेस्ट मजकूर',
      );

      notifier.addNotification(testItem);
      final state = container.read(notificationRepositoryProvider);
      expect(state.notifications.first.id, 'custom_test_1');
    });
  });

  group('NotificationSettingsNotifier tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial settings default to true', () {
      final settings = container.read(notificationSettingsProvider);
      expect(settings.rideUpdates, true);
      expect(settings.bookingAlerts, true);
      expect(settings.notificationSounds, true);
      expect(settings.vibration, true);
      expect(settings.promotionalAlerts, true);
    });

    test('Toggles update settings properly', () {
      final notifier = container.read(notificationSettingsProvider.notifier);

      notifier.toggleRideUpdates(false);
      expect(container.read(notificationSettingsProvider).rideUpdates, false);

      notifier.toggleBookingAlerts(false);
      expect(container.read(notificationSettingsProvider).bookingAlerts, false);

      notifier.toggleNotificationSounds(false);
      expect(container.read(notificationSettingsProvider).notificationSounds, false);

      notifier.toggleVibration(false);
      expect(container.read(notificationSettingsProvider).vibration, false);

      notifier.togglePromotionalAlerts(false);
      expect(container.read(notificationSettingsProvider).promotionalAlerts, false);
    });
  });
}
