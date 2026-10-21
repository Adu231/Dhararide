import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class CustomerRidesScreen extends ConsumerWidget {
  const CustomerRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final rides = ref.watch(rideRepositoryProvider).rides;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabRides)),
      body: rides.isEmpty
          ? const Center(child: Text('No ride history found.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: rides.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ride = rides[index];
                return InkWell(
                  onTap: () => context.push('/ride-detail', extra: ride),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ride.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                            StatusBadge.fromRideStatus(ride.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.my_location, size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ride.pickup.placeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ride.destination.placeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ride.createdAt, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('₹${ride.finalFare?.toStringAsFixed(0) ?? '20'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
