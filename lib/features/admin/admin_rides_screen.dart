import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class AdminRidesScreen extends ConsumerWidget {
  const AdminRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final rides = ref.watch(rideRepositoryProvider).rides;

    return ResponsiveContainer(
      appBar: AppBar(title: Text(strings.rideManagement)),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: rides.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ride = rides[index];
          return InkWell(
            onTap: () => context.push('/ride-detail', extra: ride),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ride.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      StatusBadge.fromRideStatus(ride.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${ride.customerName} → ${ride.driverName ?? 'Searching...'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${ride.pickup.placeName} to ${ride.destination.placeName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ride.createdAt, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text('₹${ride.suggestedFare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
