import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../models/enums.dart';
import '../demo/demo_data.dart';

class DriverRepositoryNotifier extends Notifier<List<DriverModel>> {
  @override
  List<DriverModel> build() {
    return [DemoData.demoDriver, DemoData.demoPendingDriver];
  }

  void toggleOnlineStatus(String driverId, bool isOnline) {
    state = state.map((d) {
      if (d.id == driverId) {
        return d.copyWith(
          availability: isOnline ? DriverAvailability.online : DriverAvailability.offline,
        );
      }
      return d;
    }).toList();
  }

  void updateVerificationStatus(String driverId, DriverVerificationStatus status) {
    state = state.map((d) {
      if (d.id == driverId) {
        return d.copyWith(verificationStatus: status);
      }
      return d;
    }).toList();
  }

  DriverModel registerDriver({
    required String userId,
    required String name,
    required String phone,
    required String autoNumber,
    required String upiId,
  }) {
    final newDriver = DriverModel(
      id: 'drv_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      phone: phone,
      autoNumber: autoNumber.isNotEmpty ? autoNumber : 'MH-25-XX-0000',
      upiId: upiId.isNotEmpty ? upiId : 'driver@upi',
      verificationStatus: DriverVerificationStatus.pending,
    );
    state = [newDriver, ...state];
    return newDriver;
  }
}

final driverRepositoryProvider = NotifierProvider<DriverRepositoryNotifier, List<DriverModel>>(DriverRepositoryNotifier.new);
