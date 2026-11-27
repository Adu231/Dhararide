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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'language': language.code,
        'profileImage': profileImage,
        'isSuspended': isSuspended,
        'createdAt': createdAt,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.customer,
        ),
        language: AppLanguage.fromCode(json['language'] as String? ?? 'en'),
        profileImage: json['profileImage'] as String?,
        isSuspended: json['isSuspended'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '2026-09-25',
      );
}
