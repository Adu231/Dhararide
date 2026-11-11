import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/ride_model.dart';
import '../../data/session/session_manager.dart';

class RideDetailScreen extends ConsumerWidget {
  final RideModel ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final isDriver = user?.role == UserRole.driver;

    final fare = (ride.finalFare ?? ride.suggestedFare).toStringAsFixed(0);

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text('${isMr ? 'प्रवास तपशील' : 'Ride Details'} • ${ride.id}'),
        actions: [
          StatusBadge.fromRideStatus(ride.status),
          const SizedBox(width: 16),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Receipt Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const AutoRickshawIcon(size: 50),
                  const SizedBox(height: 10),
                  Text(
                    isMr ? 'धाराशिव ऑटो प्रवास पावती' : 'Dharashiv Auto Ride Receipt',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(ride.createdAt, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDriver
                            ? (isMr ? 'चालक कमाई (१००% थेट)' : 'Driver Earnings (100% Direct)')
                            : (isMr ? 'एकूण ठरलेले भाडे' : 'Total Agreed Fare'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text('₹$fare', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'प्लॅटफॉर्म कमिशन' : 'Platform Fee',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                      const Text(
                        '₹0.00 (0% Commission)',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'पेमेंट पद्धत' : 'Payment Method',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                      Text(
                        ride.paymentMethod == PaymentMethod.cash ? 'Cash' : 'Online UPI',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
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
                  Text(
                    isMr ? 'प्रवास मार्ग' : 'Trip Route',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ride.pickup.placeName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ride.destination.placeName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Role-Aware Party Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Driver Info (shown to customer and admin)
                  if (!isDriver) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.electric_rickshaw, color: BrandConfig.textPrimaryBlack),
                      title: Text(ride.driverName ?? (isMr ? 'ऑटो चालक' : 'Auto Driver'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Auto: ${ride.autoNumber ?? 'MH-25-AZ-4589'} • Phone: ${ride.driverPhone ?? '+91 94220 54321'}'),
                    ),
                    if (user?.role == UserRole.admin) const Divider(),
                  ],
                  // Passenger Info (shown to driver and admin)
                  if (isDriver || user?.role == UserRole.admin) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person, color: BrandConfig.textPrimaryBlack),
                      title: Text('${isMr ? 'प्रवासी: ' : 'Passenger: '}${ride.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Phone: ${ride.customerPhone}'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
