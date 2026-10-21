import 'enums.dart';
import 'location_model.dart';

class RideModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? autoNumber;
  final double driverRating;
  final String? driverUpiId;
  final LocationPointModel pickup;
  final LocationPointModel destination;
  final double suggestedFare;
  final double? finalFare;
  final RideStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? cancelReason;
  final int? ratingGiven;
  final String? ratingComment;
  final String createdAt;
  final String? acceptedAt;
  final String? completedAt;

  const RideModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.autoNumber,
    this.driverRating = 4.8,
    this.driverUpiId,
    required this.pickup,
    required this.destination,
    this.suggestedFare = 20.0,
    this.finalFare = 20.0,
    this.status = RideStatus.searching,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.cancelReason,
    this.ratingGiven,
    this.ratingComment,
    this.createdAt = 'Just now',
    this.acceptedAt,
    this.completedAt,
  });

  RideModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? autoNumber,
    double? driverRating,
    String? driverUpiId,
    LocationPointModel? pickup,
    LocationPointModel? destination,
    double? suggestedFare,
    double? finalFare,
    RideStatus? status,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? cancelReason,
    int? ratingGiven,
    String? ratingComment,
    String? createdAt,
    String? acceptedAt,
    String? completedAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      autoNumber: autoNumber ?? this.autoNumber,
      driverRating: driverRating ?? this.driverRating,
      driverUpiId: driverUpiId ?? this.driverUpiId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      suggestedFare: suggestedFare ?? this.suggestedFare,
      finalFare: finalFare ?? this.finalFare,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cancelReason: cancelReason ?? this.cancelReason,
      ratingGiven: ratingGiven ?? this.ratingGiven,
      ratingComment: ratingComment ?? this.ratingComment,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
