import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../demo/demo_data.dart';

class RideRepositoryState {
  final List<RideModel> rides;
  final RideModel? activeRide;

  const RideRepositoryState({
    required this.rides,
    this.activeRide,
  });

  RideRepositoryState copyWith({
    List<RideModel>? rides,
    RideModel? activeRide,
    bool clearActiveRide = false,
  }) {
    return RideRepositoryState(
      rides: rides ?? this.rides,
      activeRide: clearActiveRide ? null : (activeRide ?? this.activeRide),
    );
  }
}

class RideRepositoryNotifier extends Notifier<RideRepositoryState> {
  @override
  RideRepositoryState build() {
    return RideRepositoryState(rides: DemoData.initialRides, activeRide: null);
  }

  RideModel createRideRequest({
    required UserModel customer,
    required LocationPointModel pickup,
    required LocationPointModel destination,
    double suggestedFare = 20.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) {
    final newId = 'RIDE-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newRide = RideModel(
      id: newId,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      pickup: pickup,
      destination: destination,
      suggestedFare: suggestedFare,
      finalFare: suggestedFare,
      status: RideStatus.searching,
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.pending,
      createdAt: 'Just now',
    );

    state = state.copyWith(
      rides: [newRide, ...state.rides],
      activeRide: newRide,
    );
    return newRide;
  }

  void driverAcceptRide(String rideId, DriverModel driver) {
    final active = state.activeRide;
    if (active != null && active.id == rideId) {
      final updated = active.copyWith(
        driverId: driver.id,
        driverName: driver.name,
        driverPhone: driver.phone,
        autoNumber: driver.autoNumber,
        driverRating: driver.rating,
        driverUpiId: driver.upiId,
        status: RideStatus.driverAccepted,
        acceptedAt: 'Just now',
      );
      _updateRide(updated);
    }
  }

  void updateRideStatus(RideStatus status) {
    final active = state.activeRide;
    if (active != null) {
      final updated = active.copyWith(
        status: status,
        completedAt: status == RideStatus.rideCompleted ? 'Just now' : active.completedAt,
      );
      _updateRide(updated);
    }
  }

  void updatePayment(PaymentMethod method, PaymentStatus status, double? finalFare) {
    final active = state.activeRide;
    if (active != null) {
      final updated = active.copyWith(
        paymentMethod: method,
        paymentStatus: status,
        finalFare: finalFare ?? active.finalFare,
      );
      _updateRide(updated);
    }
  }

  void completeActiveRide() {
    updateRideStatus(RideStatus.rideCompleted);
  }

  void cancelActiveRide(String reason) {
    final active = state.activeRide;
    if (active != null) {
      final updated = active.copyWith(
        status: RideStatus.cancelled,
        cancelReason: reason,
      );
      _updateRide(updated);
    }
  }

  void submitRating(String rideId, int stars, String? comment) {
    final updatedList = state.rides.map((r) {
      if (r.id == rideId) {
        return r.copyWith(ratingGiven: stars, ratingComment: comment);
      }
      return r;
    }).toList();

    state = state.copyWith(
      rides: updatedList,
      clearActiveRide: state.activeRide?.id == rideId,
    );
  }

  void clearActiveRide() {
    state = state.copyWith(clearActiveRide: true);
  }

  void _updateRide(RideModel updated) {
    final updatedList = state.rides.map((r) => r.id == updated.id ? updated : r).toList();
    state = state.copyWith(
      rides: updatedList,
      activeRide: updated,
    );
  }
}

final rideRepositoryProvider = NotifierProvider<RideRepositoryNotifier, RideRepositoryState>(RideRepositoryNotifier.new);
