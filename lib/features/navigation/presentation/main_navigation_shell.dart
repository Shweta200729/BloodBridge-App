import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';

class MainNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final isHospital = userAsync.valueOrNull?.isHospital ?? false;
    final currentBranch = navigationShell.currentIndex;

    // ── Hospital View (4 tabs: Home, Emergency, Donors, Profile) ─────────────
    if (isHospital) {
      int hospitalNavIndex = 0;
      if (currentBranch == 0) {
        hospitalNavIndex = 0;
      } else if (currentBranch == 1) {
        hospitalNavIndex = 1;
      } else if (currentBranch == 2) {
        hospitalNavIndex = 2;
      } else if (currentBranch == 4) {
        hospitalNavIndex = 3;
      } else {
        hospitalNavIndex = 0;
      }

      void onHospitalTap(int index) {
        // Index 0 -> Branch 0 (Home)
        // Index 1 -> Branch 1 (Emergency Requests)
        // Index 2 -> Branch 2 (Donors)
        // Index 3 -> Branch 4 (Profile)
        final targetBranch = index == 0
            ? 0
            : index == 1
                ? 1
                : index == 2
                    ? 2
                    : 4;
        navigationShell.goBranch(
          targetBranch,
          initialLocation: targetBranch == navigationShell.currentIndex,
        );
      }

      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: hospitalNavIndex,
            onTap: onHospitalTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryRed,
            unselectedItemColor: AppColors.lightTextSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(AppIcons.home, size: AppDimensions.iconMD),
                label: AppStrings.navHome,
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.requests, size: AppDimensions.iconMD),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.donor, size: AppDimensions.iconMD),
                label: AppStrings.navDonors,
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.profile, size: AppDimensions.iconMD),
                label: AppStrings.navProfile,
              ),
            ],
          ),
        ),
      );
    }

    // ── Donor View (4 tabs: Home, Requests, Hospitals, Profile) ──────────────
    int donorNavIndex = 0;
    if (currentBranch == 0) {
      donorNavIndex = 0;
    } else if (currentBranch == 1) {
      donorNavIndex = 1;
    } else if (currentBranch == 3) {
      donorNavIndex = 2;
    } else if (currentBranch == 4) {
      donorNavIndex = 3;
    } else {
      donorNavIndex = 0;
    }

    void onDonorTap(int index) {
      // Index 0 -> Branch 0 (Home)
      // Index 1 -> Branch 1 (Requests)
      // Index 2 -> Branch 3 (Hospitals)
      // Index 3 -> Branch 4 (Profile)
      final targetBranch = index == 0
          ? 0
          : index == 1
              ? 1
              : index == 2
                  ? 3
                  : 4;
      navigationShell.goBranch(
        targetBranch,
        initialLocation: targetBranch == navigationShell.currentIndex,
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: donorNavIndex,
          onTap: onDonorTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.lightTextSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(AppIcons.home, size: AppDimensions.iconMD),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(AppIcons.requests, size: AppDimensions.iconMD),
              label: AppStrings.navRequests,
            ),
            BottomNavigationBarItem(
              icon: Icon(AppIcons.hospital, size: AppDimensions.iconMD),
              label: AppStrings.navHospitals,
            ),
            BottomNavigationBarItem(
              icon: Icon(AppIcons.profile, size: AppDimensions.iconMD),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
