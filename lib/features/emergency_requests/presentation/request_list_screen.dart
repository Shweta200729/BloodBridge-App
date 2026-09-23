import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/blood_request_card.dart';
import '../../../core/widgets/custom_app_bar.dart';

class RequestListScreen extends StatelessWidget {
  const RequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Emergency Requests',
        subtitle: 'Real-time blood requirement feed',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.filter, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emergencyRed,
        icon: const Icon(AppIcons.add, color: Colors.white),
        label: const Text('New SOS Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push(RouteNames.createRequestPath),
      ),
      body: ListView.separated(
        padding: AppDimensions.screenPadding,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceMD),
        itemBuilder: (context, index) {
          final groups = ['B+', 'O-', 'AB+', 'A-'];
          final hospitals = [
            'Metropolitan General Hospital',
            'Red Cross Blood Center',
            'City Emergency Care',
            'St. Mary Memorial Hospital',
          ];
          final urgencies = ['CRITICAL', 'URGENT', 'CRITICAL', 'HIGH'];
          return BloodRequestCard(
            hospitalName: hospitals[index],
            bloodType: groups[index],
            unitsRequired: '${index + 2}',
            urgencyLevel: urgencies[index],
            distance: '${(index + 1) * 2} km away',
            patientCaseId: 'BB-90${index + 12}',
            onRespondTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Responding to request for ${groups[index]} blood!')),
              );
            },
          );
        },
      ),
    );
  }
}
