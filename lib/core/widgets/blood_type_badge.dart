import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_typography.dart';

enum BloodBadgeSize { small, medium, large }

class BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  final BloodBadgeSize size;
  final bool isSelected;
  final bool showUrgencyRing;
  final VoidCallback? onTap;

  const BloodTypeBadge({
    super.key,
    required this.bloodType,
    this.size = BloodBadgeSize.medium,
    this.isSelected = false,
    this.showUrgencyRing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.primaryRed;
    
    double dimension;
    double fontSize;

    switch (size) {
      case BloodBadgeSize.small:
        dimension = 36.0;
        fontSize = 12.0;
        break;
      case BloodBadgeSize.medium:
        dimension = 48.0;
        fontSize = 16.0;
        break;
      case BloodBadgeSize.large:
        dimension = 64.0;
        fontSize = 22.0;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: isSelected
              ? baseColor
              : (isDark
                  ? baseColor.withValues(alpha: 0.2)
                  : baseColor.withValues(alpha: 0.08)),
          shape: BoxShape.circle,
          border: Border.all(
            color: showUrgencyRing
                ? AppColors.emergencyRed
                : (isSelected ? Colors.white : baseColor),
            width: showUrgencyRing ? 3.0 : (isSelected ? 2.5 : 1.5),
          ),
          boxShadow: isSelected || showUrgencyRing
              ? [
                  BoxShadow(
                    color: (showUrgencyRing ? AppColors.emergencyRed : baseColor)
                        .withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            bloodType,
            style: AppTypography.bloodBadgeText.copyWith(
              fontSize: fontSize,
              color: isSelected ? Colors.white : baseColor,
            ),
          ),
        ),
      ),
    );
  }
}
