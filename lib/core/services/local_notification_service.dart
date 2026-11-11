import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/demo/demo_data.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/session/session_manager.dart';
import '../brand/brand_config.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Top-level background entry point required by flutter_local_notifications.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification background action tapped: ${notificationResponse.actionId}');
}

/// Service responsible for managing local notifications on Android devices,
/// requesting runtime permissions (Android 13+), generating actionable notifications
/// (Accept, Reject, View, Call Customer/Driver), and routing actions.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  ProviderContainer? _container;
  NotificationResponse? _pendingLaunchResponse;
  String? _pendingRoute;

  // Channels
  static const String rideChannelId = 'dharride_rides';
  static const String rideChannelName = 'Ride Updates';
  static const String rideChannelDesc =
      'Real-time notifications for auto bookings, driver arrival, trip progress, and completion';

  static const String alertsChannelId = 'dharride_alerts';
  static const String alertsChannelName = 'Service Announcements & Alerts';
  static const String alertsChannelDesc =
      'Platform announcements and community notices for Dharashiv auto network';

  // Action IDs
  static const String actionAcceptRide = 'accept_ride';
  static const String actionRejectRide = 'reject_ride';
  static const String actionViewRide = 'view_ride';
  static const String actionTrackRide = 'track_ride';
  static const String actionCallCustomer = 'call_customer';
  static const String actionCallDriver = 'call_driver';
  static const String actionRateRide = 'rate_ride';
  static const String actionViewReceipt = 'view_receipt';
  static const String actionBookAgain = 'book_again';
  static const String actionCancelRide = 'cancel_ride';
  static const String actionViewEarnings = 'view_earnings';
  static const String actionDriverHome = 'driver_home';
  static const String actionFindRides = 'find_rides';
  static const String actionViewAlerts = 'view_alerts';
  static const String actionManageAlerts = 'manage_alerts';

  /// Attaches the Riverpod [ProviderContainer] for state mutation and routing.
  void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  /// Initializes the local notification plugin and configures Android notification channels.
  Future<void> initialize({
    void Function(NotificationResponse response)? onSelectNotification,
  }) async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (onSelectNotification != null) {
            onSelectNotification(response);
          } else {
            handleNotificationResponse(response);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Create Android Notification Channels (Android 8.0+)
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        const AndroidNotificationChannel rideChannel = AndroidNotificationChannel(
          rideChannelId,
          rideChannelName,
          description: rideChannelDesc,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );

        const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
          alertsChannelId,
          alertsChannelName,
          description: alertsChannelDesc,
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );

        await androidPlatform.createNotificationChannel(rideChannel);
        await androidPlatform.createNotificationChannel(alertChannel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService initialization error: $e');
    }
  }

  /// Checks if the app was launched by tapping a notification or notification action from a terminated state.
  Future<void> checkLaunchNotification() async {
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        if (launchDetails.notificationResponse != null) {
          _pendingLaunchResponse = launchDetails.notificationResponse;
        }
      }
    } catch (e) {
      debugPrint('Error checking notification app launch: $e');
    }
  }

  /// Called after the UI is rendered to execute any pending notification launch action.
  void processPendingLaunch() {
    if (_pendingLaunchResponse != null) {
      final response = _pendingLaunchResponse!;
      _pendingLaunchResponse = null;
      handleNotificationResponse(response);
    } else if (_pendingRoute != null) {
      final route = _pendingRoute!;
      _pendingRoute = null;
      _navigateTo(route);
    }
  }

  /// Checks if notification permissions are granted on the device.
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        final bool? enabled = await androidPlatform.areNotificationsEnabled();
        return enabled ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Requests the POST_NOTIFICATIONS permission on Android 13+ (API 33+).
  Future<bool> requestPermission() async {
    await initialize();
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        final bool? granted =
            await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Opens the device application details / notification settings page.
  Future<bool> openNotificationSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Shows an Android local notification with context-appropriate action buttons.
  Future<bool> showNotificationForModel(
    NotificationModel notification, {
    UserRole? userRole,
    bool isMr = false,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    await initialize();

    // 1. Verify or request permission
    bool isEnabled = await areNotificationsEnabled();
    if (!isEnabled) {
      final bool granted = await requestPermission();
      isEnabled = granted || (await areNotificationsEnabled());
      if (!isEnabled) {
        return false;
      }
    }

    final int notificationId =
        _getStableNotificationId(notification.type, notification.id);
    final Color color = _getNotificationColor(notification.type);
    final String tag = _getNotificationTag(notification.type, isMr);
    final String channelId = notification.category == NotificationCategory.alerts
        ? alertsChannelId
        : rideChannelId;
    final String channelName = notification.category == NotificationCategory.alerts
        ? alertsChannelName
        : rideChannelName;
    final String channelDesc = notification.category == NotificationCategory.alerts
        ? alertsChannelDesc
        : rideChannelDesc;

    // Determine target role for action buttons and content
    final UserRole role = userRole ??
        _container?.read(currentUserProvider)?.role ??
        (notification.type == NotificationType.newRideRequest
            ? UserRole.driver
            : UserRole.customer);

    // Build role-appropriate title, body, and BigTextStyle content
    final content = _buildRoleNotificationContent(
      type: notification.type,
      role: role,
      isMr: isMr,
      notification: notification,
    );
    final String title = content['title']!;
    final String body = content['body']!;
    final String bigText = content['bigText']!;

    // Context-appropriate Android notification actions
    final List<AndroidNotificationAction> actions = getActionsForNotification(
      type: notification.type,
      role: role,
      isMr: isMr,
      notification: notification,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: color,
      playSound: playSound,
      enableVibration: enableVibration,
      actions: actions.isNotEmpty ? actions : null,
      styleInformation: BigTextStyleInformation(
        bigText,
        contentTitle: title,
        summaryText: 'DharRide • $tag',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
      ),
      ticker: title,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final Map<String, dynamic> payloadMap = {
      'id': notification.id,
      'type': notification.type.name,
      'role': role.name,
      'rideId': notification.rideId ?? 'RIDE-9021',
      'driverName': notification.driverName ?? DemoData.demoDriver.name,
      'driverPhone': notification.driverPhone ?? DemoData.demoDriver.phone,
      'customerPhone': DemoData.demoCustomer.phone,
      'autoNumber': notification.autoNumber ?? DemoData.demoDriver.autoNumber,
      'fare': notification.fare ?? 20.0,
      'pickup': notification.pickupAddress ?? 'Dharashiv Central Bus Stand',
      'destination': notification.destinationAddress ?? 'Government Civil Hospital',
    };

    try {
      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(payloadMap),
      );
    } catch (e) {
      debugPrint('LocalNotificationService.showNotificationForModel error: $e');
    }

    return true;
  }

  /// Builds context-appropriate Android notification action buttons based on
  /// notification type, user role, and language.
  List<AndroidNotificationAction> getActionsForNotification({
    required NotificationType type,
    required UserRole role,
    required bool isMr,
    required NotificationModel notification,
  }) {
    switch (type) {
      case NotificationType.newRideRequest:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionAcceptRide,
              isMr ? 'स्वीकारा' : 'Accept',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionRejectRide,
              isMr ? 'नाकारा' : 'Decline',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'थेट डिस्पॅच पहा' : 'View Dispatch',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'राइड पहा' : 'View Ride',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCancelRide,
              isMr ? 'रद्द करा' : 'Cancel Request',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.rideAccepted:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'पिकअप मार्ग पहा' : 'View Pickup',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallCustomer,
              isMr ? 'ग्राहकाला कॉल' : 'Call Customer',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'ऑडिट पहा' : 'View Ride',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'राइड पहा' : 'View Ride',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallDriver,
              isMr ? 'चालकाला कॉल' : 'Call Driver',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.driverArriving:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'पिकअप मार्ग' : 'View Route',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallCustomer,
              isMr ? 'ग्राहकाला कॉल' : 'Call Customer',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'थेट नकाशा' : 'Live Map',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'थेट पहा' : 'View Live',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallDriver,
              isMr ? 'चालकाला कॉल' : 'Call Driver',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.driverArrived:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'प्रवास सुरू करा' : 'Start Ride',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallCustomer,
              isMr ? 'ग्राहकाला कॉल' : 'Call Customer',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'तपशील पहा' : 'View Details',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'राइड पहा' : 'View Ride',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallDriver,
              isMr ? 'चालकाला कॉल' : 'Call Driver',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.rideStarted:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'ड्रॉप मार्ग पहा' : 'Drop Route',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionCallCustomer,
              isMr ? 'ग्राहकाला कॉल' : 'Call Customer',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'थेट ट्रिप पहा' : 'Live Trip',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'राइड पहा' : 'View Ride',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.rideCompleted:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionViewEarnings,
              isMr ? 'कमाई पहा' : 'View Earnings',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              actionDriverHome,
              isMr ? 'डॅशबोर्ड' : 'Dashboard',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'ऑडिट पहा' : 'View Audit',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewReceipt,
              isMr ? 'तपशील पहा' : 'View Details',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.rideCancelled:
        if (role == UserRole.driver) {
          return [
            AndroidNotificationAction(
              actionFindRides,
              isMr ? 'नवीन राइड शोधा' : 'Find Rides',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionViewRide,
              isMr ? 'रद्द नोंदी पहा' : 'Cancel Log',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionBookAgain,
              isMr ? 'ठीक आहे (OK)' : 'OK',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }

      case NotificationType.systemAlert:
      case NotificationType.announcement:
        if (role == UserRole.admin) {
          return [
            AndroidNotificationAction(
              actionManageAlerts,
              isMr ? 'व्यवस्थापित करा' : 'Manage Alerts',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        } else {
          return [
            AndroidNotificationAction(
              actionViewAlerts,
              isMr ? 'सूचना पहा' : 'View Alerts',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ];
        }
    }
  }

  /// Builds context-appropriate notification titles, collapsed body, and expanded
  /// BigTextStyle content for all 7 DharRide notification types, supporting
  /// English and Marathi localization.
  Map<String, String> _buildRoleNotificationContent({
    required NotificationType type,
    required UserRole role,
    required bool isMr,
    required NotificationModel notification,
  }) {
    final driverName = notification.driverName ?? DemoData.demoDriver.name;
    final autoNumber = notification.autoNumber ?? DemoData.demoDriver.autoNumber;
    final customerName = DemoData.demoCustomer.name;
    final fare = (notification.fare ?? 20.0).toStringAsFixed(0);
    final pickup = notification.pickupAddress ?? 'Dharashiv Central Bus Stand';
    final drop = notification.destinationAddress ?? 'Government Civil Hospital';
    final dist = notification.getDistanceText(isMr);
    final eta = notification.getEtaText(isMr);
    final pickupDist = notification.pickupDistance ?? '2.3 km';
    final dropDist = notification.dropDistance ?? '6.8 km';
    final cancelReason = notification.getCancelReason(isMr);
    final rideId = notification.rideId ?? 'RIDE-9021';

    String title = '';
    String body = '';
    String bigText = '';

    switch (type) {
      case NotificationType.newRideRequest:
        if (role == UserRole.driver) {
          title = isMr ? 'नवीन राइड विनंती (₹$fare)' : 'New Ride Request (₹$fare)';
          body = isMr
              ? '$pickupDist पिकअप ($pickup) • $dropDist ड्रॉप ($drop)'
              : '$pickupDist Pickup ($pickup) • $dropDist Drop ($drop)';
          bigText = isMr
              ? 'जवळपास नवीन राइड विनंती आहे!\nपिकअप: $pickup ($pickupDist)\nड्रॉप: $drop ($dropDist)\nठरलेले भाडे: ₹$fare (०% प्लॅटफॉर्म कमिशन)\nस्वीकारण्यासाठी किंवा नाकारण्यासाठी खालील बटणे दाबा.'
              : 'New ride request nearby in Dharashiv!\nPickup: $pickup ($pickupDist)\nDrop: $drop ($dropDist)\nEstimated Fare: ₹$fare (0% Platform Fee)\nTap Accept to claim this ride.';
        } else {
          title = isMr ? 'ऑटो शोधत आहे...' : 'Searching for Auto...';
          body = isMr
              ? 'धाराशिवमधील जवळच्या रिक्षा चालकांशी जोडत आहे...'
              : 'Connecting to nearby auto drivers in Dharashiv...';
          bigText = isMr
              ? 'तुमच्या प्रवासासाठी ऑटो शोधत आहे.\nपिकअप: $pickup\nड्रॉप: $drop\nअंदाजित भाडे: ₹$fare'
              : 'Searching for auto-rickshaw drivers.\nPickup: $pickup\nDestination: $drop\nEstimated Fare: ₹$fare';
        }
        break;

      case NotificationType.rideAccepted:
        if (role == UserRole.driver) {
          title = isMr ? 'राइड स्वीकारली!' : 'Ride Accepted!';
          body = isMr ? 'ग्राहक पिकअप स्थानाकडे जा: $pickup' : 'Head to customer pickup: $pickup';
          bigText = isMr
              ? 'तुम्ही राइड स्वीकारली आहे!\nप्रवासी: $customerName\nपिकअप स्थान: $pickup\nड्रॉप: $drop\nठरलेले भाडे: ₹$fare (१००% थेट चालक कमाई)'
              : 'Ride accepted successfully!\nPassenger: $customerName\nPickup: $pickup\nDrop: $drop\nFare: ₹$fare (100% Direct to You)';
        } else {
          title = isMr ? 'राइड स्वीकारली!' : 'Ride Accepted!';
          body = isMr ? '$driverName यांनी तुमची राइड स्वीकारली ($autoNumber).' : '$driverName accepted your ride ($autoNumber).';
          bigText = isMr
              ? '$driverName यांनी तुमची राइड स्वीकारली आहे!\nऑटो क्रमांक: $autoNumber\nपिकअप: $pickup\nभाडे: ₹$fare (०% अतिरिक्त शुल्क)'
              : '$driverName accepted your ride!\nAuto: $autoNumber\nPickup: $pickup\nAgreed Fare: ₹$fare (0% Platform Fee)';
        }
        break;

      case NotificationType.driverArriving:
        if (role == UserRole.driver) {
          title = isMr ? 'पिकअपकडे जात आहात' : 'Approaching Pickup';
          body = isMr ? 'पिकअप अंतर: $dist • $eta' : 'Approaching pickup spot: $dist • $eta';
          bigText = isMr
              ? 'तुम्ही पिकअप स्थानाकडे जात आहात.\nस्थान: $pickup\nअंतर: $dist • $eta\nग्राहक वाट पाहत आहे.'
              : 'Approaching pickup spot.\nLocation: $pickup\nDistance: $dist • $eta\nCustomer is waiting.';
        } else {
          title = isMr ? 'चालक येत आहे' : 'Driver is Arriving';
          body = isMr ? '$driverName पिकअपकडे येत आहेत ($dist • $eta).' : '$driverName is on the way ($dist • $eta).';
          bigText = isMr
              ? '$driverName पिकअप स्थानाकडे येत आहेत.\nऑटो क्रमांक: $autoNumber\nअंतर: $dist • $eta\nकृपया पिकअप स्थानावर तयार राहा.'
              : '$driverName is approaching your location.\nAuto: $autoNumber\nDistance: $dist • $eta\nPlease be ready at $pickup.';
        }
        break;

      case NotificationType.driverArrived:
        if (role == UserRole.driver) {
          title = isMr ? 'पिकअप स्थानावर पोहोचला!' : 'Arrived at Pickup!';
          body = isMr ? 'तुम्ही $pickup येथे पोहोचला आहात.' : 'You have arrived at $pickup.';
          bigText = isMr
              ? 'तुम्ही ग्राहक पिकअप स्थानावर पोहोचला आहात: $pickup\nग्राहकाशी संपर्क करा किंवा थेट कॉल करा.'
              : 'You arrived at customer pickup spot: $pickup.\nContact customer to board your auto.';
        } else {
          title = isMr ? 'चालक पोहोचला!' : 'Driver Arrived!';
          body = isMr ? '$driverName ($autoNumber) तुमच्या स्थानावर पोहोचले आहेत.' : '$driverName ($autoNumber) has arrived at your location.';
          bigText = isMr
              ? '$driverName ($autoNumber) तुमच्या पिकअप स्थानावर पोहोचले आहेत!\nस्थान: $pickup\nकृपया ऑटोमध्ये बसा व प्रवास सुरू करा.'
              : '$driverName has arrived at your location!\nAuto: $autoNumber\nLocation: $pickup\nPlease proceed to board the auto.';
        }
        break;

      case NotificationType.rideStarted:
        if (role == UserRole.driver) {
          title = isMr ? 'प्रवास सुरू झाला' : 'Ride Started';
          body = isMr ? 'मार्ग: $drop कडे प्रवास सुरू.' : 'Trip in progress to $drop.';
          bigText = isMr
              ? 'प्रवास सुरू झाला आहे!\nड्रॉप स्थान: $drop\nठरलेले भाडे: ₹$fare\nसुरक्षित वाहन चालवा.'
              : 'Trip in progress!\nDestination: $drop\nAgreed Fare: ₹$fare\nDrive safely in Dharashiv.';
        } else {
          title = isMr ? 'प्रवास सुरू झाला' : 'Ride Started';
          body = isMr ? 'तुमचा प्रवास $drop कडे सुरू झाला आहे.' : 'Your ride to $drop has started.';
          bigText = isMr
              ? 'तुमचा प्रवास सुरू झाला आहे!\nचालक: $driverName ($autoNumber)\nड्रॉप: $drop\nसुखकर प्रवासाच्या शुभेच्छा!'
              : 'Your ride has started!\nDriver: $driverName ($autoNumber)\nDestination: $drop\nEnjoy your ride with DharRide!';
        }
        break;

      case NotificationType.rideCompleted:
        if (role == UserRole.driver) {
          title = isMr ? 'प्रवास पूर्ण झाला 🎉' : 'Ride Completed 🎉';
          body = isMr ? 'कमाई: ₹$fare (१००% थेट • ०% कमिशन)' : 'Trip completed! Fare: ₹$fare (100% Yours)';
          bigText = isMr
              ? 'प्रवास यशस्वीरीत्या पूर्ण झाला!\nएकूण कमाई: ₹$fare (१००% थेट चालक कमाई)\nप्लॅटफॉर्म कमिशन: ₹०.००\nअंतर: $dist'
              : 'Trip completed successfully!\nEarnings: ₹$fare (100% Direct Driver Share)\nPlatform Fee: ₹0.00 (0% Commission)\nDistance: $dist';
        } else {
          title = isMr ? 'प्रवास पूर्ण झाला 🎉' : 'Ride Completed 🎉';
          body = isMr ? 'एकूण भाडे: ₹$fare • अंतर: $dist' : 'Trip completed! Total Fare: ₹$fare • $dist';
          bigText = isMr
              ? 'तुमचा प्रवास यशस्वीरीत्या पूर्ण झाला आहे!\nएकूण भाडे: ₹$fare (०% अतिरिक्त शुल्क)\nअंतर: $dist\nDharRide वापरल्याबद्दल धन्यवाद!'
              : 'Trip completed successfully!\nTotal Fare: ₹$fare (0% Platform Fee)\nDistance: $dist\nThank you for riding with DharRide!';
        }
        break;

      case NotificationType.rideCancelled:
        if (role == UserRole.driver) {
          title = isMr ? 'प्रवास रद्द झाला' : 'Ride Cancelled';
          body = isMr ? 'राइड $rideId रद्द झाली. कारण: $cancelReason' : 'Ride $rideId cancelled. Reason: $cancelReason';
          bigText = isMr
              ? 'राइड $rideId रद्द झाली आहे.\nकारण: $cancelReason\nतुम्ही नवीन राइड्स मिळवण्यासाठी ऑनलाइन आहात.'
              : 'Ride $rideId was cancelled.\nReason: $cancelReason\nYou are online to receive new requests.';
        } else {
          title = isMr ? 'प्रवास रद्द झाला' : 'Ride Cancelled';
          body = isMr ? 'तुमची राइड रद्द झाली. कारण: $cancelReason' : 'Your ride was cancelled. Reason: $cancelReason';
          bigText = isMr
              ? 'तुमची राइड रद्द करण्यात आली आहे.\nकारण: $cancelReason\nनवीन ऑटो बुक करण्यासाठी मुख्य पानावर जा.'
              : 'Your ride has been cancelled.\nReason: $cancelReason\nTap to book another auto in Dharashiv.';
        }
        break;

      case NotificationType.systemAlert:
      case NotificationType.announcement:
        title = notification.getTitle(isMr);
        body = notification.getBody(isMr);
        bigText = '${notification.getTitle(isMr)}\n\n${notification.getBody(isMr)}\n\nDharRide • Dharashiv Platform';
        break;
    }

    return {
      'title': title,
      'body': body,
      'bigText': bigText,
    };
  }

  /// Handles incoming notification response when user taps either:
  /// - An action button (`response.actionId` is present)
  /// - The notification body (`response.actionId` is null/empty)
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final String? payloadStr = response.payload;
    final String? actionId = response.actionId;

    Map<String, dynamic> data = {};
    if (payloadStr != null && payloadStr.isNotEmpty) {
      try {
        data = jsonDecode(payloadStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error decoding notification payload: $e');
      }
    }

    final String notificationId = data['id'] as String? ?? 'notif';
    final String typeName = data['type'] as String? ?? '';
    final String roleName = data['role'] as String? ?? '';
    final String rideId = data['rideId'] as String? ?? 'RIDE-9021';
    final String driverPhone = data['driverPhone'] as String? ?? DemoData.demoDriver.phone;
    final String customerPhone = data['customerPhone'] as String? ?? DemoData.demoCustomer.phone;

    // Mark as read in repository
    if (_container != null) {
      _container!.read(notificationRepositoryProvider.notifier).markAsRead(notificationId);
    }

    // Determine role
    UserRole? currentRole = _container?.read(currentUserProvider)?.role;
    if (currentRole == null && roleName.isNotEmpty) {
      currentRole = UserRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => UserRole.customer,
      );
    }

    // 1. Phone Call Actions (Call Driver / Call Customer)
    if (actionId == actionCallDriver) {
      await _makePhoneCall(driverPhone);
      _navigateTo('/customer/active-ride');
      _showFeedbackSnackBar('Calling driver ($driverPhone)...');
      return;
    } else if (actionId == actionCallCustomer) {
      await _makePhoneCall(customerPhone);
      _navigateTo('/driver/active-ride');
      _showFeedbackSnackBar('Calling customer ($customerPhone)...');
      return;
    }

    // 2. Accept Ride Action (Driver)
    if (actionId == actionAcceptRide) {
      if (_container != null) {
        final driver = _container!.read(currentDriverProvider) ?? DemoData.demoDriver;
        _container!.read(rideRepositoryProvider.notifier).driverAcceptRide(rideId, driver);
      }
      _navigateTo('/driver/active-ride');
      _showFeedbackSnackBar('Ride $rideId Accepted! Heading to pickup.');
      return;
    }

    // 3. Reject Ride Action (Driver)
    if (actionId == actionRejectRide) {
      if (_container != null) {
        _container!.read(rideRepositoryProvider.notifier).cancelActiveRide('Driver declined');
      }
      _navigateTo('/driver/home');
      _showFeedbackSnackBar('Ride $rideId Declined.');
      return;
    }

    // 4. Cancel Ride Action (Customer)
    if (actionId == actionCancelRide) {
      if (_container != null) {
        _container!.read(rideRepositoryProvider.notifier).cancelActiveRide('Customer cancelled');
      }
      _navigateTo('/customer/home');
      _showFeedbackSnackBar('Ride request cancelled.');
      return;
    }

    // 5. Rate Ride Action (Customer)
    if (actionId == actionRateRide) {
      _navigateTo('/customer/rating');
      return;
    }

    // 6. View Receipt / Earnings
    if (actionId == actionViewReceipt || actionId == actionViewEarnings) {
      if (currentRole == UserRole.driver) {
        _navigateTo('/driver/rides');
      } else {
        _navigateTo('/customer/rides');
      }
      return;
    }

    // 7. Book Again
    if (actionId == actionBookAgain) {
      _navigateTo('/customer/home');
      return;
    }

    // 8. Return Home / Find Rides
    if (actionId == actionDriverHome || actionId == actionFindRides) {
      _navigateTo('/driver/home');
      return;
    }

    // 9. View Alerts / Manage Alerts
    if (actionId == actionViewAlerts) {
      if (currentRole == UserRole.driver) {
        _navigateTo('/driver/notifications');
      } else {
        _navigateTo('/customer/notifications');
      }
      return;
    }
    if (actionId == actionManageAlerts) {
      _navigateTo('/admin/announcements');
      return;
    }

    // 10. View Ride / Track Trip or Default Notification Body Tap
    if (actionId == actionViewRide ||
        actionId == actionTrackRide ||
        actionId == null ||
        actionId.isEmpty) {
      if (currentRole == UserRole.driver) {
        if (typeName == NotificationType.newRideRequest.name) {
          _navigateTo('/driver/home');
        } else if (typeName == NotificationType.rideCompleted.name) {
          _navigateTo('/driver/rides');
        } else {
          _navigateTo('/driver/active-ride');
        }
      } else if (currentRole == UserRole.admin) {
        if (typeName == NotificationType.systemAlert.name ||
            typeName == NotificationType.announcement.name) {
          _navigateTo('/admin/announcements');
        } else {
          _navigateTo('/admin/rides');
        }
      } else {
        // Customer default
        if (typeName == NotificationType.newRideRequest.name) {
          _navigateTo('/customer/searching');
        } else if (typeName == NotificationType.rideCompleted.name) {
          _navigateTo('/customer/rating');
        } else if (typeName == NotificationType.systemAlert.name ||
            typeName == NotificationType.announcement.name) {
          _navigateTo('/customer/notifications');
        } else {
          _navigateTo('/customer/active-ride');
        }
      }
    }
  }

  /// Triggers a test notification for the specified [NotificationType] and [UserRole].
  Future<bool> showTestNotificationForType(
    NotificationType type, {
    UserRole? role,
    bool isMr = false,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    final template = _getSampleNotificationForType(type);
    return showNotificationForModel(
      template,
      userRole: role,
      isMr: isMr,
      playSound: playSound,
      enableVibration: enableVibration,
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('Cannot launch phone dialer for: $cleanPhone');
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }
  }

  void _navigateTo(String route) {
    if (_container != null) {
      final router = _container!.read(appRouterProvider);
      try {
        router.push(route);
        return;
      } catch (e) {
        try {
          router.go(route);
          return;
        } catch (_) {}
      }
    }
    _pendingRoute = route;
  }

  void _showFeedbackSnackBar(String message) {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: BrandConfig.textPrimaryBlack,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  NotificationModel _getSampleNotificationForType(NotificationType type) {
    try {
      return DemoData.demoNotifications.firstWhere((n) => n.type == type);
    } catch (_) {
      return _createFallbackNotification(type);
    }
  }

  NotificationModel _createFallbackNotification(NotificationType type) {
    switch (type) {
      case NotificationType.newRideRequest:
        return const NotificationModel(
          id: 'test_new_request',
          type: NotificationType.newRideRequest,
          category: NotificationCategory.rides,
          titleEn: 'New Ride Request',
          titleMr: 'नवीन राइड विनंती',
          bodyEn: 'A new ride request is nearby.',
          bodyMr: 'जवळपास नवीन राइड विनंती आहे.',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          pickupAddress: 'Dharashiv Central Bus Stand',
          destinationAddress: 'Government Civil Hospital',
          pickupDistance: '2.3 km',
          dropDistance: '6.8 km',
          fare: 120.0,
          actionLabelEn: 'Accept',
          actionLabelMr: 'स्वीकारा',
        );
      case NotificationType.rideAccepted:
        return const NotificationModel(
          id: 'test_ride_accepted',
          type: NotificationType.rideAccepted,
          category: NotificationCategory.rides,
          titleEn: 'Ride Accepted!',
          titleMr: 'राइड स्वीकारली!',
          bodyEn: 'Ramesh Shinde accepted your ride.',
          bodyMr: 'रमेश शिंदे यांनी तुमची राइड स्वीकारली.',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          driverName: 'Ramesh Shinde',
          driverPhone: '9422054321',
          autoNumber: 'MH-25-AZ-4589',
          statusBadgeEn: 'Accepted',
          statusBadgeMr: 'स्वीकारले',
          fare: 120.0,
        );
      case NotificationType.driverArriving:
        return const NotificationModel(
          id: 'test_driver_arriving',
          type: NotificationType.driverArriving,
          category: NotificationCategory.rides,
          titleEn: 'Driver is Arriving',
          titleMr: 'चालक येत आहे',
          bodyEn: 'Ramesh Shinde is on the way.',
          bodyMr: 'रमेश शिंदे पिकअपकडे येत आहेत.',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          driverName: 'Ramesh Shinde',
          driverPhone: '9422054321',
          autoNumber: 'MH-25-AZ-4589',
          distance: '0.5 km away',
          eta: 'ETA: 2 min',
          fare: 120.0,
        );
      case NotificationType.driverArrived:
        return const NotificationModel(
          id: 'test_driver_arrived',
          type: NotificationType.driverArrived,
          category: NotificationCategory.rides,
          titleEn: 'Driver Arrived!',
          titleMr: 'चालक पोहोचला!',
          bodyEn: 'Ramesh Shinde has arrived at your location.',
          bodyMr: 'रमेश शिंदे तुमच्या स्थानावर पोहोचले आहेत.',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          driverName: 'Ramesh Shinde',
          driverPhone: '9422054321',
          autoNumber: 'MH-25-AZ-4589',
          fare: 120.0,
        );
      case NotificationType.rideStarted:
        return const NotificationModel(
          id: 'test_ride_started',
          type: NotificationType.rideStarted,
          category: NotificationCategory.rides,
          titleEn: 'Ride Started',
          titleMr: 'प्रवास सुरू झाला',
          bodyEn: 'Your ride has started.\nEnjoy the ride!',
          bodyMr: 'तुमचा प्रवास सुरू झाला आहे.\nसुखकर प्रवासाच्या शुभेच्छा!',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          driverName: 'Ramesh Shinde',
          driverPhone: '9422054321',
          autoNumber: 'MH-25-AZ-4589',
          fare: 120.0,
        );
      case NotificationType.rideCompleted:
        return const NotificationModel(
          id: 'test_ride_completed',
          type: NotificationType.rideCompleted,
          category: NotificationCategory.rides,
          titleEn: 'Ride Completed 🎉',
          titleMr: 'प्रवास पूर्ण झाला 🎉',
          bodyEn: 'Trip completed successfully!',
          bodyMr: 'प्रवास यशस्वीरीत्या पूर्ण झाला!',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          fare: 120.0,
          distance: '14 km',
          statusBadgeEn: 'Done',
          statusBadgeMr: 'पूर्ण',
        );
      case NotificationType.rideCancelled:
        return const NotificationModel(
          id: 'test_ride_cancelled',
          type: NotificationType.rideCancelled,
          category: NotificationCategory.rides,
          titleEn: 'Ride Cancelled',
          titleMr: 'प्रवास रद्द झाला',
          bodyEn: 'Your ride has been cancelled.',
          bodyMr: 'तुमची राइड रद्द करण्यात आली आहे.',
          timestamp: 'Just now',
          isRead: false,
          rideId: 'RIDE-9021',
          cancelReason: 'Driver unavailable',
          cancelReasonMr: 'चालक अनुपलब्ध',
        );
      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return const NotificationModel(
          id: 'test_alert',
          type: NotificationType.systemAlert,
          category: NotificationCategory.alerts,
          titleEn: 'High Demand Area Alert',
          titleMr: 'जास्त मागणीचा परिसर सूचना',
          bodyEn: 'Peak travel demand detected around Dharashiv Central Bus Stand today.',
          bodyMr: 'मध्यवर्ती बस स्थानक परिसरात आज प्रवाशांची जास्त मागणी आहे.',
          timestamp: 'Just now',
          isRead: false,
        );
    }
  }

  Color _getNotificationColor(NotificationType type) {
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

  String _getNotificationTag(NotificationType type, bool isMr) {
    switch (type) {
      case NotificationType.newRideRequest:
        return isMr ? 'नवीन विनंती' : 'NEW REQUEST';
      case NotificationType.rideAccepted:
        return isMr ? 'स्वीकारले' : 'RIDE ACCEPTED';
      case NotificationType.driverArriving:
        return isMr ? 'चालक येत आहे' : 'DRIVER ARRIVING';
      case NotificationType.driverArrived:
        return isMr ? 'चालक पोहोचला' : 'DRIVER ARRIVED';
      case NotificationType.rideStarted:
        return isMr ? 'प्रवास सुरू' : 'RIDE STARTED';
      case NotificationType.rideCompleted:
        return isMr ? 'पूर्ण झाले' : 'COMPLETED';
      case NotificationType.rideCancelled:
        return isMr ? 'रद्द झाले' : 'CANCELLED';
      case NotificationType.announcement:
      case NotificationType.systemAlert:
        return isMr ? 'सूचना' : 'ALERT';
    }
  }

  int _getStableNotificationId(NotificationType type, String rawId) {
    final base = (type.index + 1) * 1000;
    final timestampOffset = DateTime.now().millisecondsSinceEpoch % 1000;
    return base + timestampOffset;
  }
}

/// Riverpod provider for accessing [LocalNotificationService].
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final service = LocalNotificationService();
  service.initialize();
  return service;
});
