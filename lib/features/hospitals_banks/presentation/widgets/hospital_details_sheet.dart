import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/hospital_model.dart';
import '../../../../core/services/hospital_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';

class HospitalDetailsSheet extends ConsumerWidget {
  final HospitalModel hospital;

  const HospitalDetailsSheet({super.key, required this.hospital});

  /// Opens this details bottom sheet.
  static void show(BuildContext context, HospitalModel hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HospitalDetailsSheet(hospital: hospital),
    );
  }

  /// Safely initiates a phone call or copies number to clipboard on failure.
  static Future<void> launchCall(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact phone number is not available for this facility.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$sanitized');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: phone));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open dialer. Phone number $phone copied to clipboard.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $phone to clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens an external maps application via coordinates or encoded address.
  static Future<void> launchDirections(BuildContext context, HospitalModel hospital) async {
    if (!hospital.hasCoordinates && !hospital.hasAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Directions unavailable: facility has no coordinates or address.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Uri? targetUri;
    if (hospital.hasCoordinates) {
      // Try geo: intent URI with fallback to universal web maps search
      targetUri = Uri.parse(
        'geo:${hospital.latitude},${hospital.longitude}?q=${hospital.latitude},${hospital.longitude}(${Uri.encodeComponent(hospital.name)})',
      );
    } else {
      targetUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${hospital.name} ${hospital.address}')}',
      );
    }

    try {
      final launched = await launchUrl(targetUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to web search
        final webFallback = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${hospital.hasCoordinates ? '${hospital.latitude},${hospital.longitude}' : Uri.encodeComponent('${hospital.name} ${hospital.address}')}',
        );
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open external navigation application.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Copies full facility address to system clipboard.
  static Future<void> copyAddress(BuildContext context, String address) async {
    if (address.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: address));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullAddress = '${hospital.address}${hospital.city.isNotEmpty ? ', ${hospital.city}' : ''}';
    final userPos = ref.watch(userLocationProvider);
    final distanceText = hospital.formattedDistanceTo(userPos?.latitude, userPos?.longitude);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (hospital.type == HospitalType.bloodBank
                                  ? AppColors.primaryRed
                                  : AppColors.healthcareBlue)
                              .withValues(alpha: 0.12),
                          borderRadius: AppDimensions.borderRadiusMD,
                        ),
                        child: Icon(
                          hospital.type == HospitalType.bloodBank
                              ? Icons.water_drop_rounded
                              : Icons.local_hospital_rounded,
                          color: hospital.type == HospitalType.bloodBank
                              ? AppColors.primaryRed
                              : AppColors.healthcareBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hospital.name, style: AppTypography.titleLarge),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (distanceText != null)
                                  StatusChip(
                                    label: distanceText,
                                    type: StatusType.info,
                                    icon: Icons.near_me_rounded,
                                  ),
                                StatusChip(
                                  label: hospital.type.label,
                                  type: StatusType.info,
                                ),
                                if (hospital.isSampleData)
                                  const StatusChip(
                                    label: 'Sample Data (Unverified)',
                                    type: StatusType.pending,
                                  )
                                else if (hospital.isVerified)
                                  const StatusChip(
                                    label: 'Verified Facility',
                                    type: StatusType.success,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Address section
                  _SectionCard(
                    title: 'Address & Location',
                    icon: Icons.place_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullAddress.isNotEmpty ? fullAddress : 'No address provided.',
                          style: AppTypography.bodyMedium,
                        ),
                        if (fullAddress.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => copyAddress(context, fullAddress),
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copy Address'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                        if (hospital.hasCoordinates) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Coordinates: ${hospital.latitude!.toStringAsFixed(4)}, ${hospital.longitude!.toStringAsFixed(4)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),

                  // Operating hours & details
                  if (hospital.operatingHours != null && hospital.operatingHours!.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Operating Hours',
                      icon: Icons.access_time_rounded,
                      child: Text(hospital.operatingHours!, style: AppTypography.bodyMedium),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                  ],

                  if (hospital.notes != null && hospital.notes!.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Facility Notes',
                      icon: Icons.note_outlined,
                      child: Text(hospital.notes!, style: AppTypography.bodyMedium),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                  ],

                  // Medical Disclaimer Notice
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: AppDimensions.borderRadiusMD,
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'BloodBridge does not verify live blood inventories. Please contact the facility directly to verify current blood availability, donor requirements, and operating hours.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Action Buttons
                  Row(
                    children: [
                      if (hospital.hasPhone)
                        Expanded(
                          child: PrimaryButton(
                            label: 'Call Facility',
                            icon: Icons.call_rounded,
                            backgroundColor: AppColors.success,
                            onPressed: () => launchCall(context, hospital.phone),
                          ),
                        ),
                      if (hospital.hasPhone && (hospital.hasCoordinates || hospital.hasAddress))
                        const SizedBox(width: AppDimensions.spaceMD),
                      if (hospital.hasCoordinates || hospital.hasAddress)
                        Expanded(
                          child: PrimaryButton(
                            label: 'Directions',
                            icon: Icons.directions_rounded,
                            backgroundColor: AppColors.healthcareBlue,
                            onPressed: () => launchDirections(context, hospital),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
