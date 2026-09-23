import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/donor_card.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  String _selectedGroup = 'O-';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Find Donors',
        subtitle: 'Connect with verified donors nearby',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.map, color: AppColors.healthcareBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppDimensions.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomTextField(
                  label: '',
                  hint: AppStrings.searchPlaceholder,
                  prefixIcon: AppIcons.search,
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppStrings.bloodGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final group = AppStrings.bloodGroups[index];
                      return BloodTypeBadge(
                        bloodType: group,
                        size: BloodBadgeSize.small,
                        isSelected: _selectedGroup == group,
                        onTap: () => setState(() => _selectedGroup = group),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceMD),
              itemBuilder: (context, index) {
                final names = ['Sarah Jenkins', 'Marcus Vance', 'David Miller', 'Elena Rostova'];
                final distances = ['0.8 km', '2.4 km', '3.1 km', '5.0 km'];
                final dates = ['2 months ago', '1 month ago', '3 weeks ago', 'Eligible now'];
                return DonorCard(
                  name: names[index],
                  bloodType: _selectedGroup,
                  distance: distances[index],
                  lastDonated: dates[index],
                  isVerified: true,
                  onCallPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling donor ${names[index]}...')),
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
