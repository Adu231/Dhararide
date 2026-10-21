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
  rideStarted,
  rideCompleted,
  cancelled;

  String get label {
    switch (this) {
      case RideStatus.searching:
        return 'Searching Driver';
      case RideStatus.driverAccepted:
        return 'Driver Accepted';
      case RideStatus.driverArriving:
        return 'Driver Arriving';
      case RideStatus.rideStarted:
        return 'Ride in Progress';
      case RideStatus.rideCompleted:
        return 'Completed';
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
