import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/hospital_model.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'status_chip.dart';

class HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final String? distanceText;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onDirectionsTap;

  const HospitalCard({
    super.key,
    required this.hospital,
    this.distanceText,
    this.onTap,
    this.onCallTap,
    this.onDirectionsTap,
  });

  IconData _iconForType(HospitalType type) {
    switch (type) {
      case HospitalType.bloodBank:
        return Icons.water_drop_rounded;
      case HospitalType.clinic:
        return Icons.medical_services_rounded;
      case HospitalType.hospital:
        return Icons.local_hospital_rounded;
    }
  }

  Color _colorForType(HospitalType type) {
    switch (type) {
      case HospitalType.bloodBank:
        return AppColors.primaryRed;
      case HospitalType.clinic:
      case HospitalType.hospital:
        return AppColors.healthcareBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(hospital.type);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: AppDimensions.borderRadiusMD,
                ),
                child: Icon(
                  _iconForType(hospital.type),
                  color: typeColor,
                  size: AppDimensions.iconLG,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hospital.address}${hospital.city.isNotEmpty ? ', ${hospital.city}' : ''}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSM),

          // Badges row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (distanceText != null)
                StatusChip(
                  label: distanceText!,
                  type: StatusType.info,
                  icon: Icons.near_me_rounded,
                ),
              StatusChip(
                label: hospital.type.label,
                type: StatusType.info,
              ),
              if (hospital.isSampleData)
                const StatusChip(
                  label: 'Sample / Unverified',
                  type: StatusType.pending,
                )
              else if (hospital.isVerified)
                const StatusChip(
                  label: 'Verified Facility',
                  type: StatusType.success,
                ),
              if (hospital.operatingHours != null &&
                  hospital.operatingHours!.isNotEmpty)
                StatusChip(
                  label: hospital.operatingHours!,
                  type: StatusType.available,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),

          // Disclaimer notice: No fabricated stock
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceSM,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: AppDimensions.borderRadiusSM,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Contact facility directly to verify current blood stock.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hospital.hasPhone && onCallTap != null)
                TextButton.icon(
                  onPressed: onCallTap,
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Call'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if ((hospital.hasCoordinates || hospital.hasAddress) &&
                  onDirectionsTap != null)
                TextButton.icon(
                  onPressed: onDirectionsTap,
                  icon: const Icon(Icons.directions_outlined, size: 16),
                  label: const Text('Directions'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.healthcareBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                label: const Text('Details'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
