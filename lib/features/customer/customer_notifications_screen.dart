import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/brand/brand_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auto_rickshaw_icon.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';
import '../../core/services/local_notification_service.dart';
import '../notifications/widgets/notification_card.dart';

class CustomerNotificationsScreen extends ConsumerStatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  ConsumerState<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends ConsumerState<CustomerNotificationsScreen> {
  UserRole _previewRole = UserRole.customer;
  NotificationType _selectedType = NotificationType.rideAccepted;
  bool _showReferencePreview = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null && mounted) {
        setState(() {
          _previewRole = user.role;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Quick Language Switcher Action in AppBar
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            icon: const Icon(Icons.language_rounded, size: 16, color: BrandConfig.textPrimaryBlack),
            label: Text(
              isMr ? 'मराठी' : 'EN',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
          ),
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
              } else if (val == 'test_all') {
                _triggerTestAllNotifications(context, ref);
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
                value: 'test_all',
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 18, color: BrandConfig.accentYellowDark),
                    const SizedBox(width: 10),
                    Text(strings.testAllNotifications),
                  ],
                ),
              ),
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
          const SizedBox(width: 4),
        ],
      ),
      child: Column(
        children: [
          // Category Filter Tabs
          _buildFilterTabs(context, ref, notifState),

          // Dedicated Local Notification Showcase & Testing Bar with All 7 Types
          _buildTestNotificationsBar(context, ref),

          // Main Notifications Feed
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(context, ref, notifState.activeFilter)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final notif = filteredList[index];
                      return NotificationCard(
                        notification: notif,
                        isMr: isMr,
                        role: user?.role ?? _previewRole,
                        onTap: () => _handleNotificationTap(context, ref, notif, user?.role),
                        onDismiss: () {
                          notifNotifier.clearNotification(notif.id);
                        },
                        onMarkAsRead: () {
                          notifNotifier.markAsRead(notif.id);
                        },
                        onTestNotification: () {
                          _handleTestNotificationAction(
                            context,
                            ref,
                            model: notif,
                            type: notif.type,
                            role: _previewRole,
                          );
                        },
                        onPrimaryAction: () => _handlePrimaryCardAction(context, ref, notif, user?.role),
                        onSecondaryAction: () => _handleSecondaryCardAction(context, ref, notif, user?.role),
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
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandConfig.accentYellow,
                    foregroundColor: BrandConfig.textPrimaryBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                  onPressed: () => _handleTestNotificationAction(
                    context,
                    ref,
                    type: _selectedType,
                    role: _previewRole,
                  ),
                  icon: const Icon(Icons.notifications_active_rounded, size: 16),
                  label: Text(
                    isMr ? 'चाचणी सूचना (Test)' : 'Test Notification',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandConfig.textPrimaryBlack,
                    side: const BorderSide(color: BrandConfig.accentYellowDark, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
          ],
        ),
      ),
    );
  }

  /// Builds a prominent, dedicated showcase section allowing testing and live visual preview
  /// of all 7 DharRide reference notification designs.
  Widget _buildTestNotificationsBar(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;

    const testTypes = [
      NotificationType.newRideRequest,
      NotificationType.rideAccepted,
      NotificationType.driverArriving,
      NotificationType.driverArrived,
      NotificationType.rideStarted,
      NotificationType.rideCompleted,
      NotificationType.rideCancelled,
    ];

    final sampleModel = _getSampleNotificationForType(_selectedType);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: BrandConfig.accentYellow.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Logo Badge, Title, and settings
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: BrandConfig.accentYellow,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  BrandConfig.appLogoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: BrandConfig.textPrimaryBlack,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.testNotificationPreview,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: BrandConfig.textPrimaryBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMr
                          ? 'DharRide संदर्भ सूचना डिझाइन्स (सर्व ७ प्रकार)'
                          : 'DharRide Reference Designs (All 7 Types)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showReferencePreview ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  size: 20,
                  color: BrandConfig.textPrimaryBlack,
                ),
                tooltip: isMr ? 'पूर्वावलोकन दाखवा/लपवा' : 'Toggle Live Preview',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _showReferencePreview = !_showReferencePreview;
                  });
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                tooltip: strings.openAppSettings,
                color: BrandConfig.textPrimaryBlack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => ref.read(localNotificationServiceProvider).openNotificationSettings(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Role Selection row (Customer, Driver, Admin)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  isMr ? 'भूमिका (Role): ' : 'Role: ',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 4),
                _buildRoleChip(UserRole.customer, isMr ? 'ग्राहक' : 'Customer', Icons.person_outline),
                const SizedBox(width: 6),
                _buildRoleChip(UserRole.driver, isMr ? 'चालक' : 'Driver', Icons.electric_rickshaw_outlined),
                const SizedBox(width: 6),
                _buildRoleChip(UserRole.admin, isMr ? 'ॲडमिन' : 'Admin', Icons.shield_outlined),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Horizontal scroll of 7 types
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: testTypes.map((type) {
                final label = _getTypeLabel(type, isMr);
                final icon = _getTypeIcon(type);
                final color = _getTypeColor(type);
                final isSelected = _selectedType == type;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : color.withOpacity(0.4),
                          width: isSelected ? 1.8 : 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: color),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                              color: BrandConfig.textPrimaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // LIVE INTERACTIVE REFERENCE CARD PREVIEW
          if (_showReferencePreview) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(8),
              child: NotificationCard(
                notification: sampleModel,
                isMr: isMr,
                role: _previewRole,
                onTap: () => _handlePrimaryCardAction(context, ref, sampleModel, _previewRole),
                onPrimaryAction: () => _handlePrimaryCardAction(context, ref, sampleModel, _previewRole),
                onSecondaryAction: () => _handleSecondaryCardAction(context, ref, sampleModel, _previewRole),
                onDismiss: () {},
                onMarkAsRead: () {},
                onTestNotification: () => _handleTestNotificationAction(
                  context,
                  ref,
                  type: _selectedType,
                  role: _previewRole,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Buttons Row: Send Actionable Notification (Android OS) & Test All 7
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandConfig.accentYellow,
                    foregroundColor: BrandConfig.textPrimaryBlack,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _handleTestNotificationAction(
                    context,
                    ref,
                    type: _selectedType,
                    role: _previewRole,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: Text(
                    isMr ? 'Android सूचना पाठवा' : 'Send Android Push',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandConfig.textPrimaryBlack,
                    side: const BorderSide(color: BrandConfig.accentYellowDark, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _triggerTestAllNotifications(context, ref),
                  child: Text(
                    isMr ? 'सर्व ७ पाठवा' : 'Test All 7',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon) {
    final isSelected = _previewRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _previewRole = role;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? BrandConfig.accentYellow : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? BrandConfig.accentYellowDark : AppColors.border,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: BrandConfig.textPrimaryBlack),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE CARD ACTION DISPATCHERS
  // ---------------------------------------------------------------------------

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    UserRole? role,
  ) {
    ref.read(notificationRepositoryProvider.notifier).markAsRead(notification.id);

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

  void _handlePrimaryCardAction(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    UserRole? role,
  ) {
    ref.read(notificationRepositoryProvider.notifier).markAsRead(notification.id);
    final isMr = ref.read(stringsProvider).isMr;

    switch (notification.type) {
      case NotificationType.newRideRequest:
        if (role == UserRole.driver) {
          final driver = ref.read(currentDriverProvider) ?? DemoData.demoDriver;
          ref.read(rideRepositoryProvider.notifier).driverAcceptRide(notification.rideId ?? 'RIDE-9021', driver);
          context.push('/driver/active-ride');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMr ? 'राइड स्वीकारली! पिकअप मार्ग उघडत आहे...' : 'Ride accepted! Heading to pickup.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: BrandConfig.textPrimaryBlack,
            ),
          );
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
        final allRides = ref.read(rideRepositoryProvider).rides;
        final matchedRide = allRides.firstWhere(
          (r) => r.id == notification.rideId,
          orElse: () => DemoData.initialRides.first,
        );
        context.push('/ride-detail', extra: matchedRide);
        break;

      case NotificationType.rideCancelled:
        context.go('/customer/home');
        break;

      case NotificationType.systemAlert:
      case NotificationType.announcement:
        _showAlertDetailsModal(context, ref, notification);
        break;
    }
  }

  void _handleSecondaryCardAction(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    UserRole? role,
  ) {
    final isMr = ref.read(stringsProvider).isMr;

    switch (notification.type) {
      case NotificationType.newRideRequest:
        if (role == UserRole.driver) {
          ref.read(rideRepositoryProvider.notifier).cancelActiveRide('Driver declined');
          ref.read(notificationRepositoryProvider.notifier).clearNotification(notification.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMr ? 'राइड नाकारली' : 'Ride request declined'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: BrandConfig.textPrimaryBlack,
            ),
          );
        } else {
          ref.read(notificationRepositoryProvider.notifier).clearNotification(notification.id);
        }
        break;

      case NotificationType.rideAccepted:
      case NotificationType.driverArriving:
      case NotificationType.driverArrived:
      case NotificationType.rideStarted:
        final phone = role == UserRole.driver
            ? DemoData.demoCustomer.phone
            : (notification.driverPhone ?? DemoData.demoDriver.phone);
        _makePhoneCall(phone);
        break;

      default:
        break;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  NotificationModel _getSampleNotificationForType(NotificationType type) {
    try {
      return DemoData.demoNotifications.firstWhere((n) => n.type == type);
    } catch (_) {
      return DemoData.demoNotifications.first;
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

  Future<void> _handleTestNotificationAction(
    BuildContext context,
    WidgetRef ref, {
    NotificationType type = NotificationType.rideAccepted,
    NotificationModel? model,
    UserRole? role,
  }) async {
    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;
    final settings = ref.read(notificationSettingsProvider);
    final notifService = ref.read(localNotificationServiceProvider);
    final targetRole = role ?? _previewRole;

    bool isEnabled = await notifService.areNotificationsEnabled();
    if (!isEnabled) {
      final granted = await notifService.requestPermission();
      isEnabled = granted || (await notifService.areNotificationsEnabled());
    }

    if (!context.mounted) return;

    if (!isEnabled) {
      _showPermissionDeniedDialog(context, ref);
      return;
    }

    bool success = false;
    if (model != null) {
      success = await notifService.showNotificationForModel(
        model,
        userRole: targetRole,
        isMr: isMr,
        playSound: settings.notificationSounds,
        enableVibration: settings.vibration,
      );
    } else {
      success = await notifService.showTestNotificationForType(
        type,
        role: targetRole,
        isMr: isMr,
        playSound: settings.notificationSounds,
        enableVibration: settings.vibration,
      );
    }

    if (!context.mounted) return;

    if (success) {
      final targetTitle = model != null ? model.getTitle(isMr) : _getTypeLabel(type, isMr);
      final roleStr = targetRole == UserRole.driver
          ? (isMr ? 'चालक' : 'Driver')
          : targetRole == UserRole.admin
              ? (isMr ? 'ॲडमिन' : 'Admin')
              : (isMr ? 'ग्राहक' : 'Customer');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: BrandConfig.accentYellow, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMr
                      ? '$targetTitle ($roleStr): ॲक्शन बटणांसह सूचना पाठवली!'
                      : '$targetTitle ($roleStr): Actionable notification sent! Check buttons.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: BrandConfig.textPrimaryBlack,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showPermissionDeniedDialog(context, ref);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context, WidgetRef ref) {
    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;
    final notifService = ref.read(localNotificationServiceProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_off_rounded, color: AppColors.error, size: 36),
        ),
        title: Text(
          isMr ? 'सूचना परवानगी नाकारली आहे' : 'Notification Permission Denied',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        content: Text(
          isMr
              ? 'तुमच्या फोनवर सूचना बंद आहेत. रिअल-टाइम राइड ट्रॅकिंग, चालक आगमन अलर्ट्स आणि चाचणी सूचना मिळवण्यासाठी कृपया सेटिंग्जमध्ये सूचना चालू करा.'
              : 'Android notifications are currently disabled for DharRide. To receive real-time ride tracking, driver arrival alerts, and test notifications, please enable Notifications in phone settings.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandConfig.accentYellow,
              foregroundColor: BrandConfig.textPrimaryBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await notifService.openNotificationSettings();
            },
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: Text(
              isMr ? 'ॲप सेटिंग उघडा' : 'Open App Settings',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerTestAllNotifications(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(stringsProvider);
    final isMr = strings.isMr;
    final settings = ref.read(notificationSettingsProvider);
    final notifService = ref.read(localNotificationServiceProvider);

    bool isEnabled = await notifService.areNotificationsEnabled();
    if (!isEnabled) {
      final granted = await notifService.requestPermission();
      isEnabled = granted || (await notifService.areNotificationsEnabled());
    }

    if (!context.mounted) return;

    if (!isEnabled) {
      _showPermissionDeniedDialog(context, ref);
      return;
    }

    const testTypes = [
      NotificationType.newRideRequest,
      NotificationType.rideAccepted,
      NotificationType.driverArriving,
      NotificationType.driverArrived,
      NotificationType.rideStarted,
      NotificationType.rideCompleted,
      NotificationType.rideCancelled,
    ];

    bool anySucceeded = false;
    for (final type in testTypes) {
      final ok = await notifService.showTestNotificationForType(
        type,
        role: _previewRole,
        isMr: isMr,
        playSound: settings.notificationSounds,
        enableVibration: settings.vibration,
      );
      if (ok) anySucceeded = true;
    }

    if (!context.mounted) return;

    if (anySucceeded) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: BrandConfig.accentYellow, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMr
                      ? 'सर्व ७ प्रकारच्या राइड सूचना Android वर पाठवल्या!'
                      : 'All 7 ride notifications dispatched to Android status bar!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: BrandConfig.textPrimaryBlack,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showPermissionDeniedDialog(context, ref);
    }
  }

  String _getTypeLabel(NotificationType type, bool isMr) {
    switch (type) {
      case NotificationType.newRideRequest:
        return isMr ? 'नवीन राइड विनंती' : 'New Ride Request';
      case NotificationType.rideAccepted:
        return isMr ? 'राइड स्वीकारली' : 'Ride Accepted';
      case NotificationType.driverArriving:
        return isMr ? 'चालक येत आहे' : 'Driver Arriving';
      case NotificationType.driverArrived:
        return isMr ? 'चालक पोहोचला' : 'Driver Arrived';
      case NotificationType.rideStarted:
        return isMr ? 'प्रवास सुरू' : 'Ride Started';
      case NotificationType.rideCompleted:
        return isMr ? 'प्रवास पूर्ण' : 'Ride Completed';
      case NotificationType.rideCancelled:
        return isMr ? 'प्रवास रद्द' : 'Ride Cancelled';
      case NotificationType.announcement:
        return isMr ? 'प्लॅटफॉर्म घोषणा' : 'Announcement';
      case NotificationType.systemAlert:
        return isMr ? 'सिस्टम इशारा' : 'System Alert';
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newRideRequest:
        return Icons.hail_rounded;
      case NotificationType.rideAccepted:
        return Icons.check_circle_rounded;
      case NotificationType.driverArriving:
        return Icons.directions_car_rounded;
      case NotificationType.driverArrived:
        return Icons.pin_drop_rounded;
      case NotificationType.rideStarted:
        return Icons.navigation_rounded;
      case NotificationType.rideCompleted:
        return Icons.task_alt_rounded;
      case NotificationType.rideCancelled:
        return Icons.cancel_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.systemAlert:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newRideRequest:
        return BrandConfig.accentYellowDark;
      case NotificationType.rideAccepted:
        return AppColors.success;
      case NotificationType.driverArriving:
        return AppColors.info;
      case NotificationType.driverArrived:
        return BrandConfig.accentYellowDark;
      case NotificationType.rideStarted:
        return const Color(0xFFE65100);
      case NotificationType.rideCompleted:
        return AppColors.success;
      case NotificationType.rideCancelled:
        return AppColors.error;
      case NotificationType.announcement:
      case NotificationType.systemAlert:
        return BrandConfig.accentYellowDark;
    }
  }
}
