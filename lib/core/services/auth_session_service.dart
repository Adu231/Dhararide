import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';

/// Secure session service powered by [FlutterSecureStorage].
/// Stores authentication tokens and encrypted user session details.
/// Never stores passwords or OTPs.
class AuthSessionService {
  static final AuthSessionService _instance = AuthSessionService._internal();
  factory AuthSessionService() => _instance;
  AuthSessionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'dharride_auth_token';
  static const String _keyUser = 'dharride_auth_user';
  static const String _keyTimestamp = 'dharride_auth_timestamp';

  bool get _isBindingReady {
    try {
      return WidgetsBinding.instance != null;
    } catch (_) {
      return false;
    }
  }

  /// Securely save authenticated session with token and user details.
  Future<void> saveSession({
    required UserModel user,
    required String token,
  }) async {
    if (!_isBindingReady) return;
    try {
      await _storage.write(key: _keyToken, value: token);
      await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
      await _storage.write(key: _keyTimestamp, value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('AuthSessionService.saveSession error: $e');
    }
  }

  /// Retrieve stored user session from secure storage.
  Future<UserModel?> getStoredUser() async {
    if (!_isBindingReady) return null;
    try {
      final token = await _storage.read(key: _keyToken);
      final userJsonStr = await _storage.read(key: _keyUser);

      if (token == null || token.isEmpty || userJsonStr == null || userJsonStr.isEmpty) {
        return null;
      }

      final Map<String, dynamic> userMap = jsonDecode(userJsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      debugPrint('AuthSessionService.getStoredUser error: $e');
      return null;
    }
  }

  /// Retrieve stored auth token.
  Future<String?> getStoredToken() async {
    if (!_isBindingReady) return null;
    try {
      return await _storage.read(key: _keyToken);
    } catch (e) {
      debugPrint('AuthSessionService.getStoredToken error: $e');
      return null;
    }
  }

  /// Check whether an active valid session exists.
  Future<bool> hasValidSession() async {
    try {
      final token = await getStoredToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Securely clear session on explicit logout or session revocation.
  Future<void> clearSession() async {
    if (!_isBindingReady) return;
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
      await _storage.delete(key: _keyTimestamp);
    } catch (e) {
      debugPrint('AuthSessionService.clearSession error: $e');
    }
  }
}
