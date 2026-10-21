import 'package:flutter/material.dart';
import '../brand/brand_config.dart';

class AutoRickshawIcon extends StatelessWidget {
  final double size;
  final Color badgeColor;

  const AutoRickshawIcon({
    super.key,
    this.size = 40.0,
    this.badgeColor = BrandConfig.accentYellow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Image.asset(
        'assets/images/ic_app_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.electric_rickshaw,
            size: size * 0.6,
            color: BrandConfig.textPrimaryBlack,
          );
        },
      ),
    );
  }
}
