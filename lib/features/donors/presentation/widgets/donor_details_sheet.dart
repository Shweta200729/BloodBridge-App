import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/blood_type_badge.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';

class DonorDetailsSheet extends StatelessWidget {
  final UserModel donor;

  const DonorDetailsSheet({
    super.key,
    required this.donor,
  });

  static void show(BuildContext context, UserModel donor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DonorDetailsSheet(donor: donor),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          await _copyToClipboard(context, phone, isFallback: true);
        }
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, phone, isFallback: true);
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text, {bool isFallback = false}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFallback
                ? 'Unable to open dialer directly. Phone copied to clipboard: $text'
                : 'Phone number copied to clipboard: $text',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidPhone = donor.phone.trim().isNotEmpty;
    final cityText = donor.city.trim().isNotEmpty
        ? donor.city.trim()
        : 'Location not specified';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Donor Details', style: AppTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Donor summary row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BloodTypeBadge(
                    bloodType: donor.bloodGroup.isNotEmpty ? donor.bloodGroup : 'O+',
                    size: BloodBadgeSize.large,
                    isSelected: true,
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donor.fullName.isNotEmpty ? donor.fullName : 'Volunteer Donor',
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusChip(
                              label: donor.isVerified ? 'Verified Donor' : 'Pending Verification',
                              type: donor.isVerified ? StatusType.verified : StatusType.pending,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.donorGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Available',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.donorGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // General location information (privacy-safe, no exact GPS coordinates)
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primaryRed, size: 22),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Area / Region (Self-reported)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            cityText,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Medical Safety Notice
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.primaryRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important Medical Notice',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Blood group matching shown here is a preliminary search aid only. Cross-matching, clinical compatibility, and donor medical eligibility must be evaluated and confirmed by licensed healthcare professionals and certified blood bank personnel before any donation or transfusion.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Primary Action Buttons: Call & Copy Phone
              if (hasValidPhone) ...[
                PrimaryButton(
                  label: 'Call ${donor.fullName.isNotEmpty ? donor.fullName.split(' ').first : 'Donor'}',
                  icon: Icons.phone_rounded,
                  onPressed: () => _makePhoneCall(context, donor.phone),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      'Copy ${donor.phone}',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () => _copyToClipboard(context, donor.phone),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_disabled_rounded, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No contact phone number provided by this donor',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
