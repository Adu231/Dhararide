import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/session/session_manager.dart';

class AdminComplaintsScreen extends ConsumerWidget {
  const AdminComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final complaints = ref.watch(adminRepositoryProvider).complaints;

    return ResponsiveContainer(
      appBar: AppBar(title: Text(strings.complaintsManagement)),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: complaints.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cmp = complaints[index];
          final isResolved = cmp.status == ComplaintStatus.resolved;

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
                    Text(cmp.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isResolved ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cmp.status.label,
                        style: TextStyle(
                          color: isResolved ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('User: ${cmp.userName} (${cmp.userRole.displayName})', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(cmp.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(isResolved ? Icons.check_circle : Icons.done, size: 16),
                    label: Text(isResolved ? 'Resolved' : 'Mark Resolved'),
                    onPressed: isResolved
                        ? null
                        : () {
                            ref.read(adminRepositoryProvider.notifier).updateComplaintStatus(cmp.id, ComplaintStatus.resolved, 'Resolved by admin.');
                          },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
