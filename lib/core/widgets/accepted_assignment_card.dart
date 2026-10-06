import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/emergency_request_model.dart';
import '../models/hospital_model.dart';
import '../router/route_names.dart';
import '../theme/app_typography.dart';
import '../widgets/blood_type_badge.dart';
import '../widgets/status_chip.dart';
import '../../features/hospitals_banks/presentation/widgets/hospital_details_sheet.dart';

class AcceptedAssignmentCard extends StatelessWidget {
  final EmergencyRequestModel request;

  const AcceptedAssignmentCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final caseId = request.patientCaseId ??
        (request.id.length >= 6
            ? request.id.substring(0, 6).toUpperCase()
            : request.id.toUpperCase());

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.donorGreen.withValues(alpha: 0.08),
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(color: AppColors.donorGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.donorGreen.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Badge ──────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.donorGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'YOU ARE THE ACCEPTED DONOR!',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.donorGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                StatusChip(
                  label: request.status == RequestStatus.fulfilled
                      ? 'FULFILLED'
                      : 'ACTION REQUIRED',
                  type: request.status == RequestStatus.fulfilled
                      ? StatusType.info
                      : StatusType.success,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Hospital & Case Summary ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BloodTypeBadge(
                  bloodType: request.bloodGroup,
                  size: BloodBadgeSize.medium,
                  isSelected: true,
                ),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.hospitalName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Case ID: $caseId • ${request.units} Units Required',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Location: ${request.city}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Hospital Contact Instructions Box ─────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.borderRadiusSM,
                border: Border.all(
                    color: AppColors.donorGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.donorGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${request.hospitalName} has selected you for this emergency requirement. Please contact the hospital desk immediately to coordinate transfusion.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Action Buttons (Call, Directions, View Details) ────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.contactPhone != null &&
                    request.contactPhone!.trim().isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.donorGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                    ),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: Text('Call Hospital (${request.contactPhone})'),
                    onPressed: () => HospitalDetailsSheet.launchCall(
                        context, request.contactPhone),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.healthcareBlue,
                    side: const BorderSide(color: AppColors.healthcareBlue),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Directions'),
                  onPressed: () => HospitalDetailsSheet.launchDirections(
                    context,
                    HospitalModel(
                      id: '',
                      name: request.hospitalName,
                      address: request.city,
                      city: request.city,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  label: const Text('View Case'),
                  onPressed: () => context.push(
                    RouteNames.requestDetailRoute(request.id),
                    extra: request,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
