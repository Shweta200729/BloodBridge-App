import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.healthcareBlue;

    return SizedBox(
      width: width ?? double.infinity,
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: activeColor,
          side: BorderSide(color: activeColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMD,
          ),
          textStyle: AppTypography.labelLarge,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppDimensions.iconMD),
                    const SizedBox(width: AppDimensions.spaceSM),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: activeColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
