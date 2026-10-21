import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/demo/demo_data.dart';
import '../../data/session/session_manager.dart';

class CustomerNotificationsScreen extends ConsumerWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final notifications = DemoData.demoNotifications;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabNotifications)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif.getTitle(isMr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(notif.getBody(isMr), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text(notif.timestamp, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
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
