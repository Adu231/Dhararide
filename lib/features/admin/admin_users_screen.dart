import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/session/session_manager.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final users = ref.watch(userRepositoryProvider);

    return ResponsiveContainer(
      appBar: AppBar(title: Text(strings.userManagement)),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(user.name.isNotEmpty ? user.name[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${user.phone} • ${user.role.displayName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(userRepositoryProvider.notifier).toggleSuspension(user.id);
                  },
                  child: Text(
                    user.isSuspended ? 'Activate' : 'Suspend',
                    style: TextStyle(color: user.isSuspended ? AppColors.success : AppColors.error),
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
