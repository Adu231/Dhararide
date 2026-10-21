import 'enums.dart';

class DriverModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String autoNumber;
  final String upiId;
  final String? upiQrUrl;
  final DriverVerificationStatus verificationStatus;
  final DriverAvailability availability;
  final double rating;
  final int totalRides;
  final double totalEarnings;
  final String? profileImage;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final String? h3Index;
  final String createdAt;

  const DriverModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.autoNumber,
    required this.upiId,
    this.upiQrUrl,
    this.verificationStatus = DriverVerificationStatus.pending,
    this.availability = DriverAvailability.offline,
    this.rating = 4.8,
    this.totalRides = 0,
    this.totalEarnings = 0.0,
    this.profileImage,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.h3Index,
    this.createdAt = '2026-09-25',
  });

  DriverModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? autoNumber,
    String? upiId,
    String? upiQrUrl,
    DriverVerificationStatus? verificationStatus,
    DriverAvailability? availability,
    double? rating,
    int? totalRides,
    double? totalEarnings,
    String? profileImage,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    String? h3Index,
    String? createdAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      autoNumber: autoNumber ?? this.autoNumber,
      upiId: upiId ?? this.upiId,
      upiQrUrl: upiQrUrl ?? this.upiQrUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      availability: availability ?? this.availability,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      profileImage: profileImage ?? this.profileImage,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      h3Index: h3Index ?? this.h3Index,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
