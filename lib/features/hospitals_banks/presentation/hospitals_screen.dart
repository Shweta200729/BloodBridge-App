import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/hospital_card.dart';

class HospitalsScreen extends StatelessWidget {
  const HospitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Hospitals & Blood Banks',
        subtitle: 'Real-time blood stock inventory',
      ),
      body: ListView.separated(
        padding: AppDimensions.screenPadding,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceMD),
        itemBuilder: (context, index) {
          final centers = [
            'Red Cross Regional Blood Center',
            'St. Michael University Hospital',
            'LifeSource Blood Bank & Research',
            'Mercy General Emergency Center',
          ];
          final addresses = [
            '124 Medical Plaza Blvd, District 4',
            '88 Healthcare Ave, Downtown',
            '502 Vitality Way, Sector 12',
            '771 Hope Street, North Wing',
          ];
          final stockLevels = [
            'O+ (12 units), A+ (8 units)',
            'B+ (15 units), O- (3 units)',
            'AB+ (9 units), O+ (20 units)',
            'A- (5 units), B- (2 units)',
          ];
          return HospitalCard(
            hospitalName: centers[index],
            address: addresses[index],
            distance: '${(index + 1) * 1.8} km away',
            stockSummary: stockLevels[index],
            isOpen247: true,
            onTap: () {},
          );
        },
      ),
    );
  }
}
