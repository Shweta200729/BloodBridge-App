import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';

class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
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
              icon: Icon(AppIcons.donor, size: AppDimensions.iconMD),
              label: AppStrings.navDonors,
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
