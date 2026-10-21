import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/h3_service.dart';
import '../models/driver_model.dart';
import '../models/enums.dart';
import '../demo/demo_data.dart';

final h3ServiceProvider = Provider<H3Service>((ref) {
  return H3Service();
});

class DriverRepositoryNotifier extends Notifier<List<DriverModel>> {
  @override
  List<DriverModel> build() {
    final h3 = ref.watch(h3ServiceProvider);
    final initialDrivers = [
      DemoData.demoDriver,
      DemoData.demoDriver2,
      DemoData.demoDriver3,
      DemoData.demoPendingDriver,
    ];

    // Compute initial H3 cell index for drivers with coordinates
    return initialDrivers.map((d) {
      if (d.currentLatitude != null && d.currentLongitude != null) {
        final cell = h3.geoToCell(d.currentLatitude!, d.currentLongitude!);
        return d.copyWith(h3Index: cell);
      }
      return d;
    }).toList();
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

  void updateDriverLocation(String driverId, double lat, double lon) {
    final h3 = ref.read(h3ServiceProvider);
    final cell = h3.geoToCell(lat, lon);

    state = state.map((d) {
      if (d.id == driverId) {
        return d.copyWith(
          currentLatitude: lat,
          currentLongitude: lon,
          lastLocationUpdate: DateTime.now(),
          h3Index: cell,
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

