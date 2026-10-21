import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../data/models/enums.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  factory StatusBadge.fromRideStatus(RideStatus status) {
    Color bg;
    Color fg = Colors.white;
    switch (status) {
      case RideStatus.searching:
        bg = AppColors.warning;
        break;
      case RideStatus.driverAccepted:
      case RideStatus.driverArriving:
        bg = AppColors.info;
        break;
      case RideStatus.rideStarted:
        bg = AppColors.primaryDark;
        break;
      case RideStatus.rideCompleted:
        bg = AppColors.success;
        break;
      case RideStatus.cancelled:
        bg = AppColors.error;
        break;
    }
    return StatusBadge(label: status.label, color: bg, textColor: fg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
