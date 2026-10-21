import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class ActiveRideCustomerScreen extends ConsumerWidget {
  const ActiveRideCustomerScreen({super.key});

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
              const Text('No active ride found'),
              const SizedBox(height: 12),
              PrimaryButton(text: 'Return Home', onClick: () => context.go('/customer/home')),
            ],
          ),
        ),
      );
    }

    return ResponsiveContainer(
      appBar: AppBar(
        title: const Text('Live Ride'),
        actions: [
          StatusBadge.fromRideStatus(activeRide.status),
          const SizedBox(width: 16),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Driver Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, size: 30, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeRide.driverName ?? 'Ramesh Shinde',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeRide.autoNumber ?? 'MH-25-AZ-4589',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  '${activeRide.driverRating} ★',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: strings.callDriver,
                          icon: Icons.phone,
                          onClick: () => _makePhoneCall(activeRide.driverPhone ?? BrandConfig.supportPhone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryButton(
                          text: 'Map',
                          icon: Icons.map,
                          onClick: () => _openGoogleMaps(activeRide.pickup.address),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(activeRide.pickup.placeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(activeRide.destination.placeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(strings.finalFare, style: const TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '₹${activeRide.finalFare?.toStringAsFixed(0) ?? '20'}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),

            PrimaryButton(
              text: 'Complete & Proceed to Payment',
              icon: Icons.payment,
              onClick: () {
                ref.read(rideRepositoryProvider.notifier).completeActiveRide();
                context.push('/customer/payment');
              },
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              text: strings.cancelRide,
              onClick: () {
                ref.read(rideRepositoryProvider.notifier).cancelActiveRide('Customer cancelled');
                context.go('/customer/home');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
