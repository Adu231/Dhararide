import 'package:flutter/material.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/ride_model.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(ride.id),
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
              ),
              child: Column(
                children: [
                  const AutoRickshawIcon(size: 54),
                  const SizedBox(height: 12),
                  const Text('Dharashiv Auto Ride Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(ride.createdAt, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Agreed Fare', style: TextStyle(color: AppColors.textSecondary)),
                      Text('₹${ride.finalFare?.toStringAsFixed(0) ?? '20'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const Text('₹0.00 (0% Commission)', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  const Text('Trip Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(ride.pickup.placeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(ride.destination.placeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Driver & Customer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person, color: AppColors.textPrimary),
                    title: Text(ride.driverName ?? 'Ramesh Shinde'),
                    subtitle: Text('Auto: ${ride.autoNumber ?? 'MH-25-AZ-4589'} • ${ride.driverPhone ?? '+91 94220 54321'}'),
                  ),
                  const Divider(),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                    title: Text(ride.customerName),
                    subtitle: Text(ride.customerPhone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
