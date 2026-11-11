import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/session/session_manager.dart';
import '../../core/services/local_notification_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final settings = ref.watch(notificationSettingsProvider);
    final settingsNotifier = ref.read(notificationSettingsProvider.notifier);

    return ResponsiveContainer(
      appBar: AppBar(
        title: Text(strings.notificationSettings),
        centerTitle: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DharRide Notification Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandConfig.accentYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: BrandConfig.accentYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: BrandConfig.textPrimaryBlack,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMr ? 'धाराशिव सूचना केंद्र' : 'Dharashiv Notification Hub',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: BrandConfig.textPrimaryBlack,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isMr
                              ? 'महत्त्वाच्या राइड अपडेट्स आणि बुकिंग सूचना तुमच्या पसंतीनुसार नियंत्रित करा.'
                              : 'Customize alerts for ride progress, arrival, and local auto bookings.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Ride & Trip Updates
            _buildSectionHeader(
              title: isMr ? 'प्रवास आणि बुकिंग सूचना' : 'Ride & Booking Alerts',
              icon: Icons.alt_route_rounded,
            ),
            const SizedBox(height: 10),
            _buildSettingsCard(
              children: [
                _buildSwitchTile(
                  title: strings.rideUpdates,
                  subtitle: strings.rideUpdatesDesc,
                  value: settings.rideUpdates,
                  icon: Icons.directions_car_rounded,
                  onChanged: (val) => settingsNotifier.toggleRideUpdates(val),
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  title: strings.bookingAlerts,
                  subtitle: strings.bookingAlertsDesc,
                  value: settings.bookingAlerts,
                  icon: Icons.calendar_month_rounded,
                  onChanged: (val) => settingsNotifier.toggleBookingAlerts(val),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 2: Sound and Haptics
            _buildSectionHeader(
              title: isMr ? 'आवाज आणि कंपन' : 'Sounds & Haptics',
              icon: Icons.volume_up_rounded,
            ),
            const SizedBox(height: 10),
            _buildSettingsCard(
              children: [
                _buildSwitchTile(
                  title: strings.notificationSounds,
                  subtitle: strings.notificationSoundsDesc,
                  value: settings.notificationSounds,
                  icon: Icons.music_note_rounded,
                  onChanged: (val) => settingsNotifier.toggleNotificationSounds(val),
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  title: strings.vibrationAlerts,
                  subtitle: strings.vibrationAlertsDesc,
                  value: settings.vibration,
                  icon: Icons.vibration_rounded,
                  onChanged: (val) => settingsNotifier.toggleVibration(val),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 3: Platform Announcements
            _buildSectionHeader(
              title: isMr ? 'सिस्टम व स्थानिक घोषणा' : 'System & Platform Announcements',
              icon: Icons.campaign_rounded,
            ),
            const SizedBox(height: 10),
            _buildSettingsCard(
              children: [
                _buildSwitchTile(
                  title: strings.promotionalAndSystem,
                  subtitle: strings.promotionalAndSystemDesc,
                  value: settings.promotionalAlerts,
                  icon: Icons.info_outline_rounded,
                  onChanged: (val) => settingsNotifier.togglePromotionalAlerts(val),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Testing / Simulation Controls Card
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
                      const Icon(Icons.touch_app_outlined, size: 18, color: BrandConfig.textPrimaryBlack),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMr ? 'सूचना चाचणी व पूर्वावलोकन' : 'Notification Preview & Simulation',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMr
                        ? 'नवीन सूचना कशी दिसेल ते तपासण्यासाठी त्वरित चाचणी सूचना पाठवा किंवा डेमो डेटा रीसेट करा.'
                        : 'Simulate a live notification event to preview frontend interactions and banners.',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandConfig.textPrimaryBlack,
                            side: const BorderSide(color: BrandConfig.accentYellowDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final newNotif = NotificationModel(
                              id: 'notif_sim_${DateTime.now().millisecondsSinceEpoch}',
                              type: NotificationType.driverArriving,
                              category: NotificationCategory.rides,
                              titleEn: 'Driver Approaching Pickup',
                              titleMr: 'चालक पिकअप स्थानाजवळ येत आहे',
                              bodyEn: 'Ramesh Shinde (MH-25-AZ-4589) is now 1 minute away from Bus Stand.',
                              bodyMr: 'रमेश शिंदे (MH-25-AZ-4589) आता बस स्थानकापासून १ मिनिट अंतरावर आहेत.',
                              timestamp: 'Just now',
                              isRead: false,
                              rideId: 'RIDE-9021',
                              driverName: 'Ramesh Shinde',
                              autoNumber: 'MH-25-AZ-4589',
                              distance: '0.5 km away',
                              eta: 'ETA: 1 min',
                              actionLabelEn: 'Track Auto',
                              actionLabelMr: 'ट्रॅक करा',
                            );
                            ref.read(notificationRepositoryProvider.notifier).addNotification(newNotif);
                            ref.read(localNotificationServiceProvider).showNotificationForModel(
                                  newNotif,
                                  isMr: isMr,
                                  playSound: settings.notificationSounds,
                                  enableVibration: settings.vibration,
                                );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: BrandConfig.accentYellow, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(strings.testNotificationSent)),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_alert_rounded, size: 16),
                          label: Text(
                            strings.simulateNotification,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandConfig.textPrimaryBlack,
                            side: const BorderSide(color: BrandConfig.accentYellowDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(localNotificationServiceProvider).openNotificationSettings();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: Text(
                            isMr ? 'फोन ॲप सूचना सेटिंग्ज उघडा' : 'Device App Notification Settings',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(notificationRepositoryProvider.notifier).resetToMockData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMr ? 'डेमो सूचना रीसेट केल्या!' : 'Demo notifications reset!',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: Text(
                            strings.resetMockNotifications,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: BrandConfig.textPrimaryBlack),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BrandConfig.textPrimaryBlack,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? BrandConfig.accentYellow.withOpacity(0.2) : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? BrandConfig.textPrimaryBlack : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: BrandConfig.textPrimaryBlack,
            activeTrackColor: BrandConfig.accentYellow,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD6D8DB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
