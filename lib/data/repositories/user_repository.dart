import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../demo/demo_data.dart';

class UserRepositoryNotifier extends Notifier<List<UserModel>> {
  @override
  List<UserModel> build() {
    return [
      DemoData.demoCustomer,
      DemoData.demoCustomer2,
      DemoData.demoDriverUser,
      DemoData.demoDriverUser2,
      DemoData.demoAdmin,
    ];
  }

  UserModel? login(String emailOrPhone, UserRole role) {
    final clean = emailOrPhone.trim();
    if (clean.isNotEmpty) {
      for (final u in state) {
        if ((u.phone == clean || u.email == clean) && u.role == role) {
          return u;
        }
      }
    }
    // Fallback: first user matching role
    try {
      return state.firstWhere((u) => u.role == role);
    } catch (_) {
      return null;
    }
  }

  /// Lookup an existing user strictly by mobile phone number without client-supplied role.
  UserModel? getUserByPhone(String phone) {
    final clean = phone.trim().replaceAll('+91', '').replaceAll(' ', '').replaceAll('-', '');
    if (clean.isEmpty) return null;
    for (final u in state) {
      final userPhone = u.phone.trim().replaceAll('+91', '').replaceAll(' ', '').replaceAll('-', '');
      if (userPhone == clean) {
        return u;
      }
    }
    return null;
  }

  /// Register a new customer with minimal required fields (Name + Language preference).
  UserModel registerCustomer({
    required String name,
    required String phone,
    AppLanguage language = AppLanguage.english,
  }) {
    final cleanPhone = phone.trim().replaceAll('+91', '').replaceAll(' ', '').replaceAll('-', '');
    final newUser = UserModel(
      id: 'usr_cust_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isNotEmpty ? name.trim() : 'Customer',
      phone: cleanPhone.isNotEmpty ? cleanPhone : '9800000000',
      role: UserRole.customer,
      language: language,
    );
    state = [newUser, ...state];
    return newUser;
  }

  UserModel register({
    required String name,
    required String phone,
    String? email,
    required UserRole role,
  }) {
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isNotEmpty ? name : 'New User',
      phone: phone.isNotEmpty ? phone : '9800000000',
      email: email,
      role: role,
    );
    state = [newUser, ...state];
    return newUser;
  }

  void toggleSuspension(String userId) {
    state = state.map((u) {
      if (u.id == userId) {
        return u.copyWith(isSuspended: !u.isSuspended);
      }
      return u;
    }).toList();
  }
}

final userRepositoryProvider = NotifierProvider<UserRepositoryNotifier, List<UserModel>>(UserRepositoryNotifier.new);
