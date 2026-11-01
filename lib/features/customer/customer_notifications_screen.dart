import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';
import '../notifications/widgets/notification_card.dart';

class CustomerNotificationsScreen extends ConsumerWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final notifState = ref.watch(notificationRepositoryProvider);
    final notifNotifier = ref.read(notificationRepositoryProvider.notifier);
    final user = ref.watch(currentUserProvider);

    final filteredList = notifState.filteredNotifications;
    final unreadCount = notifState.unreadCount;

    return ResponsiveContainer(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                strings.tabNotifications,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: BrandConfig.accentYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BrandConfig.textPrimaryBlack, width: 1.2),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: false,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, size: 22),
              tooltip: strings.markAllAsRead,
              onPressed: () {
                notifNotifier.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.markedAllAsReadMessage),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            tooltip: strings.notificationSettings,
            onPressed: () {
              context.push('/notifications/settings');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'clear_all') {
                _showClearAllDialog(context, ref);
              } else if (val == 'mark_read') {
                notifNotifier.markAllAsRead();
              } else if (val == 'reset') {
                notifNotifier.resetToMockData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMr ? 'डेमो सूचना रीसेट केल्या!' : 'Demo notifications restored!'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(strings.markAllAsRead),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(strings.clearAllNotifications, style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.restart_alt_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(strings.resetMockNotifications),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: Column(
        children: [
          // Category Filter Tabs
          _buildFilterTabs(context, ref, notifState),

          // Main Notifications List or Empty State
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(context, ref, notifState.activeFilter)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = filteredList[index];
                      return NotificationCard(
                        notification: notif,
                        isMr: isMr,
                        onTap: () => _handleNotificationTap(context, ref, notif, user?.role),
                        onDismiss: () {
                          notifNotifier.clearNotification(notif.id);
                        },
                        onMarkAsRead: () {
                          notifNotifier.markAsRead(notif.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    WidgetRef ref,
    NotificationRepositoryState state,
  ) {
    final strings = ref.watch(stringsProvider);
    final notifier = ref.read(notificationRepositoryProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: strings.filterAll,
              count: state.allCount,
              isSelected: state.activeFilter == NotificationCategory.all,
              hasUnread: state.unreadCount > 0,
              onTap: () => notifier.setFilter(NotificationCategory.all),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: strings.filterRides,
              count: state.ridesCount,
              isSelected: state.activeFilter == NotificationCategory.rides,
              hasUnread: state.unreadRidesCount > 0,
              onTap: () => notifier.setFilter(NotificationCategory.rides),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: strings.filterAlerts,
              count: state.alertsCount,
              isSelected: state.activeFilter == NotificationCategory.alerts,
              hasUnread: state.unreadAlertsCount > 0,
              onTap: () => notifier.setFilter(NotificationCategory.alerts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellow : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BrandConfig.accentYellow.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? BrandConfig.textPrimaryBlack : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? BrandConfig.textPrimaryBlack
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? BrandConfig.accentYellow : AppColors.textMuted,
                ),
              ),
            ),
            if (hasUnread && !isSelected) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: BrandConfig.accentYellowDark,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    NotificationCategory activeFilter,
  ) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final notifier = ref.read(notificationRepositoryProvider.notifier);

    IconData emptyIcon;
    String emptyTitle;
    String emptySubtitle;

    switch (activeFilter) {
      case NotificationCategory.rides:
        emptyIcon = Icons.directions_car_outlined;
        emptyTitle = isMr ? 'कोणतीही राइड सूचना नाही' : 'No Ride Notifications';
        emptySubtitle = isMr
            ? 'नवीन राइड्स किंवा ड्रायव्हर अपडेट्स येथे दिसतील.'
            : 'Ride tracking and driver arrival updates will appear here.';
        break;
      case NotificationCategory.alerts:
        emptyIcon = Icons.campaign_outlined;
        emptyTitle = isMr ? 'कोणतेही इशारे नाहीत' : 'No Alerts';
        emptySubtitle = isMr
            ? 'धाराशिव सेवा घोषणा आणि ०% कमिशन अपडेट्स येथे दिसतील.'
            : 'Dharashiv announcements and zero-commission updates will appear here.';
        break;
      case NotificationCategory.all:
        emptyIcon = Icons.notifications_none_rounded;
        emptyTitle = strings.noNotificationsYet;
        emptySubtitle = isMr
            ? 'तुमच्याकडे सध्या कोणतीही सूचना नाही.'
            : 'You are all caught up! No notifications to review right now.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: BrandConfig.accentYellow.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.4)),
              ),
              child: Center(
                child: Icon(emptyIcon, size: 36, color: BrandConfig.textPrimaryBlack),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              emptyTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandConfig.textPrimaryBlack,
                side: const BorderSide(color: BrandConfig.accentYellowDark, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
              onPressed: () {
                notifier.resetToMockData();
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(
                strings.resetMockNotifications,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    UserRole? role,
  ) {
    // 1. Mark as read
    ref.read(notificationRepositoryProvider.notifier).markAsRead(notification.id);

    // 2. Route based on notification type and ride context
    switch (notification.type) {
      case NotificationType.newRideRequest:
        if (role == UserRole.driver) {
          context.push('/driver/home');
        } else {
          context.push('/customer/searching');
        }
        break;

      case NotificationType.rideAccepted:
      case NotificationType.driverArriving:
      case NotificationType.driverArrived:
      case NotificationType.rideStarted:
        if (role == UserRole.driver) {
          context.push('/driver/active-ride');
        } else {
          context.push('/customer/active-ride');
        }
        break;

      case NotificationType.rideCompleted:
      case NotificationType.rideCancelled:
        final allRides = ref.read(rideRepositoryProvider).rides;
        final matchedRide = allRides.firstWhere(
          (r) => r.id == notification.rideId,
          orElse: () => DemoData.initialRides.first,
        );
        context.push('/ride-detail', extra: matchedRide);
        break;

      case NotificationType.systemAlert:
      case NotificationType.announcement:
        _showAlertDetailsModal(context, ref, notification);
        break;
    }
  }

  void _showAlertDetailsModal(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BrandConfig.accentYellow.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: BrandConfig.textPrimaryBlack,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: BrandConfig.accentYellowLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isMr ? 'धाराशिव अधिकृत सूचना' : 'Dharashiv Official Alert',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8A5300),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.timestamp,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notification.getTitle(isMr),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  notification.getBody(isMr),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const AutoRickshawIcon(size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMr
                              ? 'DharRide: धाराशिव शहराचे स्वतःचे रिक्षा नेटवर्क • ०% कमिशन'
                              : 'DharRide: Dharashiv City Platform • 0% Commission',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BrandConfig.textPrimaryBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandConfig.accentYellow,
                      foregroundColor: BrandConfig.textPrimaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isMr ? 'समजले / बंद करा' : 'Got it / Dismiss',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(strings.clearNotificationsTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Text(
            strings.clearNotificationsDesc,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(notificationRepositoryProvider.notifier).clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.notificationsClearedMessage),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                isMr ? 'साफ करा' : 'Clear All',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
