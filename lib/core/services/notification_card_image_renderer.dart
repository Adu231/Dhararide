import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../brand/brand_config.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';

/// Renders high-definition, pixel-perfect bitmap cards representing the
/// DharRide visual notification templates for native Android notifications.
class NotificationCardImageRenderer {
  static final Map<String, Uint8List> _imageCache = {};

  /// Generates a crisp, safe-size PNG bitmap of the DharRide notification card.
  static Future<Uint8List> renderCardBitmap({
    required NotificationType type,
    required UserRole role,
    required bool isMr,
    required NotificationModel notification,
    double width = 500.0,
    double height = 250.0,
  }) async {
    final cacheKey =
        '${type.name}_${role.name}_${isMr ? "mr" : "en"}_${notification.fare}_${notification.id}_${notification.statusBadgeEn}';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    canvas.save();
    canvas.scale(width / 800.0, height / 400.0);

    _paintCard(
      canvas: canvas,
      size: const Size(800.0, 400.0),
      type: type,
      role: role,
      isMr: isMr,
      notification: notification,
    );

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    _imageCache[cacheKey] = bytes;
    return bytes;
  }

  static void _paintCard({
    required Canvas canvas,
    required Size size,
    required NotificationType type,
    required UserRole role,
    required bool isMr,
    required NotificationModel notification,
  }) {
    final w = size.width;
    final h = size.height;

    // 1. Base Card Background (Clean Card with Subtle Elevation & Border)
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, w - 20, h - 20),
      const Radius.circular(28),
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(bgRect.shift(const Offset(0, 4)), shadowPaint);

    // Card Surface
    final surfacePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(bgRect, surfacePaint);

    // Card Outline Border
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bgRect, borderPaint);

    // 2. Top Header: DharRide Yellow Circular Logo + App Name + Timestamp/Bell
    final logoCenter = const Offset(48, 48);
    final logoBadgePaint = Paint()..color = BrandConfig.accentYellow;
    canvas.drawCircle(logoCenter, 22, logoBadgePaint);

    // Auto rickshaw icon silhouette inside badge
    _drawAutoRickshawSilhouette(canvas, logoCenter);

    // Brand Label
    _drawText(
      canvas: canvas,
      text: '${BrandConfig.appName} • ${notification.timestamp == "Just now" ? (isMr ? "आता" : "Now") : notification.timestamp}',
      offset: const Offset(82, 36),
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1E293B),
    );

    // Bell & Tag pill on top right
    _drawHeaderTag(
      canvas: canvas,
      offset: Offset(w - 190, 32),
      isMr: isMr,
      type: type,
    );

    // 3. Card Title and Subtitle
    final title = _getTitle(type, role, isMr, notification);
    final subtitle = _getSubtitle(type, role, isMr, notification);

    _drawText(
      canvas: canvas,
      text: title,
      offset: const Offset(40, 92),
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF0F172A),
    );

    _drawText(
      canvas: canvas,
      text: subtitle,
      offset: const Offset(40, 134),
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF64748B),
    );

    // 4. Center Visual Feature Box (Specific to Notification Type)
    _drawFeatureBox(
      canvas: canvas,
      rect: Rect.fromLTWH(36, 175, w - 72, 125),
      type: type,
      role: role,
      isMr: isMr,
      notification: notification,
    );

    // 5. Bottom Action Button Representation (Pill button with matching design)
    _drawActionButton(
      canvas: canvas,
      rect: Rect.fromLTWH(36, 318, w - 72, 48),
      type: type,
      role: role,
      isMr: isMr,
    );
  }

  static void _drawAutoRickshawSilhouette(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.55);

    final blackPaint = Paint()..color = const Color(0xFF111111);

    // Body
    final bodyPath = Path()
      ..moveTo(-16, -6)
      ..lineTo(10, -6)
      ..lineTo(14, 2)
      ..lineTo(-16, 2)
      ..close();
    canvas.drawPath(bodyPath, blackPaint);

    // Roof
    final roofPath = Path()
      ..moveTo(-15, -14)
      ..quadraticBezierTo(0, -17, 10, -13)
      ..lineTo(14, -6)
      ..lineTo(-16, -6)
      ..close();
    canvas.drawPath(roofPath, blackPaint);

    // Wheels
    canvas.drawCircle(const Offset(-10, 8), 4.5, blackPaint);
    canvas.drawCircle(const Offset(10, 8), 4.5, blackPaint);

    canvas.restore();
  }

  static void _drawHeaderTag({
    required Canvas canvas,
    required Offset offset,
    required bool isMr,
    required NotificationType type,
  }) {
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx, offset.dy, 150, 32),
      const Radius.circular(16),
    );
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRRect(pillRect, bgPaint);

    final tagText = _getTagLabel(type, isMr);
    _drawText(
      canvas: canvas,
      text: tagText,
      offset: Offset(offset.dx + 16, offset.dy + 6),
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF334155),
    );
  }

  static void _drawFeatureBox({
    required Canvas canvas,
    required Rect rect,
    required NotificationType type,
    required UserRole role,
    required bool isMr,
    required NotificationModel notification,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final boxPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRRect(rrect, boxPaint);

    final boxBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect, boxBorder);

    final fare = notification.fare != null ? '₹ ${notification.fare!.toInt()}' : '₹ 120';
    final dist = notification.distance ?? (type == NotificationType.rideCompleted ? '14 km' : '2.3 km');
    final driverName = notification.driverName ?? 'Ramesh Shinde';
    final autoNumber = notification.autoNumber ?? 'MH-25-AZ-4589';

    switch (type) {
      case NotificationType.rideCompleted:
        // 3-Column Layout: Fare | Distance | Done Badge (Exact replica of user screenshot!)
        final colWidth = rect.width / 3;

        // Col 1: Fare
        _drawText(
          canvas: canvas,
          text: fare,
          offset: Offset(rect.left + 24, rect.top + 28),
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0F172A),
        );
        _drawText(
          canvas: canvas,
          text: isMr ? 'एकूण भाडे' : 'Total Fare',
          offset: Offset(rect.left + 24, rect.top + 68),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        );

        // Divider 1
        canvas.drawLine(
          Offset(rect.left + colWidth, rect.top + 20),
          Offset(rect.left + colWidth, rect.bottom - 20),
          Paint()
            ..color = const Color(0xFFCBD5E1)
            ..strokeWidth = 1.2,
        );

        // Col 2: Distance
        _drawText(
          canvas: canvas,
          text: '📍 $dist',
          offset: Offset(rect.left + colWidth + 24, rect.top + 28),
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        );
        _drawText(
          canvas: canvas,
          text: isMr ? 'एकूण अंतर' : 'Distance',
          offset: Offset(rect.left + colWidth + 24, rect.top + 68),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        );

        // Divider 2
        canvas.drawLine(
          Offset(rect.left + colWidth * 2, rect.top + 20),
          Offset(rect.left + colWidth * 2, rect.bottom - 20),
          Paint()
            ..color = const Color(0xFFCBD5E1)
            ..strokeWidth = 1.2,
        );

        // Col 3: Done Yellow Pill Badge
        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + colWidth * 2 + 20, rect.top + 40, colWidth - 40, 44),
          const Radius.circular(22),
        );
        canvas.drawRRect(badgeRect, Paint()..color = BrandConfig.accentYellow);
        _drawText(
          canvas: canvas,
          text: isMr ? '✓ पूर्ण' : '✓ Done',
          offset: Offset(rect.left + colWidth * 2 + 40, rect.top + 48),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: BrandConfig.textPrimaryBlack,
        );
        break;

      case NotificationType.rideAccepted:
      case NotificationType.driverArriving:
      case NotificationType.driverArrived:
        // Driver details box + Vehicle plate + Green Accepted badge
        _drawText(
          canvas: canvas,
          text: '👤 $driverName',
          offset: Offset(rect.left + 24, rect.top + 26),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        );
        _drawText(
          canvas: canvas,
          text: '🛺 $autoNumber • Bajaj Compact CNG',
          offset: Offset(rect.left + 24, rect.top + 64),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        );

        // Status badge
        final rightBadgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.right - 180, rect.top + 38, 156, 44),
          const Radius.circular(22),
        );
        final isArrived = type == NotificationType.driverArrived;
        final badgeColor = isArrived ? BrandConfig.accentYellow : const Color(0xFFDCFCE7);
        final badgeTextColor = isArrived ? BrandConfig.textPrimaryBlack : const Color(0xFF166534);

        canvas.drawRRect(rightBadgeRect, Paint()..color = badgeColor);
        _drawText(
          canvas: canvas,
          text: isArrived
              ? (isMr ? 'पोहोचला' : 'Arrived')
              : (isMr ? 'स्वीकारले' : 'Accepted'),
          offset: Offset(rect.right - 146, rect.top + 48),
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: badgeTextColor,
        );
        break;

      case NotificationType.newRideRequest:
        // Pickup & Drop distances + Estimated fare
        _drawText(
          canvas: canvas,
          text: '$fare (0% Commission)',
          offset: Offset(rect.left + 24, rect.top + 24),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0F172A),
        );
        _drawText(
          canvas: canvas,
          text: '📍 ${notification.pickupDistance ?? "2.3 km"} Pickup  •  🏁 ${notification.dropDistance ?? "6.8 km"} Drop',
          offset: Offset(rect.left + 24, rect.top + 64),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        );
        break;

      case NotificationType.rideStarted:
        _drawText(
          canvas: canvas,
          text: isMr ? 'प्रवास सुरू झाला (सुरक्षित प्रवास)' : 'Trip in Progress (Dharashiv Safe)',
          offset: Offset(rect.left + 24, rect.top + 26),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        );
        _drawText(
          canvas: canvas,
          text: '🏁 ${notification.destinationAddress ?? "Government Civil Hospital"}  ($fare)',
          offset: Offset(rect.left + 24, rect.top + 64),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        );
        break;

      case NotificationType.rideCancelled:
        _drawText(
          canvas: canvas,
          text: isMr ? 'प्रवास रद्द करण्यात आला' : 'Trip Cancelled',
          offset: Offset(rect.left + 24, rect.top + 26),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFDC2626),
        );
        _drawText(
          canvas: canvas,
          text: isMr ? 'पुन्हा शोधण्यासाठी टॅप करा' : 'Tap to rebook auto nearby',
          offset: Offset(rect.left + 24, rect.top + 64),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        );
        break;

      case NotificationType.systemAlert:
      case NotificationType.announcement:
        _drawText(
          canvas: canvas,
          text: '📢 0% Commission Active in Dharashiv',
          offset: Offset(rect.left + 24, rect.top + 26),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        );
        _drawText(
          canvas: canvas,
          text: isMr ? 'चालकांसाठी कोणतेही कमिशन नाही' : '100% Direct Driver Fare Guarantee',
          offset: Offset(rect.left + 24, rect.top + 64),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        );
        break;
    }
  }

  static void _drawActionButton({
    required Canvas canvas,
    required Rect rect,
    required NotificationType type,
    required UserRole role,
    required bool isMr,
  }) {
    final pillRect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    if (type == NotificationType.newRideRequest) {
      // Two action buttons: Accept (Yellow) & Decline (White)
      final halfWidth = (rect.width - 16) / 2;
      final acceptRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, halfWidth, rect.height),
        const Radius.circular(24),
      );
      canvas.drawRRect(acceptRect, Paint()..color = BrandConfig.accentYellow);
      _drawText(
        canvas: canvas,
        text: isMr ? 'स्वीकारा (Accept)' : 'Accept',
        offset: Offset(rect.left + halfWidth / 2 - 38, rect.top + 14),
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: BrandConfig.textPrimaryBlack,
      );

      final declineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + halfWidth + 16, rect.top, halfWidth, rect.height),
        const Radius.circular(24),
      );
      canvas.drawRRect(declineRect, Paint()..color = const Color(0xFFF1F5F9));
      canvas.drawRRect(
        declineRect,
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      _drawText(
        canvas: canvas,
        text: isMr ? 'नाकारा (Decline)' : 'Decline',
        offset: Offset(rect.left + halfWidth + 16 + halfWidth / 2 - 40, rect.top + 14),
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF334155),
      );
    } else {
      // Single full-width styled button matching Image 1
      final isYellow = type == NotificationType.rideStarted ||
          type == NotificationType.rideAccepted ||
          type == NotificationType.driverArrived;

      final bgPaint = Paint()..color = isYellow ? BrandConfig.accentYellow : const Color(0xFFFFFFFF);
      canvas.drawRRect(pillRect, bgPaint);

      final borderPaint = Paint()
        ..color = isYellow ? BrandConfig.accentYellowDark : const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(pillRect, borderPaint);

      final label = _getButtonLabel(type, role, isMr);
      _drawText(
        canvas: canvas,
        text: label,
        offset: Offset(rect.left + rect.width / 2 - (label.length * 4.6), rect.top + 14),
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: BrandConfig.textPrimaryBlack,
      );
    }
  }

  static String _getTitle(
    NotificationType type,
    UserRole role,
    bool isMr,
    NotificationModel notif,
  ) {
    switch (type) {
      case NotificationType.newRideRequest:
        return isMr ? 'नवीन राइड विनंती' : 'New Ride Request';
      case NotificationType.rideAccepted:
        return isMr ? 'राइड स्वीकारली!' : 'Ride Accepted!';
      case NotificationType.driverArriving:
        return isMr ? 'चालक येत आहे' : 'Driver is Arriving';
      case NotificationType.driverArrived:
        return isMr ? 'चालक पोहोचला!' : 'Driver Arrived!';
      case NotificationType.rideStarted:
        return isMr ? 'प्रवास सुरू झाला' : 'Ride Started';
      case NotificationType.rideCompleted:
        return isMr ? 'प्रवास पूर्ण झाला 🎉' : 'Ride Completed 🎉';
      case NotificationType.rideCancelled:
        return isMr ? 'प्रवास रद्द झाला' : 'Ride Cancelled';
      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return isMr ? 'महत्त्वाची सूचना' : 'System Notice';
    }
  }

  static String _getSubtitle(
    NotificationType type,
    UserRole role,
    bool isMr,
    NotificationModel notif,
  ) {
    switch (type) {
      case NotificationType.newRideRequest:
        return isMr ? 'जवळपास नवीन राइड उपलब्ध आहे.' : 'A new ride request is nearby.';
      case NotificationType.rideAccepted:
        return isMr ? '${notif.driverName ?? "रमेश शिंदे"} यांनी राइड स्वीकारली.' : '${notif.driverName ?? "Ramesh Shinde"} accepted your ride.';
      case NotificationType.driverArriving:
        return isMr ? 'चालक पिकअप स्थानाकडे येत आहेत.' : 'Driver is on the way to pickup.';
      case NotificationType.driverArrived:
        return isMr ? 'चालक तुमच्या स्थानावर पोहोचले आहेत.' : 'Driver has arrived at your location.';
      case NotificationType.rideStarted:
        return isMr ? 'सुरक्षित प्रवासाच्या शुभेच्छा!' : 'Heading towards destination.';
      case NotificationType.rideCompleted:
        return isMr ? 'प्रवास यशस्वीरीत्या पूर्ण झाला!' : 'Trip completed successfully!';
      case NotificationType.rideCancelled:
        return isMr ? 'प्रवास रद्द करण्यात आला.' : 'Trip was cancelled.';
      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return isMr ? 'धाराशिवसाठी ०% कमिशन' : 'Zero commission active in Dharashiv.';
    }
  }

  static String _getTagLabel(NotificationType type, bool isMr) {
    switch (type) {
      case NotificationType.newRideRequest:
        return isMr ? 'नवीन विनंती' : 'New Request';
      case NotificationType.rideAccepted:
        return isMr ? 'स्वीकारले' : 'Accepted';
      case NotificationType.driverArriving:
        return isMr ? 'येत आहे' : 'Arriving';
      case NotificationType.driverArrived:
        return isMr ? 'पोहोचला' : 'Arrived';
      case NotificationType.rideStarted:
        return isMr ? 'सुरू आहे' : 'In Progress';
      case NotificationType.rideCompleted:
        return isMr ? 'पूर्ण झाले' : 'Completed';
      case NotificationType.rideCancelled:
        return isMr ? 'रद्द' : 'Cancelled';
      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return isMr ? 'सूचना' : 'Alert';
    }
  }

  static String _getButtonLabel(NotificationType type, UserRole role, bool isMr) {
    switch (type) {
      case NotificationType.newRideRequest:
        return isMr ? 'स्वीकारा' : 'Accept';
      case NotificationType.rideAccepted:
        return isMr ? 'राइड पहा' : 'View Ride';
      case NotificationType.driverArriving:
        return isMr ? 'थेट पहा' : 'View Live';
      case NotificationType.driverArrived:
        return isMr ? 'राइड उघडा' : 'View Ride';
      case NotificationType.rideStarted:
        return isMr ? 'मार्ग पहा' : 'View Route';
      case NotificationType.rideCompleted:
        return isMr ? 'तपशील पहा' : 'View Details';
      case NotificationType.rideCancelled:
        return isMr ? 'पुन्हा बुक करा' : 'Rebook Auto';
      case NotificationType.systemAlert:
      case NotificationType.announcement:
        return isMr ? 'तपशील' : 'Details';
    }
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: 'Roboto',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }
}

