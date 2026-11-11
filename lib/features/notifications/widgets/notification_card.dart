import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/brand/brand_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/notification_model.dart';
import 'notification_graphics.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isMr;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;
  final VoidCallback? onTestNotification;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final UserRole? role;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isMr,
    required this.onTap,
    required this.onDismiss,
    required this.onMarkAsRead,
    this.onTestNotification,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: notification.isRead
                    ? const Color(0xFFE5E7EB)
                    : BrandConfig.accentYellow.withOpacity(0.85),
                width: notification.isRead ? 1.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(notification.isRead ? 0.03 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row: Actual DharRide Logo + 'DharRide • Now' + Bell & Chevron
                _buildCardHeader(context),

                const SizedBox(height: 12),

                // Specific Notification Content based on Type
                _buildCardBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Card Header with DharRide app branding and icons matching reference image
  Widget _buildCardHeader(BuildContext context) {
    return Row(
      children: [
        // DharRide Official Brand Logo inside circular yellow badge
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: BrandConfig.accentYellow,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(5),
          child: Image.asset(
            BrandConfig.appLogoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.electric_rickshaw,
              size: 20,
              color: BrandConfig.textPrimaryBlack,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${BrandConfig.appName} • ${notification.timestamp == 'Just now' ? (isMr ? 'आता' : 'Now') : notification.timestamp}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
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
        ),
        const SizedBox(width: 6),
        // Bell icon and downward chevron matching reference
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 17,
              color: Color(0xFF222222),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF444444),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'read') {
                  onMarkAsRead();
                } else if (val == 'dismiss') {
                  onDismiss();
                } else if (val == 'test' && onTestNotification != null) {
                  onTestNotification!();
                }
              },
              itemBuilder: (ctx) => [
                if (!notification.isRead)
                  PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(isMr ? 'वाचले म्हणून खूण करा' : 'Mark as read', style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                if (onTestNotification != null)
                  PopupMenuItem(
                    value: 'test',
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, size: 16, color: BrandConfig.accentYellowDark),
                        const SizedBox(width: 8),
                        Text(isMr ? 'स्थानिक सूचना पाठवा' : 'Trigger OS Notification', style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'dismiss',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(isMr ? 'काढून टाका' : 'Dismiss', style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Builds context-appropriate card body for each of the 7 notification types
  Widget _buildCardBody(BuildContext context) {
    switch (notification.type) {
      case NotificationType.newRideRequest:
        return _buildNewRideRequestCard(context);

      case NotificationType.rideAccepted:
        return _buildRideAcceptedCard(context);

      case NotificationType.driverArriving:
        return _buildDriverArrivingCard(context);

      case NotificationType.driverArrived:
        return _buildDriverArrivedCard(context);

      case NotificationType.rideStarted:
        return _buildRideStartedCard(context);

      case NotificationType.rideCompleted:
        return _buildRideCompletedCard(context);

      case NotificationType.rideCancelled:
        return _buildRideCancelledCard(context);

      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return _buildAlertCard(context);
    }
  }

  // ---------------------------------------------------------------------------
  // CARD 1: Ride Accepted!
  // ---------------------------------------------------------------------------
  Widget _buildRideAcceptedCard(BuildContext context) {
    final driverName = notification.driverName ?? 'Ramesh Shinde';
    final autoNumber = notification.autoNumber ?? 'MH-25-AZ-4589';
    final driverPhone = notification.driverPhone ?? '9422054321';
    final isDriverRole = role == UserRole.driver;

    final title = isDriverRole
        ? (isMr ? 'राइड स्वीकारली!' : 'Ride Accepted!')
        : (isMr ? 'राइड स्वीकारली!' : 'Ride Accepted!');
    final subtitle = isDriverRole
        ? (isMr ? 'पिकअप स्थानाकडे जाण्यासाठी मार्ग पहा.' : 'You accepted the ride. Head to pickup point.')
        : (isMr ? '$driverName यांनी तुमची राइड स्वीकारली.' : '$driverName accepted your ride.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: BrandConfig.textPrimaryBlack,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),

        // Grey container with Driver name, Vehicle number, and Accepted green badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.directions_car, size: 16, color: Color(0xFF333333)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            autoNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 5),
                    Text(
                      isMr ? 'स्वीकारले' : 'Accepted',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Action Buttons Row: 'View Ride' (Yellow) and 'Call Driver' (Outlined)
        Row(
          children: [
            Expanded(
              child: _buildYellowPillButton(
                label: isDriverRole ? (isMr ? 'पिकअप मार्ग' : 'View Pickup') : (isMr ? 'राइड पहा' : 'View Ride'),
                onTap: onPrimaryAction ?? onTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOutlinedPillButton(
                label: isDriverRole ? (isMr ? 'ग्राहकाला कॉल' : 'Call Customer') : (isMr ? 'चालकाला कॉल' : 'Call Driver'),
                icon: Icons.phone,
                onTap: onSecondaryAction ?? () => _launchCall(driverPhone),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 2: Driver is Arriving
  // ---------------------------------------------------------------------------
  Widget _buildDriverArrivingCard(BuildContext context) {
    final driverName = notification.driverName ?? 'Ramesh Shinde';
    final driverPhone = notification.driverPhone ?? '9422054321';
    final distance = notification.getDistanceText(isMr);
    final eta = notification.getEtaText(isMr);
    final isDriverRole = role == UserRole.driver;

    final title = isDriverRole
        ? (isMr ? 'पिकअपकडे जात आहात' : 'Approaching Pickup')
        : (isMr ? 'चालक येत आहे' : 'Driver is Arriving');
    final subtitle = isDriverRole
        ? (isMr ? 'ग्राहक बस स्थानक येथे वाट पाहत आहे.' : 'Customer is waiting at pickup location.')
        : (isMr ? '$driverName पिकअपकडे येत आहेत.' : '$driverName is on the way.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: BrandConfig.textPrimaryBlack,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),

        // Middle Section: Distance & ETA on left, Rickshaw on road with city skyline on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF111111)),
                    const SizedBox(width: 6),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF111111)),
                    const SizedBox(width: 6),
                    Text(
                      eta,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const SkylineRickshawGraphic(width: 96, height: 50),
          ],
        ),

        const SizedBox(height: 14),

        // Action Buttons Row: 'View Live' (Yellow) and 'Call Driver' (Outlined)
        Row(
          children: [
            Expanded(
              child: _buildYellowPillButton(
                label: isMr ? 'थेट पहा' : 'View Live',
                onTap: onPrimaryAction ?? onTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOutlinedPillButton(
                label: isDriverRole ? (isMr ? 'ग्राहकाला कॉल' : 'Call Customer') : (isMr ? 'चालकाला कॉल' : 'Call Driver'),
                icon: Icons.phone,
                onTap: onSecondaryAction ?? () => _launchCall(driverPhone),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 3: Driver Arrived!
  // ---------------------------------------------------------------------------
  Widget _buildDriverArrivedCard(BuildContext context) {
    final driverName = notification.driverName ?? 'Ramesh Shinde';
    final driverPhone = notification.driverPhone ?? '9422054321';
    final isDriverRole = role == UserRole.driver;

    final title = isDriverRole
        ? (isMr ? 'पिकअप स्थानावर पोहोचला!' : 'Arrived at Pickup!')
        : (isMr ? 'चालक पोहोचला!' : 'Driver Arrived!');
    final subtitle = isDriverRole
        ? (isMr ? 'तुम्ही ग्राहक पिकअप स्थानावर आहात. ग्राहकाशी संपर्क करा.' : 'You arrived at pickup. Contact customer to board.')
        : (isMr ? '$driverName तुमच्या स्थानावर पोहोचले आहेत.' : '$driverName has arrived at your location.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const FoldedMapGraphic(width: 68, height: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: BrandConfig.textPrimaryBlack,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Action Buttons Row: 'View Ride' (Yellow) and 'Call Driver' (Outlined)
        Row(
          children: [
            Expanded(
              child: _buildYellowPillButton(
                label: isDriverRole ? (isMr ? 'प्रवास सुरू करा' : 'Start Ride') : (isMr ? 'राइड पहा' : 'View Ride'),
                onTap: onPrimaryAction ?? onTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOutlinedPillButton(
                label: isDriverRole ? (isMr ? 'ग्राहकाला कॉल' : 'Call Customer') : (isMr ? 'चालकाला कॉल' : 'Call Driver'),
                icon: Icons.phone,
                onTap: onSecondaryAction ?? () => _launchCall(driverPhone),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 4: Ride Started
  // ---------------------------------------------------------------------------
  Widget _buildRideStartedCard(BuildContext context) {
    final title = isMr ? 'प्रवास सुरू झाला' : 'Ride Started';
    final subtitle = isMr
        ? 'तुमचा प्रवास सुरू झाला आहे.\nसुखकर प्रवासाच्या शुभेच्छा!'
        : 'Your ride has started.\nEnjoy the ride!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: BrandConfig.textPrimaryBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SpeedRickshawGraphic(width: 96, height: 50),
          ],
        ),

        const SizedBox(height: 14),

        // Single Full-Width Yellow Button: 'View Ride'
        _buildYellowPillButton(
          label: isMr ? 'राइड पहा' : 'View Ride',
          onTap: onPrimaryAction ?? onTap,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 5: Ride Completed 🎉
  // ---------------------------------------------------------------------------
  Widget _buildRideCompletedCard(BuildContext context) {
    final fareAmount = (notification.fare ?? 120.0).toInt();
    final distanceText = notification.distance ?? '14 km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMr ? 'प्रवास पूर्ण झाला 🎉' : 'Ride Completed 🎉',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: BrandConfig.textPrimaryBlack,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          isMr ? 'प्रवास यशस्वीरीत्या पूर्ण झाला!' : 'Trip completed successfully!',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),

        // 3-Column Box (Total Fare, Distance, Done badge)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Column 1: Total Fare
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹ $fareAmount',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMr ? 'एकूण भाडे' : 'Total Fare',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 32, color: const Color(0xFFE0E0E0)),

              // Column 2: Distance
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF111111)),
                          const SizedBox(width: 3),
                          Text(
                            distanceText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMr ? 'अंतर' : 'Distance',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(width: 1, height: 32, color: const Color(0xFFE0E0E0)),

              // Column 3: Status Done
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: BrandConfig.accentYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 13, color: BrandConfig.textPrimaryBlack),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMr ? 'पूर्ण' : 'Done',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Full-Width Outlined Button: 'View Details'
        _buildOutlinedPillButton(
          label: isMr ? 'तपशील पहा' : 'View Details',
          onTap: onPrimaryAction ?? onTap,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 6: Ride Cancelled
  // ---------------------------------------------------------------------------
  Widget _buildRideCancelledCard(BuildContext context) {
    final cancelReason = notification.getCancelReason(isMr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? 'प्रवास रद्द झाला' : 'Ride Cancelled',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: BrandConfig.textPrimaryBlack,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isMr ? 'तुमची राइड रद्द करण्यात आली आहे.' : 'Your ride has been cancelled.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Grey capsule with info icon and reason
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info, size: 13, color: Color(0xFF444444)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${isMr ? 'कारण: ' : 'Reason: '}$cancelReason',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CancelledRickshawGraphic(width: 96, height: 50),
          ],
        ),

        const SizedBox(height: 14),

        // Full-Width Yellow Button: 'OK'
        _buildYellowPillButton(
          label: isMr ? 'ठीक आहे' : 'OK',
          onTap: onPrimaryAction ?? onTap,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 7: New Ride Request
  // ---------------------------------------------------------------------------
  Widget _buildNewRideRequestCard(BuildContext context) {
    final pickupDist = notification.pickupDistance ?? '2.3 km';
    final dropDist = notification.dropDistance ?? '6.8 km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const FoldedMapGraphic(width: 62, height: 48),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMr ? 'नवीन राइड विनंती' : 'New Ride Request',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: BrandConfig.textPrimaryBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMr ? 'जवळपास नवीन राइड उपलब्ध आहे.' : 'A new ride request is nearby.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Color(0xFF111111)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '$pickupDist ${isMr ? 'पिकअप' : 'Pickup'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 1,
                        height: 10,
                        color: const Color(0xFFD0D0D0),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flag, size: 12, color: Color(0xFF111111)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '$dropDist ${isMr ? 'ड्रॉप' : 'Drop'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 90,
                  height: 36,
                  child: _buildYellowPillButton(
                    label: isMr ? 'स्वीकारा' : 'Accept',
                    onTap: onPrimaryAction ?? onTap,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 90,
                  height: 36,
                  child: _buildOutlinedPillButton(
                    label: isMr ? 'नाकारा' : 'Decline',
                    onTap: onSecondaryAction ?? onDismiss,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FALLBACK / SYSTEM ALERT & ANNOUNCEMENTS
  // ---------------------------------------------------------------------------
  Widget _buildAlertCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: BrandConfig.accentYellow.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_rounded,
                size: 20,
                color: BrandConfig.textPrimaryBlack,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.getTitle(isMr),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BrandConfig.textPrimaryBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.getBody(isMr),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF555555),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildOutlinedPillButton(
            label: notification.getActionLabel(isMr) ?? (isMr ? 'सूचना पहा' : 'View Notice'),
            onTap: onPrimaryAction ?? onTap,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE PREMIUM BUTTON BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildYellowPillButton({
    required String label,
    required VoidCallback onTap,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandConfig.accentYellow,
          foregroundColor: BrandConfig.textPrimaryBlack,
          elevation: 0,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: BrandConfig.textPrimaryBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedPillButton({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: BrandConfig.textPrimaryBlack,
          elevation: 0,
          side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: BrandConfig.textPrimaryBlack),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: BrandConfig.textPrimaryBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }
}
