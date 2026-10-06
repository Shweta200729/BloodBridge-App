import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/emergency_request_model.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/emergency_request_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _cityController = TextEditingController();
  final _unitsController = TextEditingController();
  final _contactController = TextEditingController();
  final _caseIdController = TextEditingController();
  String? _selectedBloodGroup;
  UrgencyLevel _selectedUrgency = UrgencyLevel.urgent;
  bool _isSubmitting = false;
  bool _didPrefill = false;

  @override
  void dispose() {
    _hospitalController.dispose();
    _cityController.dispose();
    _unitsController.dispose();
    _contactController.dispose();
    _caseIdController.dispose();
    super.dispose();
  }

  void _prefillFromHospital(dynamic user) {
    if (_didPrefill || user == null) return;
    if (user.isHospital) {
      _hospitalController.text = user.hospitalName ?? user.fullName;
      if (user.city.isNotEmpty) _cityController.text = user.city;
      if (user.phone.isNotEmpty) _contactController.text = user.phone;
      _didPrefill = true;
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the required blood group')),
      );
      return;
    }

    // Confirm user is authenticated before attempting write
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be signed in to create a request.')),
      );
      return;
    }

    if (!currentUser.isHospital) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only registered hospitals can initiate SOS blood requests.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final unitsText = _unitsController.text.trim();
    final units = int.tryParse(unitsText);
    if (units == null || units < 1 || units > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units must be a number between 1 and 20.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(emergencyRequestServiceProvider);
      final newId = await service.createRequest(
        bloodGroup: _selectedBloodGroup!,
        units: units,
        hospitalName: _hospitalController.text.trim(),
        city: _cityController.text.trim(),
        urgency: _selectedUrgency,
        contactPhone: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        patientCaseId: _caseIdController.text.trim().isEmpty
            ? null
            : _caseIdController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency SOS broadcast published! Matching donors notified.'),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate to the created request's detail screen
      context.pushReplacement(RouteNames.requestDetailRoute(newId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _errorMessage(dynamic e) {
    if (e is ArgumentError) return e.message.toString();
    final msg = e?.toString() ?? '';
    if (msg.contains('permission-denied')) {
      return 'Permission denied. Please verify your hospital credentials.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Failed to publish request. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final user = userProfileAsync.value;

    if (user != null && !_didPrefill) {
      _prefillFromHospital(user);
    }

    // Guard: Only hospitals should create SOS blood requests
    if (user != null && !user.isHospital) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'SOS Requests',
          showBack: true,
        ),
        body: Padding(
          padding: AppDimensions.screenPadding,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  decoration: BoxDecoration(
                    color: AppColors.healthcareBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 64,
                    color: AppColors.healthcareBlue,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                Text(
                  'Hospital Authorization Required',
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                Text(
                  'To prevent unverified alerts and ensure clinical oversight, emergency blood requests are initiated exclusively by registered hospitals and medical centers.\n\nIf you need blood urgently, please have your treating hospital post an SOS, or find nearby accredited blood banks directly.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                PrimaryButton(
                  label: 'Find Nearby Hospitals & Blood Banks',
                  icon: Icons.search_rounded,
                  backgroundColor: AppColors.healthcareBlue,
                  onPressed: () => context.go(RouteNames.hospitalsPath),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  ),
                  onPressed: () => context.pop(),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Broadcast SOS Request',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Header Banner
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.healthcareBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: AppColors.healthcareBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.healthcareBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.hospitalName ?? user?.fullName ?? 'Hospital Portal',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.healthcareBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Official SOS Broadcast to registered blood donors in ${user?.city.isNotEmpty == true ? user!.city : "your region"}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              Text(
                'Emergency Blood Requirement',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'This emergency broadcast alerts available donors with matching blood type immediately. Enter accurate patient coordination details.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // ── Blood Group ─────────────────────────────────────────────
              Text('Required Blood Group *', style: AppTypography.labelLarge),
              const SizedBox(height: AppDimensions.spaceSM),
              Wrap(
                spacing: AppDimensions.spaceMD,
                runSpacing: AppDimensions.spaceMD,
                children: AppStrings.bloodGroups.map((group) {
                  return BloodTypeBadge(
                    bloodType: group,
                    isSelected: _selectedBloodGroup == group,
                    showUrgencyRing: _selectedBloodGroup == group,
                    onTap: () =>
                        setState(() => _selectedBloodGroup = group),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // ── Urgency ─────────────────────────────────────────────────
              Text('Urgency Level *', style: AppTypography.labelLarge),
              const SizedBox(height: AppDimensions.spaceSM),
              Wrap(
                spacing: AppDimensions.spaceSM,
                children: UrgencyLevel.values.map((level) {
                  final isSelected = _selectedUrgency == level;
                  final color = level == UrgencyLevel.critical
                      ? AppColors.emergencyRed
                      : level == UrgencyLevel.urgent
                          ? AppColors.warning
                          : level == UrgencyLevel.high
                              ? AppColors.healthcareBlue
                              : AppColors.textSecondary;
                  return ChoiceChip(
                    label: Text(level.label),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? color
                          : AppColors.borderLight,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedUrgency = level),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // ── Hospital Name ───────────────────────────────────────────
              CustomTextField(
                controller: _hospitalController,
                label: 'Hospital Name & Department / Ward *',
                hint: 'e.g. City General Hospital, ICU Ward 2',
                prefixIcon: Icons.local_hospital_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Hospital name is required'
                    : null,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── City ────────────────────────────────────────────────────
              CustomTextField(
                controller: _cityController,
                label: 'City / Region *',
                hint: 'e.g. Mumbai, New York',
                prefixIcon: Icons.location_city_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'City is required'
                    : null,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Units ───────────────────────────────────────────────────
              CustomTextField(
                controller: _unitsController,
                label: 'Blood Units Required *',
                hint: 'e.g. 2 (max 20)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.water_drop_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Units required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1 || n > 20) {
                    return 'Enter a number between 1 and 20';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Contact Phone (Helpline) ─────────────────────────────────
              CustomTextField(
                controller: _contactController,
                label: 'Emergency Desk Phone / Helpline *',
                hint: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Helpline phone is required'
                    : null,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Patient Case Reference ID (optional) ─────────────────────
              CustomTextField(
                controller: _caseIdController,
                label: 'Patient Case / MRN Reference ID (optional)',
                hint: 'e.g. ICU-CASE-849',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Disclaimer ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: AppDimensions.borderRadiusMD,
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By broadcasting, you certify this blood request on behalf of the hospital. Registered donors in the queue will be able to volunteer, and you can select the donor to coordinate blood collection.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),
              PrimaryButton(
                label: 'Broadcast Emergency SOS',
                backgroundColor: AppColors.emergencyRed,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
                icon: Icons.emergency_share_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
