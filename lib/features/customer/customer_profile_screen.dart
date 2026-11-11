import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider) ?? DemoData.demoCustomer;
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final activeLang = ref.watch(languageProvider);

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(strings.tabProfile),
        centerTitle: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Avatar & Identity Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: BrandConfig.accentYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: BrandConfig.textPrimaryBlack, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: BrandConfig.textPrimaryBlack,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BrandConfig.accentYellow),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user, size: 14, color: BrandConfig.textPrimaryBlack),
                        const SizedBox(width: 4),
                        Text(
                          isMr ? 'सत्यापित ग्राहक' : 'Verified Customer',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: BrandConfig.textPrimaryBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Saved Locations Card (Quick 1-Tap Booking)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bookmark_outline_rounded, size: 18, color: BrandConfig.textPrimaryBlack),
                      const SizedBox(width: 8),
                      Text(
                        isMr ? 'जतन केलेली ठिकाणे (Saved Locations)' : 'Saved Locations',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSavedLocationTile(
                    icon: Icons.home_outlined,
                    title: isMr ? 'घर (Home)' : 'Home',
                    address: DemoData.popularPlaces[0].nameEn,
                    onTap: () => context.go('/customer/home'),
                  ),
                  const Divider(height: 12),
                  _buildSavedLocationTile(
                    icon: Icons.work_outline,
                    title: isMr ? 'कार्यालय / कॉलेज (Work)' : 'Work / College',
                    address: DemoData.popularPlaces[2].nameEn,
                    onTap: () => context.go('/customer/home'),
                  ),
                  const Divider(height: 12),
                  _buildSavedLocationTile(
                    icon: Icons.train_outlined,
                    title: isMr ? 'रेल्वे स्टेशन (Station)' : 'Railway Station',
                    address: DemoData.popularPlaces[1].nameEn,
                    onTap: () => context.go('/customer/home'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Language Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        strings.languageSettings,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLangTile(
                          title: 'मराठी',
                          subtitle: 'Marathi',
                          isSelected: activeLang == AppLanguage.marathi,
                          onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.marathi),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLangTile(
                          title: 'English',
                          subtitle: 'इंग्रजी',
                          isSelected: activeLang == AppLanguage.english,
                          onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.english),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods & 0% Commission Policy Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? 'पेमेंट आणि धाराशिव धोरण' : 'Payment & Dharashiv Policy',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.success),
                    ),
                    title: Text(
                      isMr ? '०% प्लॅटफॉर्म कमिशन' : '0% Platform Commission',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      isMr
                          ? 'ग्राहक आणि स्थानिक ऑटो चालक यांच्यात थेट व्यवहार. कोणतेही छुपे शुल्क नाही.'
                          : '100% of the fare goes directly to the local auto driver. No hidden cuts.',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined, size: 20),
                    title: Text(
                      isMr ? 'सूचना सेटिंग्ज' : 'Notification Settings',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/notifications/settings'),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BrandConfig.accentYellow.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk, size: 18, color: BrandConfig.textPrimaryBlack),
                    ),
                    title: const Text(
                      BrandConfig.supportPhone,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      isMr ? 'धाराशिव हेल्पलाइन व ग्राहक मदत कक्ष' : 'Dharashiv Direct Customer Helpline',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ref.read(currentUserProvider.notifier).logout();
                  ref.read(currentDriverProvider.notifier).setDriver(null);
                  ref.read(rideRepositoryProvider.notifier).clearActiveRide();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                label: Text(
                  strings.logout,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLocationTile({
    required IconData icon,
    required String title,
    required String address,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildLangTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellowLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13.5,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
