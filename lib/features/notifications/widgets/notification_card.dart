import 'package:flutter/material.dart';
import '../../../core/brand/brand_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isMr;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isMr,
    required this.onTap,
    required this.onDismiss,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getNotificationStyle(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              isMr ? 'हटवा' : 'Delete',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: Colors.white, size: 22),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : const Color(0xFFFFFDF7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead ? AppColors.border : BrandConfig.accentYellowDark.withOpacity(0.55),
                width: notification.isRead ? 1 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(notification.isRead ? 0.02 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Accent Bar for Unread Items
                  Container(
                    width: 5,
                    color: notification.isRead ? Colors.transparent : BrandConfig.accentYellow,
                  ),

                  // Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Icon + Category Tag + Timestamp + Unread Dot
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: style.bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: style.borderColor.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Icon(style.icon, size: 20, color: style.iconColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: style.tagBgColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isMr ? style.tagLabelMr : style.tagLabelEn,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                                color: style.tagTextColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              notification.timestamp,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (!notification.isRead) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  color: BrandConfig.accentYellowDark,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification.getTitle(isMr),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: BrandConfig.textPrimaryBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Notification Body Message
                          Text(
                            notification.getBody(isMr),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),

                          // Optional Route or Driver Capsule
                          if (_hasMetadata(notification)) ...[
                            const SizedBox(height: 8),
                            _buildMetadataCapsule(context),
                          ],

                          const SizedBox(height: 10),

                          // Bottom Row Actions
                          Row(
                            children: [
                              // Primary Action Button
                              InkWell(
                                onTap: onTap,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: BrandConfig.accentYellow.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: BrandConfig.accentYellowDark.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        notification.getActionLabel(isMr) ??
                                            (isMr ? 'तपशील पहा' : 'View Details'),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: BrandConfig.textPrimaryBlack,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 13,
                                        color: BrandConfig.textPrimaryBlack,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (!notification.isRead)
                                IconButton(
                                  icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                                  tooltip: isMr ? 'वाचले म्हणून चिन्हांकित करा' : 'Mark as read',
                                  color: AppColors.textMuted,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  onPressed: onMarkAsRead,
                                ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                tooltip: isMr ? 'काढून टाका' : 'Dismiss',
                                color: AppColors.textMuted,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: onDismiss,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasMetadata(NotificationModel n) {
    return n.pickupAddress != null || n.driverName != null || n.fare != null;
  }

  Widget _buildMetadataCapsule(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (notification.autoNumber != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: BrandConfig.textPrimaryBlack,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                notification.autoNumber!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: BrandConfig.accentYellow,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (notification.pickupAddress != null && notification.destinationAddress != null) ...[
            const Icon(Icons.route_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${notification.pickupAddress} ➔ ${notification.destinationAddress}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ] else if (notification.pickupAddress != null) ...[
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                notification.pickupAddress!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
          if (notification.fare != null) ...[
            const SizedBox(width: 8),
            Text(
              '₹${notification.fare!.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _NotificationStyle _getNotificationStyle(NotificationType type) {
    switch (type) {
      case NotificationType.newRideRequest:
        return _NotificationStyle(
          icon: Icons.hail_rounded,
          iconColor: BrandConfig.textPrimaryBlack,
          bgColor: BrandConfig.accentYellow.withOpacity(0.22),
          borderColor: BrandConfig.accentYellowDark,
          tagLabelEn: 'NEW REQUEST',
          tagLabelMr: 'नवीन विनंती',
          tagBgColor: BrandConfig.accentYellowLight,
          tagTextColor: const Color(0xFF8A5300),
        );
      case NotificationType.rideAccepted:
        return _NotificationStyle(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          bgColor: AppColors.success.withOpacity(0.12),
          borderColor: AppColors.success,
          tagLabelEn: 'RIDE ACCEPTED',
          tagLabelMr: 'स्वीकारले',
          tagBgColor: AppColors.success.withOpacity(0.12),
          tagTextColor: AppColors.success,
        );
      case NotificationType.driverArriving:
        return _NotificationStyle(
          icon: Icons.directions_car_rounded,
          iconColor: AppColors.info,
          bgColor: AppColors.info.withOpacity(0.12),
          borderColor: AppColors.info,
          tagLabelEn: 'DRIVER ARRIVING',
          tagLabelMr: 'चालक येत आहे',
          tagBgColor: AppColors.info.withOpacity(0.12),
          tagTextColor: AppColors.info,
        );
      case NotificationType.driverArrived:
        return _NotificationStyle(
          icon: Icons.pin_drop_rounded,
          iconColor: BrandConfig.accentYellowDark,
          bgColor: BrandConfig.accentYellow.withOpacity(0.25),
          borderColor: BrandConfig.accentYellowDark,
          tagLabelEn: 'DRIVER ARRIVED',
          tagLabelMr: 'चालक पोहोचला',
          tagBgColor: BrandConfig.accentYellowLight,
          tagTextColor: const Color(0xFF8A5300),
        );
      case NotificationType.rideStarted:
        return _NotificationStyle(
          icon: Icons.navigation_rounded,
          iconColor: BrandConfig.textPrimaryBlack,
          bgColor: BrandConfig.accentYellow.withOpacity(0.25),
          borderColor: BrandConfig.textPrimaryBlack,
          tagLabelEn: 'RIDE STARTED',
          tagLabelMr: 'प्रवास सुरू',
          tagBgColor: BrandConfig.accentYellowLight,
          tagTextColor: BrandConfig.textPrimaryBlack,
        );
      case NotificationType.rideCompleted:
        return _NotificationStyle(
          icon: Icons.task_alt_rounded,
          iconColor: AppColors.success,
          bgColor: AppColors.success.withOpacity(0.14),
          borderColor: AppColors.success,
          tagLabelEn: 'COMPLETED',
          tagLabelMr: 'पूर्ण झाले',
          tagBgColor: AppColors.success.withOpacity(0.12),
          tagTextColor: AppColors.success,
        );
      case NotificationType.rideCancelled:
        return _NotificationStyle(
          icon: Icons.cancel_rounded,
          iconColor: AppColors.error,
          bgColor: AppColors.error.withOpacity(0.12),
          borderColor: AppColors.error,
          tagLabelEn: 'CANCELLED',
          tagLabelMr: 'रद्द झाले',
          tagBgColor: AppColors.error.withOpacity(0.12),
          tagTextColor: AppColors.error,
        );
      case NotificationType.announcement:
      case NotificationType.systemAlert:
        return _NotificationStyle(
          icon: Icons.campaign_rounded,
          iconColor: BrandConfig.textPrimaryBlack,
          bgColor: BrandConfig.accentYellow.withOpacity(0.2),
          borderColor: BrandConfig.accentYellowDark,
          tagLabelEn: 'ALERT',
          tagLabelMr: 'सूचना',
          tagBgColor: BrandConfig.accentYellowLight,
          tagTextColor: const Color(0xFF8A5300),
        );
    }
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String tagLabelEn;
  final String tagLabelMr;
  final Color tagBgColor;
  final Color tagTextColor;

  const _NotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.tagLabelEn,
    required this.tagLabelMr,
    required this.tagBgColor,
    required this.tagTextColor,
  });
}
