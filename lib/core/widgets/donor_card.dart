import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'blood_type_badge.dart';
import 'status_chip.dart';

class DonorCard extends StatelessWidget {
  final String name;
  final String bloodType;
  final String distance;
  final String lastDonated;
  final bool isVerified;
  final bool isAvailable;
  final VoidCallback? onCallPressed;
  final VoidCallback? onTap;

  const DonorCard({
    super.key,
    required this.name,
    required this.bloodType,
    required this.distance,
    required this.lastDonated,
    this.isVerified = true,
    this.isAvailable = true,
    this.onCallPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          BloodTypeBadge(
            bloodType: bloodType,
            size: BloodBadgeSize.medium,
            isSelected: true,
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const StatusChip(
                        label: 'Verified',
                        type: StatusType.verified,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last donated: $lastDonated • $distance',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.donorGreen.withValues(alpha: 0.12),
              foregroundColor: AppColors.donorGreen,
            ),
            icon: const Icon(Icons.phone_rounded, size: AppDimensions.iconMD),
            onPressed: onCallPressed,
          ),
        ],
      ),
    );
  }
}
