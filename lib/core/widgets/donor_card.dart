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
  final String? subtitle;
  final String? distance;
  final String? lastDonated;
  final bool isVerified;
  final bool isAvailable;
  final VoidCallback? onCallPressed;
  final VoidCallback? onTap;

  const DonorCard({
    super.key,
    required this.name,
    required this.bloodType,
    this.subtitle,
    this.distance,
    this.lastDonated,
    this.isVerified = false,
    this.isAvailable = true,
    this.onCallPressed,
    this.onTap,
  });

  String get _resolvedSubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) {
      return subtitle!;
    }
    final List<String> parts = [];
    if (lastDonated != null && lastDonated!.isNotEmpty) {
      parts.add('Last donated: $lastDonated');
    }
    if (distance != null && distance!.isNotEmpty) {
      parts.add(distance!);
    }
    if (parts.isEmpty) {
      return isAvailable ? 'Available donor' : 'Unavailable';
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          BloodTypeBadge(
            bloodType: bloodType.isNotEmpty ? bloodType : 'O+',
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
                        name.isNotEmpty ? name : 'Anonymous Donor',
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
                  _resolvedSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
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
