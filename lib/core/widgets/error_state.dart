import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something Went Wrong',
    this.message = 'We encountered an error loading the data. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconXL,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceXL),
              PrimaryButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                width: 180,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
