import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../demo/demo_data.dart';
import '../models/enums.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';

class NotificationRepositoryState {
  final List<NotificationModel> notifications;
  final NotificationCategory activeFilter;

  const NotificationRepositoryState({
    required this.notifications,
    this.activeFilter = NotificationCategory.all,
  });

  List<NotificationModel> get filteredNotifications {
    switch (activeFilter) {
      case NotificationCategory.all:
        return notifications;
      case NotificationCategory.rides:
        return notifications.where((n) => n.category == NotificationCategory.rides).toList();
      case NotificationCategory.alerts:
        return notifications.where((n) => n.category == NotificationCategory.alerts).toList();
    }
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  int get allCount => notifications.length;
  int get ridesCount => notifications.where((n) => n.category == NotificationCategory.rides).length;
  int get alertsCount => notifications.where((n) => n.category == NotificationCategory.alerts).length;

  int get unreadRidesCount =>
      notifications.where((n) => n.category == NotificationCategory.rides && !n.isRead).length;
  int get unreadAlertsCount =>
      notifications.where((n) => n.category == NotificationCategory.alerts && !n.isRead).length;

  NotificationRepositoryState copyWith({
    List<NotificationModel>? notifications,
    NotificationCategory? activeFilter,
  }) {
    return NotificationRepositoryState(
      notifications: notifications ?? this.notifications,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class NotificationRepositoryNotifier extends Notifier<NotificationRepositoryState> {
  @override
  NotificationRepositoryState build() {
    return const NotificationRepositoryState(
      notifications: DemoData.demoNotifications,
      activeFilter: NotificationCategory.all,
    );
  }

  void setFilter(NotificationCategory filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }

  void clearNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);
  }

  void clearAll() {
    state = state.copyWith(notifications: []);
  }

  void resetToMockData() {
    state = state.copyWith(notifications: DemoData.demoNotifications);
  }

  void addNotification(NotificationModel item) {
    state = state.copyWith(notifications: [item, ...state.notifications]);
  }
}

final notificationRepositoryProvider =
    NotifierProvider<NotificationRepositoryNotifier, NotificationRepositoryState>(
  NotificationRepositoryNotifier.new,
);

class NotificationSettingsNotifier extends Notifier<NotificationSettingsModel> {
  @override
  NotificationSettingsModel build() {
    return const NotificationSettingsModel();
  }

  void toggleRideUpdates(bool value) {
    state = state.copyWith(rideUpdates: value);
  }

  void toggleBookingAlerts(bool value) {
    state = state.copyWith(bookingAlerts: value);
  }

  void toggleNotificationSounds(bool value) {
    state = state.copyWith(notificationSounds: value);
  }

  void toggleVibration(bool value) {
    state = state.copyWith(vibration: value);
  }

  void togglePromotionalAlerts(bool value) {
    state = state.copyWith(promotionalAlerts: value);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsModel>(
  NotificationSettingsNotifier.new,
);
