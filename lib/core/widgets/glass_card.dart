import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surfaceWhite);

    final cardBorder = border ??
        Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          width: 1,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.borderRadiusLG,
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppDimensions.spaceMD),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppDimensions.borderRadiusLG,
            border: cardBorder,
            boxShadow: AppColors.softShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
