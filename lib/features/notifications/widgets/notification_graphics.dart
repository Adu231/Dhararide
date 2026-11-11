import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/brand/brand_config.dart';

/// Renders a 3D isometric folded paper map with yellow navigation route
/// and a prominent red location pin marker with drop shadow.
class FoldedMapGraphic extends StatelessWidget {
  final double width;
  final double height;

  const FoldedMapGraphic({
    super.key,
    this.width = 68.0,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FoldedMapPainter(),
      ),
    );
  }
}

class _FoldedMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft map ground shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final shadowPath = Path()
      ..moveTo(w * 0.08, h * 0.88)
      ..lineTo(w * 0.92, h * 0.88)
      ..lineTo(w * 0.84, h * 0.96)
      ..lineTo(w * 0.16, h * 0.96)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Three map segments (accordion fold: Left, Center, Right)
    // Left segment: slightly shaded
    final leftPath = Path()
      ..moveTo(w * 0.05, h * 0.46)
      ..lineTo(w * 0.35, h * 0.36)
      ..lineTo(w * 0.35, h * 0.82)
      ..lineTo(w * 0.05, h * 0.92)
      ..close();
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDCE2E8), Color(0xFFCAD3DC)],
      ).createShader(Rect.fromLTWH(w * 0.05, h * 0.36, w * 0.30, h * 0.56));
    canvas.drawPath(leftPath, leftPaint);

    // Center segment: brightest highlight
    final centerPath = Path()
      ..moveTo(w * 0.35, h * 0.36)
      ..lineTo(w * 0.65, h * 0.46)
      ..lineTo(w * 0.65, h * 0.92)
      ..lineTo(w * 0.35, h * 0.82)
      ..close();
    final centerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2F6F9), Color(0xFFE4EBF0)],
      ).createShader(Rect.fromLTWH(w * 0.35, h * 0.36, w * 0.30, h * 0.56));
    canvas.drawPath(centerPath, centerPaint);

    // Right segment: moderate shade
    final rightPath = Path()
      ..moveTo(w * 0.65, h * 0.46)
      ..lineTo(w * 0.95, h * 0.36)
      ..lineTo(w * 0.95, h * 0.82)
      ..lineTo(w * 0.65, h * 0.92)
      ..close();
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFE1E7ED), Color(0xFFD0D9E1)],
      ).createShader(Rect.fromLTWH(w * 0.65, h * 0.36, w * 0.30, h * 0.56));
    canvas.drawPath(rightPath, rightPaint);

    // Grid lines / secondary street details on map panels
    final streetPaint = Paint()
      ..color = const Color(0xFFB8C4CE).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(w * 0.12, h * 0.62), Offset(w * 0.32, h * 0.56), streetPaint);
    canvas.drawLine(Offset(w * 0.38, h * 0.58), Offset(w * 0.60, h * 0.68), streetPaint);
    canvas.drawLine(Offset(w * 0.68, h * 0.70), Offset(w * 0.90, h * 0.60), streetPaint);

    // 3. Bright Yellow Route Path
    final routePaint = Paint()
      ..color = BrandConfig.accentYellow
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.6;

    final routePath = Path()
      ..moveTo(w * 0.12, h * 0.82)
      ..lineTo(w * 0.28, h * 0.70)
      ..lineTo(w * 0.44, h * 0.72)
      ..lineTo(w * 0.52, h * 0.58)
      ..lineTo(w * 0.74, h * 0.54)
      ..lineTo(w * 0.88, h * 0.44);
    canvas.drawPath(routePath, routePaint);

    // Route waypoint dot at start
    final waypointPaint = Paint()..color = const Color(0xFFE6A000);
    canvas.drawCircle(Offset(w * 0.12, h * 0.82), 2.2, waypointPaint);

    // 4. Pin drop shadow on the map
    final pinShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.52, h * 0.60), width: 9, height: 4),
      pinShadowPaint,
    );

    // 5. Red Location Marker Pin
    final pinCenter = Offset(w * 0.52, h * 0.30);
    final pinRadius = w * 0.13;

    final pinPath = Path();
    // Top arc bulb
    pinPath.addArc(
      Rect.fromCircle(center: pinCenter, radius: pinRadius),
      math.pi * 0.75,
      math.pi * 1.5,
    );
    // Taper to bottom tip
    pinPath.lineTo(w * 0.52, h * 0.58);
    pinPath.close();

    final pinPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [Color(0xFFFF5252), Color(0xFFD32F2F), Color(0xFFB71C1C)],
      ).createShader(Rect.fromCircle(center: pinCenter, radius: pinRadius * 1.5));
    canvas.drawPath(pinPath, pinPaint);

    // Inner white dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pinCenter, pinRadius * 0.38, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders the DharRide yellow-and-black auto-rickshaw on road with city skyline background.
class SkylineRickshawGraphic extends StatelessWidget {
  final double width;
  final double height;

  const SkylineRickshawGraphic({
    super.key,
    this.width = 96.0,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SkylineRickshawPainter(),
      ),
    );
  }
}

class _SkylineRickshawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. City skyline silhouette in background
    final skylinePaint = Paint()..color = const Color(0xFFE2E6EC);
    final skyline = Path()
      ..moveTo(w * 0.20, h * 0.75)
      ..lineTo(w * 0.20, h * 0.40)
      ..lineTo(w * 0.32, h * 0.40)
      ..lineTo(w * 0.32, h * 0.26)
      ..lineTo(w * 0.44, h * 0.26)
      ..lineTo(w * 0.44, h * 0.36)
      ..lineTo(w * 0.52, h * 0.36)
      ..lineTo(w * 0.52, h * 0.18)
      ..lineTo(w * 0.62, h * 0.18)
      ..lineTo(w * 0.62, h * 0.30)
      ..lineTo(w * 0.72, h * 0.30)
      ..lineTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.82, h * 0.22)
      ..lineTo(w * 0.82, h * 0.45)
      ..lineTo(w * 0.95, h * 0.45)
      ..lineTo(w * 0.95, h * 0.75)
      ..close();
    canvas.drawPath(skyline, skylinePaint);

    // 2. Asphalt Road patch with perspective
    final roadPaint = Paint()..color = const Color(0xFFEAEDF1);
    final roadPath = Path()
      ..moveTo(w * 0.05, h * 0.88)
      ..lineTo(w * 0.35, h * 0.66)
      ..lineTo(w * 0.98, h * 0.66)
      ..lineTo(w * 0.98, h * 0.96)
      ..lineTo(w * 0.15, h * 0.96)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    // Road dash lines
    final roadDashPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(w * 0.45, h * 0.82), Offset(w * 0.62, h * 0.82), roadDashPaint);
    canvas.drawLine(Offset(w * 0.72, h * 0.82), Offset(w * 0.92, h * 0.82), roadDashPaint);

    // 3. Draw DharRide Auto Rickshaw
    _drawRickshaw(canvas, Offset(w * 0.54, h * 0.64), scale: w * 0.0095);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders DharRide auto-rickshaw with motion / speed streaks on road.
class SpeedRickshawGraphic extends StatelessWidget {
  final double width;
  final double height;

  const SpeedRickshawGraphic({
    super.key,
    this.width = 96.0,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SpeedRickshawPainter(),
      ),
    );
  }
}

class _SpeedRickshawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Dynamic speed lines trailing behind
    final streakPaint = Paint()
      ..color = const Color(0xFFD4D9E2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    streakPaint.strokeWidth = 2.0;
    canvas.drawLine(Offset(w * 0.05, h * 0.35), Offset(w * 0.28, h * 0.35), streakPaint);
    canvas.drawLine(Offset(w * 0.08, h * 0.50), Offset(w * 0.32, h * 0.50), streakPaint);

    streakPaint.strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.02, h * 0.65), Offset(w * 0.24, h * 0.65), streakPaint);
    canvas.drawLine(Offset(w * 0.12, h * 0.24), Offset(w * 0.26, h * 0.24), streakPaint);

    // 2. Asphalt road
    final roadPaint = Paint()..color = const Color(0xFFECEFF3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.74, w * 0.82, h * 0.18),
        const Radius.circular(6),
      ),
      roadPaint,
    );

    // 3. Rickshaw in motion
    _drawRickshaw(canvas, Offset(w * 0.58, h * 0.60), scale: w * 0.0098);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders DharRide auto-rickshaw with an overlaid circular red (X) badge.
class CancelledRickshawGraphic extends StatelessWidget {
  final double width;
  final double height;

  const CancelledRickshawGraphic({
    super.key,
    this.width = 96.0,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CancelledRickshawPainter(),
      ),
    );
  }
}

class _CancelledRickshawPainter extends CustomPainter {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft base road patch
    final roadPaint = Paint()..color = const Color(0xFFF1F3F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.74, w * 0.85, h * 0.18),
        const Radius.circular(6),
      ),
      roadPaint,
    );

    // 2. Auto Rickshaw
    _drawRickshaw(canvas, Offset(w * 0.44, h * 0.58), scale: w * 0.0095);

    // 3. Overlaid Red Circular Badge with white 'X'
    final badgeCenter = Offset(w * 0.80, h * 0.72);
    const badgeRadius = 13.0;

    // Badge shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(badgeCenter.translate(0, 1.5), badgeRadius, shadowPaint);

    // White outer border
    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(badgeCenter, badgeRadius + 2.0, borderPaint);

    // Red solid fill
    final redPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawCircle(badgeCenter, badgeRadius, redPaint);

    // White 'X' symbol
    final xPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const crossSize = 5.0;
    canvas.drawLine(
      badgeCenter.translate(-crossSize, -crossSize),
      badgeCenter.translate(crossSize, crossSize),
      xPaint,
    );
    canvas.drawLine(
      badgeCenter.translate(crossSize, -crossSize),
      badgeCenter.translate(-crossSize, crossSize),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper function to draw the iconic DharRide yellow & black auto-rickshaw
void _drawRickshaw(Canvas canvas, Offset origin, {double scale = 1.0}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(scale);

  // Rickshaw drop shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
  canvas.drawOval(
    const Rect.fromLTWH(-28, 14, 56, 7),
    shadowPaint,
  );

  // 1. Black Lower Body / Chassis
  final bodyPaint = Paint()..color = const Color(0xFF181818);
  final bodyPath = Path()
    ..moveTo(-24, 6)
    ..lineTo(-25, 12)
    ..lineTo(21, 12)
    ..lineTo(23, 7)
    ..lineTo(14, 2)
    ..lineTo(-18, 2)
    ..close();
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-24, 2, 46, 11), const Radius.circular(2.5)),
    bodyPaint,
  );

  // 2. Yellow Canopy & Hood (DharRide signature yellow #FFC107)
  final yellowPaint = Paint()..color = BrandConfig.accentYellow;
  final roofPath = Path()
    ..moveTo(-22, -14)
    ..quadraticBezierTo(2, -18, 14, -13)
    ..lineTo(22, 2)
    ..lineTo(15, 2)
    ..lineTo(11, -8)
    ..lineTo(-20, -8)
    ..lineTo(-22, -14)
    ..close();
  canvas.drawPath(roofPath, yellowPaint);

  // Curved top canopy sheet
  final canopyRect = RRect.fromRectAndCorners(
    const Rect.fromLTWH(-24, -16, 38, 7),
    topLeft: const Radius.circular(6),
    topRight: const Radius.circular(6),
    bottomLeft: const Radius.circular(1),
    bottomRight: const Radius.circular(1),
  );
  canvas.drawRRect(canopyRect, yellowPaint);

  // Rear yellow hood panel
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -9, 8, 12), const Radius.circular(2)),
    yellowPaint,
  );

  // Front yellow mudguard
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(13, 3, 11, 7), const Radius.circular(2)),
    yellowPaint,
  );

  // 3. Windshield & Cabin Window
  final glassPaint = Paint()..color = const Color(0xFFD6E4EF);
  final glassPath = Path()
    ..moveTo(10, -8)
    ..lineTo(19, 1)
    ..lineTo(13, 1)
    ..lineTo(6, -8)
    ..close();
  canvas.drawPath(glassPath, glassPaint);

  // Cabin interior opening (dark hollow)
  final interiorPaint = Paint()..color = const Color(0xFF2B2B2B);
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -8, 18, 11), const Radius.circular(2)),
    interiorPaint,
  );

  // Driver seat / handlebar hint
  final seatPaint = Paint()..color = const Color(0xFF0F0F0F);
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -2, 6, 6), const Radius.circular(1)),
    seatPaint,
  );

  // 4. Wheels
  final tirePaint = Paint()..color = const Color(0xFF141414);
  final rimPaint = Paint()..color = const Color(0xFF9E9E9E);
  final hubPaint = Paint()..color = const Color(0xFF333333);

  // Front Wheel
  canvas.drawCircle(const Offset(18, 13), 5.5, tirePaint);
  canvas.drawCircle(const Offset(18, 13), 3.0, rimPaint);
  canvas.drawCircle(const Offset(18, 13), 1.2, hubPaint);

  // Rear Wheel
  canvas.drawCircle(const Offset(-16, 13), 5.8, tirePaint);
  canvas.drawCircle(const Offset(-16, 13), 3.2, rimPaint);
  canvas.drawCircle(const Offset(-16, 13), 1.3, hubPaint);

  // 5. Headlight beam / lamp
  final lampPaint = Paint()..color = const Color(0xFFFFF176);
  canvas.drawCircle(const Offset(23, 5), 2.0, lampPaint);

  canvas.restore();
}

