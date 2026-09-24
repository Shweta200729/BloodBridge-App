import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'blood_type_badge.dart';
import 'status_chip.dart';

class BloodRequestCard extends StatelessWidget {
  final String hospitalName;
  final String bloodType;
  final String unitsRequired;
  final String urgencyLevel;
  final String distance;
  final String patientCaseId;
  final VoidCallback? onRespondTap;
  final VoidCallback? onTap;

  const BloodRequestCard({
    super.key,
    required this.hospitalName,
    required this.bloodType,
    required this.unitsRequired,
    required this.urgencyLevel,
    required this.distance,
    required this.patientCaseId,
    this.onRespondTap,
    this.onTap,
  });

  StatusType _getUrgencyStatusType() {
    switch (urgencyLevel.toUpperCase()) {
      case 'CRITICAL':
      case 'EMERGENCY':
        return StatusType.critical;
      case 'HIGH':
      case 'URGENT':
        return StatusType.urgent;
      default:
        return StatusType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BloodTypeBadge(
                bloodType: bloodType,
                size: BloodBadgeSize.medium,
                showUrgencyRing: urgencyLevel.toUpperCase() == 'CRITICAL',
                isSelected: true,
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
                      'Case ID: $patientCaseId • $unitsRequired Units Required',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: urgencyLevel,
                type: _getUrgencyStatusType(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  distance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.borderRadiusSM,
                  ),
                ),
                onPressed: onRespondTap ?? onTap,
                child: Text(
                  'Respond',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
