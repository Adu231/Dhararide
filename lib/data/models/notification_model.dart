import 'enums.dart';

class NotificationModel {
  final String id;
  final String titleEn;
  final String titleMr;
  final String bodyEn;
  final String bodyMr;
  final String timestamp;
  final bool isRead;
  final NotificationType type;
  final NotificationCategory category;
  final String? rideId;
  final String? pickupAddress;
  final String? destinationAddress;
  final String? driverName;
  final String? driverPhone;
  final String? autoNumber;
  final double? fare;
  final String? actionLabelEn;
  final String? actionLabelMr;

  const NotificationModel({
    required this.id,
    required this.titleEn,
    required this.titleMr,
    required this.bodyEn,
    required this.bodyMr,
    this.timestamp = 'Just now',
    this.isRead = false,
    this.type = NotificationType.systemAlert,
    NotificationCategory? category,
    this.rideId,
    this.pickupAddress,
    this.destinationAddress,
    this.driverName,
    this.driverPhone,
    this.autoNumber,
    this.fare,
    this.actionLabelEn,
    this.actionLabelMr,
  }) : category = category ?? (type == NotificationType.systemAlert || type == NotificationType.announcement
            ? NotificationCategory.alerts
            : NotificationCategory.rides);

  String getTitle(bool isMr) => isMr ? titleMr : titleEn;
  String getBody(bool isMr) => isMr ? bodyMr : bodyEn;
  String? getActionLabel(bool isMr) => isMr ? actionLabelMr : actionLabelEn;

  NotificationModel copyWith({
    String? id,
    String? titleEn,
    String? titleMr,
    String? bodyEn,
    String? bodyMr,
    String? timestamp,
    bool? isRead,
    NotificationType? type,
    NotificationCategory? category,
    String? rideId,
    String? pickupAddress,
    String? destinationAddress,
    String? driverName,
    String? driverPhone,
    String? autoNumber,
    double? fare,
    String? actionLabelEn,
    String? actionLabelMr,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleMr: titleMr ?? this.titleMr,
      bodyEn: bodyEn ?? this.bodyEn,
      bodyMr: bodyMr ?? this.bodyMr,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      category: category ?? this.category,
      rideId: rideId ?? this.rideId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      autoNumber: autoNumber ?? this.autoNumber,
      fare: fare ?? this.fare,
      actionLabelEn: actionLabelEn ?? this.actionLabelEn,
      actionLabelMr: actionLabelMr ?? this.actionLabelMr,
    );
  }
}
