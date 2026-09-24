import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/donor_card.dart';
import 'widgets/donor_details_sheet.dart';

class DonorSearchScreen extends ConsumerStatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  ConsumerState<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends ConsumerState<DonorSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGroup = 'All';

  final List<String> _filterGroups = ['All', ...AppStrings.bloodGroups];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableDonorsAsync = ref.watch(availableDonorsStreamProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Find Donors',
        subtitle: 'Connect with available blood donors',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMD,
              vertical: AppDimensions.spaceSM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Field
                CustomTextField(
                  controller: _searchController,
                  label: '',
                  hint: 'Search by donor name or city...',
                  prefixIcon: AppIcons.search,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                // 8 Blood Groups + All Filter Selector
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final group = _filterGroups[index];
                      final isSelected = _selectedGroup == group;

                      if (group == 'All') {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGroup = 'All'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryRed
                                  : AppColors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMD),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryRed
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Text(
                              'All Types',
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      return BloodTypeBadge(
                        bloodType: group,
                        size: BloodBadgeSize.small,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedGroup = group),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Transparency Notice regarding Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSM,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.healthcareBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Showing donors opted in for donations. Locations are based on self-reported city/area.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spaceSM),

          // Donor List Body with Loading, Empty, and Error States
          Expanded(
            child: availableDonorsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(
                        'Unable to load donors',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AuthService.getReadableErrorMessage(err),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        onPressed: () => ref.refresh(availableDonorsStreamProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allDonors) {
                // Filter by Blood Group
                var filtered = allDonors.where((d) {
                  if (_selectedGroup == 'All') return true;
                  return d.bloodGroup.toUpperCase() == _selectedGroup.toUpperCase();
                }).toList();

                // Filter by Search Query (Name or City)
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filtered = filtered.where((d) {
                    final nameMatch = d.fullName.toLowerCase().contains(query);
                    final cityMatch = d.city.toLowerCase().contains(query);
                    return nameMatch || cityMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.spaceXL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spaceLG),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_search_rounded,
                              size: 54,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            'No Available Donors Found',
                            style: AppTypography.titleLarge,
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            _selectedGroup != 'All'
                                ? 'No donors for blood group $_selectedGroup are currently marked as available.'
                                : 'No donors currently match your search criteria.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            'Only users who have explicitly enabled "Available to Donate Blood" in their profile appear in search results.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceMD,
                    vertical: AppDimensions.spaceSM,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.spaceMD),
                  itemBuilder: (context, index) {
                    final donor = filtered[index];
                    final subtitle = donor.city.isNotEmpty
                        ? '${donor.city} • Available'
                        : 'Available donor';

                    return DonorCard(
                      name: donor.fullName,
                      bloodType: donor.bloodGroup,
                      subtitle: subtitle,
                      isVerified: donor.isVerified,
                      isAvailable: donor.isDonorAvailable,
                      onTap: () => DonorDetailsSheet.show(context, donor),
                      onCallPressed: () =>
                          DonorDetailsSheet.show(context, donor),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
