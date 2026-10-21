import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/session/session_manager.dart';

class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final drivers = ref.watch(driverRepositoryProvider);

    return ResponsiveContainer(
      appBar: AppBar(title: Text(strings.driverManagement)),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: drivers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final isPending = driver.verificationStatus == DriverVerificationStatus.pending;

          return Container(
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
                    Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.warning.withOpacity(0.2) : AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        driver.verificationStatus.label,
                        style: TextStyle(
                          color: isPending ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Auto: ${driver.autoNumber} • UPI: ${driver.upiId}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('Phone: ${driver.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const Divider(height: 20),
                Row(
                  children: [
                    if (isPending) ...[
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                          onPressed: () {
                            ref.read(driverRepositoryProvider.notifier).updateVerificationStatus(driver.id, DriverVerificationStatus.approved);
                          },
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(driverRepositoryProvider.notifier).updateVerificationStatus(driver.id, DriverVerificationStatus.rejected);
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(driverRepositoryProvider.notifier).updateVerificationStatus(driver.id, DriverVerificationStatus.suspended);
                          },
                          child: const Text('Suspend'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
