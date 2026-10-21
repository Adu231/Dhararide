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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
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
            const Spacer(),

            if (!isStarted) ...[
              PrimaryButton(
                text: strings.startRide,
                icon: Icons.play_arrow,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).updateRideStatus(RideStatus.rideStarted);
                },
              ),
            ] else ...[
              PrimaryButton(
                text: strings.completeRide,
                icon: Icons.check_circle,
                onClick: () {
                  ref.read(rideRepositoryProvider.notifier).completeActiveRide();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ride completed successfully! ₹20 received.')),
                  );
                  context.go('/driver/home');
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
