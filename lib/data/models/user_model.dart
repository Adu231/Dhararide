import 'enums.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final AppLanguage language;
  final String? profileImage;
  final bool isSuspended;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.language = AppLanguage.english,
    this.profileImage,
    this.isSuspended = false,
    this.createdAt = '2026-09-25',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    AppLanguage? language,
    String? profileImage,
    bool? isSuspended,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      language: language ?? this.language,
      profileImage: profileImage ?? this.profileImage,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
