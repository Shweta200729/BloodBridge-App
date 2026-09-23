import 'package:flutter/material.dart';
import 'blood_type_badge.dart';

enum BloodChipSize { small, medium, large }

class BloodGroupChip extends StatelessWidget {
  final String bloodGroup;
  final BloodChipSize size;
  final bool isSelected;
  final VoidCallback? onTap;

  const BloodGroupChip({
    super.key,
    required this.bloodGroup,
    this.size = BloodChipSize.medium,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BloodBadgeSize badgeSize;
    switch (size) {
      case BloodChipSize.small:
        badgeSize = BloodBadgeSize.small;
        break;
      case BloodChipSize.medium:
        badgeSize = BloodBadgeSize.medium;
        break;
      case BloodChipSize.large:
        badgeSize = BloodBadgeSize.large;
        break;
    }

    return BloodTypeBadge(
      bloodType: bloodGroup,
      size: badgeSize,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
