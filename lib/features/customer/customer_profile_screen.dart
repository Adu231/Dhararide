import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../data/models/enums.dart';
import '../../data/session/session_manager.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final strings = ref.watch(stringsProvider);
    final activeLang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Avatar card
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 40, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Aditya Patil', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user?.phone ?? '+91 98220 12345', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(user?.role.displayName ?? 'Customer', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Language Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.languageSettings, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('English'),
                          selected: activeLang == AppLanguage.english,
                          selectedColor: AppColors.primary,
                          onSelected: (val) => ref.read(languageProvider.notifier).setLanguage(AppLanguage.english),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('मराठी (Marathi)'),
                          selected: activeLang == AppLanguage.marathi,
                          selectedColor: AppColors.primary,
                          onSelected: (val) => ref.read(languageProvider.notifier).setLanguage(AppLanguage.marathi),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Support & Policy Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support & Platform Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  const ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.phone_outlined, size: 20),
                    title: Text(BrandConfig.supportPhone),
                    subtitle: Text('Direct Helpline (Dharashiv)'),
                  ),
                  const ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.shield_outlined, size: 20),
                    title: Text('0% Platform Commission'),
                    subtitle: Text('All payments directly between customer and auto driver'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SecondaryButton(
              text: strings.logout,
              icon: Icons.logout,
              borderColor: AppColors.error.withOpacity(0.5),
              onClick: () {
                ref.read(currentUserProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
