enum UserRole {
  customer,
  driver,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.driver:
        return 'Auto Driver';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

enum DriverVerificationStatus {
  pending,
  approved,
  rejected,
  suspended;

  String get label {
    switch (this) {
      case DriverVerificationStatus.pending:
        return 'Pending Verification';
      case DriverVerificationStatus.approved:
        return 'Approved';
      case DriverVerificationStatus.rejected:
        return 'Rejected';
      case DriverVerificationStatus.suspended:
        return 'Suspended';
    }
  }
}

enum DriverAvailability {
  online,
  offline;

  bool get isOnline => this == DriverAvailability.online;
}

enum RideStatus {
  searching,
  driverAccepted,
  driverArriving,
  driverArrived,
  rideStarted,
  rideCompleted,
  cancelled;

  String get label {
    switch (this) {
      case RideStatus.searching:
        return 'Searching Driver';
      case RideStatus.driverAccepted:
        return 'Driver Assigned';
      case RideStatus.driverArriving:
        return 'Driver Arriving';
      case RideStatus.driverArrived:
        return 'Driver Arrived';
      case RideStatus.rideStarted:
        return 'Ride Started';
      case RideStatus.rideCompleted:
        return 'Ride Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PaymentMethod {
  cash,
  onlineUpi;

  String get label => this == PaymentMethod.cash ? 'Cash' : 'Online UPI';
}

enum PaymentStatus {
  pending,
  markedPaid,
  confirmed;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.markedPaid:
        return 'Marked Paid';
      case PaymentStatus.confirmed:
        return 'Confirmed';
    }
  }
}

enum ComplaintStatus {
  open,
  inReview,
  resolved,
  closed;

  String get label {
    switch (this) {
      case ComplaintStatus.open:
        return 'Open';
      case ComplaintStatus.inReview:
        return 'In Review';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }
}

enum AppLanguage {
  english('en', 'English'),
  marathi('mr', 'मराठी');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

enum NotificationCategory {
  all,
  rides,
  alerts;

  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'All';
      case NotificationCategory.rides:
        return 'Rides';
      case NotificationCategory.alerts:
        return 'Alerts';
    }
  }

  String labelLocalized(bool isMr) {
    switch (this) {
      case NotificationCategory.all:
        return isMr ? 'सर्व' : 'All';
      case NotificationCategory.rides:
        return isMr ? 'राइड्स' : 'Rides';
      case NotificationCategory.alerts:
        return isMr ? 'सूचना' : 'Alerts';
    }
  }
}

enum NotificationType {
  newRideRequest,
  rideAccepted,
  driverArriving,
  driverArrived,
  rideStarted,
  rideCompleted,
  rideCancelled,
  systemAlert,
  announcement;

  NotificationCategory get category {
    switch (this) {
      case NotificationType.newRideRequest:
      case NotificationType.rideAccepted:
      case NotificationType.driverArriving:
      case NotificationType.driverArrived:
      case NotificationType.rideStarted:
      case NotificationType.rideCompleted:
      case NotificationType.rideCancelled:
        return NotificationCategory.rides;
      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return NotificationCategory.alerts;
    }
  }

  bool get isRideEvent => category == NotificationCategory.rides;
}
