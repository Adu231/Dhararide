import 'enums.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final UserRole userRole;
  final String? rideId;
  final String category;
  final String description;
  final ComplaintStatus status;
  final String? adminNotes;
  final String createdAt;

  const ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.rideId,
    required this.category,
    required this.description,
    this.status = ComplaintStatus.open,
    this.adminNotes,
    this.createdAt = '2026-09-25',
  });

  ComplaintModel copyWith({
    String? id,
    String? userId,
    String? userName,
    UserRole? userRole,
    String? rideId,
    String? category,
    String? description,
    ComplaintStatus? status,
    String? adminNotes,
    String? createdAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      rideId: rideId ?? this.rideId,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
