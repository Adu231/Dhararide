class NotificationSettingsModel {
  final bool rideUpdates;
  final bool bookingAlerts;
  final bool notificationSounds;
  final bool vibration;
  final bool promotionalAlerts;

  const NotificationSettingsModel({
    this.rideUpdates = true,
    this.bookingAlerts = true,
    this.notificationSounds = true,
    this.vibration = true,
    this.promotionalAlerts = true,
  });

  NotificationSettingsModel copyWith({
    bool? rideUpdates,
    bool? bookingAlerts,
    bool? notificationSounds,
    bool? vibration,
    bool? promotionalAlerts,
  }) {
    return NotificationSettingsModel(
      rideUpdates: rideUpdates ?? this.rideUpdates,
      bookingAlerts: bookingAlerts ?? this.bookingAlerts,
      notificationSounds: notificationSounds ?? this.notificationSounds,
      vibration: vibration ?? this.vibration,
      promotionalAlerts: promotionalAlerts ?? this.promotionalAlerts,
    );
  }
}
