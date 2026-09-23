import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'status_chip.dart';

class HospitalCard extends StatelessWidget {
  final String hospitalName;
  final String address;
  final String distance;
  final String stockSummary;
  final bool isOpen247;
  final VoidCallback? onTap;
  final VoidCallback? onDirectionsTap;

  const HospitalCard({
    super.key,
    required this.hospitalName,
    required this.address,
    required this.distance,
    required this.stockSummary,
    this.isOpen247 = true,
    this.onTap,
    this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.healthcareBlue.withValues(alpha: 0.1),
                  borderRadius: AppDimensions.borderRadiusMD,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.healthcareBlue,
                  size: AppDimensions.iconLG,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalName,
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOpen247)
                const StatusChip(
                  label: '24/7',
                  type: StatusType.info,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSM),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: AppDimensions.borderRadiusSM,
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stock: $stockSummary',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  distance,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.healthcareBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
