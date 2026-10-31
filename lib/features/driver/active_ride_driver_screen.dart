import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class ActiveRideDriverScreen extends ConsumerWidget {
  const ActiveRideDriverScreen({super.key});

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openGoogleMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final uri = Uri.parse('${BrandConfig.deepLinkMapsUrl}$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final activeRide = ref.watch(rideRepositoryProvider).activeRide;

    if (activeRide == null) {
      return ResponsiveContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active ride for driver'),
              const SizedBox(height: 12),
              PrimaryButton(text: 'Return to Dashboard', onClick: () => context.go('/driver/home')),
            ],
          ),
        ),
      );
    }

    final isStarted = activeRide.status == RideStatus.rideStarted;

    return ResponsiveContainer(
      appBar: AppBar(
        title: const Text('Active Customer Ride'),
        actions: [
          StatusBadge.fromRideStatus(activeRide.status),
          const SizedBox(width: 16),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Driver Ride Lifecycle Stepper
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync, size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        'Live Status: ${activeRide.status.label}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStepItem(0, 'Assigned', activeRide.status),
                      _buildStepLine(0, activeRide.status),
                      _buildStepItem(1, 'Arriving', activeRide.status),
                      _buildStepLine(1, activeRide.status),
                      _buildStepItem(2, 'Arrived', activeRide.status),
                      _buildStepLine(2, activeRide.status),
                      _buildStepItem(3, 'Started', activeRide.status),
                      _buildStepLine(3, activeRide.status),
                      _buildStepItem(4, 'Complete', activeRide.status),
                    ],
                  ),
                ],
              ),
            ),

            // Customer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activeRide.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(activeRide.customerPhone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: strings.callCustomer,
                          icon: Icons.phone,
                          onClick: () => _makePhoneCall(activeRide.customerPhone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryButton(
                          text: strings.viewLocation,
                          icon: Icons.navigation,
                          onClick: () => _openGoogleMaps(isStarted ? activeRide.destination.address : activeRide.pickup.address),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup Location:', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(activeRide.pickup.placeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Text('Destination Drop:', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(activeRide.destination.placeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  const Text('Sample Trip Distance:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const Text('2.4 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fare to Collect:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '₹${activeRide.suggestedFare.toStringAsFixed(0)} (${activeRide.paymentMethod.label})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Driver Status Control Buttons (Step-by-Step)
            if (activeRide.status == RideStatus.driverAccepted) ...[
              PrimaryButton(
                text: 'Heading to Pickup',
                icon: Icons.directions_car,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).updateRideStatus(RideStatus.driverArriving);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated: Driver Arriving')),
                  );
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                text: 'Arrived at Pickup',
                icon: Icons.pin_drop_rounded,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).updateRideStatus(RideStatus.driverArrived);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated: Driver Arrived at Pickup')),
                  );
                },
              ),
            ] else if (activeRide.status == RideStatus.driverArriving) ...[
              PrimaryButton(
                text: 'Arrived at Pickup',
                icon: Icons.pin_drop_rounded,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).updateRideStatus(RideStatus.driverArrived);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated: Driver Arrived at Pickup')),
                  );
                },
              ),
            ] else if (activeRide.status == RideStatus.driverArrived) ...[
              PrimaryButton(
                text: strings.startRide,
                icon: Icons.play_arrow,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).updateRideStatus(RideStatus.rideStarted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated: Ride Started')),
                  );
                },
              ),
            ] else if (activeRide.status == RideStatus.rideStarted) ...[
              PrimaryButton(
                text: strings.completeRide,
                icon: Icons.check_circle,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).completeActiveRide();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride completed successfully!')),
                  );
                },
              ),
            ] else ...[
              PrimaryButton(
                text: 'Return to Dashboard',
                icon: Icons.dashboard,
                onClick: () => context.go('/driver/home'),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int _getDriverStepIndex(RideStatus status) {
    switch (status) {
      case RideStatus.searching:
        return -1;
      case RideStatus.driverAccepted:
        return 0;
      case RideStatus.driverArriving:
        return 1;
      case RideStatus.driverArrived:
        return 2;
      case RideStatus.rideStarted:
        return 3;
      case RideStatus.rideCompleted:
        return 4;
      case RideStatus.cancelled:
        return -1;
    }
  }

  Widget _buildStepItem(int stepIndex, String title, RideStatus status) {
    final current = _getDriverStepIndex(status);
    final isPassed = current >= 0 && stepIndex < current;
    final isCurrent = current >= 0 && stepIndex == current;

    final circleBg = isPassed
        ? AppColors.success
        : (isCurrent ? BrandConfig.accentYellow : const Color(0xFFF1F3F5));
    final circleBorder = isPassed
        ? AppColors.success
        : (isCurrent ? BrandConfig.textPrimaryBlack : const Color(0xFFCED4DA));

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: Border.all(color: circleBorder, width: isCurrent ? 2 : 1.5),
          ),
          child: Center(
            child: isPassed
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : (isCurrent
                    ? const Icon(Icons.radio_button_checked, size: 12, color: BrandConfig.textPrimaryBlack)
                    : Text(
                        '${stepIndex + 1}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      )),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? BrandConfig.textPrimaryBlack : (isPassed ? AppColors.success : AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int leftIndex, RideStatus status) {
    final current = _getDriverStepIndex(status);
    final isPassed = current >= 0 && leftIndex < current;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isPassed ? AppColors.success : const Color(0xFFDEE2E6),
      ),
    );
  }
}
