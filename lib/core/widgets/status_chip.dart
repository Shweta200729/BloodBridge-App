import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';

enum StatusType { verified, urgent, available, pending, critical, info, success }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusType.info,
    this.icon,
  });

  Color _getBgColor() {
    switch (type) {
      case StatusType.verified:
      case StatusType.available:
      case StatusType.success:
        return AppColors.donorGreen.withValues(alpha: 0.12);
      case StatusType.urgent:
        return AppColors.warning.withValues(alpha: 0.15);
      case StatusType.critical:
        return AppColors.emergencyRed.withValues(alpha: 0.12);
      case StatusType.pending:
        return AppColors.textSecondary.withValues(alpha: 0.12);
      case StatusType.info:
        return AppColors.healthcareBlue.withValues(alpha: 0.12);
    }
  }

  Color _getContentColor() {
    switch (type) {
      case StatusType.verified:
      case StatusType.available:
      case StatusType.success:
        return AppColors.donorGreen;
      case StatusType.urgent:
        return AppColors.warning;
      case StatusType.critical:
        return AppColors.emergencyRed;
      case StatusType.pending:
        return AppColors.textSecondary;
      case StatusType.info:
        return AppColors.healthcareBlue;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case StatusType.verified:
        return Icons.verified_rounded;
      case StatusType.available:
        return Icons.check_circle_outline_rounded;
      case StatusType.success:
        return Icons.check_rounded;
      case StatusType.urgent:
        return Icons.warning_amber_rounded;
      case StatusType.critical:
        return Icons.error_outline_rounded;
      case StatusType.pending:
        return Icons.hourglass_empty_rounded;
      case StatusType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = _getContentColor();
    final chipIcon = icon ?? _getDefaultIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBgColor(),
        borderRadius: AppDimensions.borderRadiusPill,
        border: Border.all(color: contentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 14, color: contentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: contentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
