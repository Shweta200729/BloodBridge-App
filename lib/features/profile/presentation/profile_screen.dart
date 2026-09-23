import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/storage_preference_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/status_chip.dart';

final themeModeNotifierProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final Ref _ref;
  ThemeModeNotifier(this._ref) : super(false);

  void toggleTheme() {
    state = !state;
    _ref.read(storagePreferenceServiceProvider).setDarkMode(state);
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Donor Profile',
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? AppIcons.lightMode : AppIcons.darkMode,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.spaceMD),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarXL / 2,
                    backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                    child: Text(
                      'JD',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const BloodTypeBadge(
                    bloodType: 'O-',
                    size: BloodBadgeSize.small,
                    isSelected: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('John Doe', style: AppTypography.titleLarge),
                const SizedBox(width: 6),
                const StatusChip(label: 'Verified Donor', type: StatusType.verified),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'john.doe@example.com • +1 (555) 019-2831',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfileStat('Donations', '5 Times'),
                  Container(height: 30, width: 1, color: AppColors.borderLight),
                  _buildProfileStat('Lives Saved', '15 Lives'),
                  Container(height: 30, width: 1, color: AppColors.borderLight),
                  _buildProfileStat('Eligibility', 'Eligible Now'),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(AppIcons.donor, color: AppColors.primaryRed),
                    title: const Text('Donation History'),
                    trailing: const Icon(AppIcons.forward, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.settings, color: AppColors.healthcareBlue),
                    title: const Text('Account Settings'),
                    trailing: const Icon(AppIcons.forward, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.signOut, color: AppColors.error),
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    onTap: () => context.go(RouteNames.loginPath),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.primaryRed)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
      ],
    );
  }
}
