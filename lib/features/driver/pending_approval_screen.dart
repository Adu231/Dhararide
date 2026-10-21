import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/session/session_manager.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return ResponsiveContainer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AutoRickshawIcon(size: 80, badgeColor: AppColors.warning),
              const SizedBox(height: 24),
              Text(
                strings.verificationPending,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                strings.verificationPendingDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                text: 'Refresh Status',
                onClick: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking verification status...')),
                  );
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: strings.logout,
                onClick: () {
                  ref.read(currentUserProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
