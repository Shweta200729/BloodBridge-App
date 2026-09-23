import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/blood_request_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.appName,
        subtitle: 'Every Drop Saves Lives',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.notification, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High Visibility Emergency SOS Button Component
            EmergencyButton(
              onPressed: () => context.push(RouteNames.createRequestPath),
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Statistics Overview
            Text('Live Impact & Network', style: AppTypography.titleMedium),
            const SizedBox(height: AppDimensions.spaceSM),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Urgent Requests',
                    value: '14',
                    icon: AppIcons.requests,
                    color: AppColors.emergencyRed,
                  ),
                ),
                SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: StatCard(
                    title: 'Verified Donors',
                    value: '128',
                    icon: AppIcons.donor,
                    color: AppColors.donorGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Active Emergency Requests Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.activeEmergencyRequests, style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () => context.go(RouteNames.requestsPath),
                  child: Text(
                    'See All',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.healthcareBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSM),

            // BloodRequestCard Components
            BloodRequestCard(
              hospitalName: 'City Central Hospital',
              bloodType: 'O-',
              unitsRequired: '3',
              urgencyLevel: 'CRITICAL',
              distance: '1.2 km away',
              patientCaseId: 'BB-9042',
              onRespondTap: () => context.push(RouteNames.requestsPath),
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            BloodRequestCard(
              hospitalName: 'St. Jude Children Hospital',
              bloodType: 'A+',
              unitsRequired: '2',
              urgencyLevel: 'URGENT',
              distance: '3.5 km away',
              patientCaseId: 'BB-9048',
              onRespondTap: () => context.push(RouteNames.requestsPath),
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Quick Info Healthcare Card
            AppCard(
              backgroundColor: AppColors.healthcareBlue.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.healthcareBlue.withValues(alpha: 0.3)),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.healthcareBlue, size: AppDimensions.iconLG),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Medical Partner Network',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.healthcareBlue,
                          ),
                        ),
                        Text(
                          'All blood banks and hospital requests are cross-verified by medical staff.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
