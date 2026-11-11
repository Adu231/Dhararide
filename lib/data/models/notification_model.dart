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
  // Rich visual metadata matching DharRide notification designs
  final String? distance; // e.g., '0.5 km away' or '14 km'
  final String? eta; // e.g., 'ETA: 2 min'
  final String? cancelReason; // e.g., 'Driver unavailable'
  final String? cancelReasonMr; // e.g., 'चालक अनुपलब्ध'
  final String? pickupDistance; // e.g., '2.3 km'
  final String? dropDistance; // e.g., '6.8 km'
  final String? statusBadgeEn; // e.g., 'Accepted' or 'Done'
  final String? statusBadgeMr; // e.g., 'स्वीकारले' or 'पूर्ण'

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
    this.distance,
    this.eta,
    this.cancelReason,
    this.cancelReasonMr,
    this.pickupDistance,
    this.dropDistance,
    this.statusBadgeEn,
    this.statusBadgeMr,
  }) : category = category ??
            (type == NotificationType.systemAlert || type == NotificationType.announcement
                ? NotificationCategory.alerts
                : NotificationCategory.rides);

  String getTitle(bool isMr) => isMr ? titleMr : titleEn;
  String getBody(bool isMr) => isMr ? bodyMr : bodyEn;
  String? getActionLabel(bool isMr) => isMr ? actionLabelMr : actionLabelEn;

  String getCancelReason(bool isMr) {
    if (isMr) {
      return cancelReasonMr ?? cancelReason ?? 'चालक अनुपलब्ध';
    }
    return cancelReason ?? 'Driver unavailable';
  }

  String getDistanceText(bool isMr) {
    if (distance != null && distance!.isNotEmpty) return distance!;
    if (type == NotificationType.rideCompleted) return '14 km';
    if (type == NotificationType.driverArriving) return isMr ? '०.५ किमी अंतरावर' : '0.5 km away';
    return isMr ? '२.३ किमी' : '2.3 km';
  }

  String getEtaText(bool isMr) {
    if (eta != null && eta!.isNotEmpty) return eta!;
    return isMr ? 'अंदाजित वेळ: २ मिनिटे' : 'ETA: 2 min';
  }

  String getStatusBadge(bool isMr) {
    if (isMr) {
      return statusBadgeMr ?? (type == NotificationType.rideCompleted ? 'पूर्ण' : 'स्वीकारले');
    }
    return statusBadgeEn ?? (type == NotificationType.rideCompleted ? 'Done' : 'Accepted');
  }

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
    String? distance,
    String? eta,
    String? cancelReason,
    String? cancelReasonMr,
    String? pickupDistance,
    String? dropDistance,
    String? statusBadgeEn,
    String? statusBadgeMr,
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
      distance: distance ?? this.distance,
      eta: eta ?? this.eta,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelReasonMr: cancelReasonMr ?? this.cancelReasonMr,
      pickupDistance: pickupDistance ?? this.pickupDistance,
      dropDistance: dropDistance ?? this.dropDistance,
      statusBadgeEn: statusBadgeEn ?? this.statusBadgeEn,
      statusBadgeMr: statusBadgeMr ?? this.statusBadgeMr,
    );
  }
}
