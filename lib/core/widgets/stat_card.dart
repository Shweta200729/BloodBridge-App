import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceSM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppDimensions.borderRadiusSM,
                ),
                child: Icon(icon, color: color, size: AppDimensions.iconMD),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
