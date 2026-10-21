import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../demo/demo_data.dart';

class UserRepositoryNotifier extends Notifier<List<UserModel>> {
  @override
  List<UserModel> build() {
    return [DemoData.demoCustomer, DemoData.demoDriverUser, DemoData.demoAdmin];
  }

  UserModel? login(String emailOrPhone, UserRole role) {
    return state.firstWhere(
      (u) => (u.phone == emailOrPhone || u.email == emailOrPhone) && u.role == role,
      orElse: () => state.firstWhere((u) => u.role == role),
    );
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
