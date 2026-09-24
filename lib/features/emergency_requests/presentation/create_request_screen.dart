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

  @override
  void dispose() {
    _hospitalController.dispose();
    _cityController.dispose();
    _unitsController.dispose();
    _contactController.dispose();
    _caseIdController.dispose();
    super.dispose();
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
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be signed in to create a request.')),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Emergency request published successfully!')),
        );
        // Navigate to the created request's detail screen
        context.pushReplacement(RouteNames.requestDetailRoute(newId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
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
      return 'Permission denied. Please check your account status.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Failed to publish request. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Create SOS Request',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urgent Blood Requirement',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'This request will be visible to all available donors. Provide accurate information only.',
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

              // ── Hospital ────────────────────────────────────────────────
              CustomTextField(
                controller: _hospitalController,
                label: 'Hospital Name & Ward *',
                hint: 'e.g. City General Hospital, Ward 4B',
                prefixIcon: Icons.local_hospital_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Hospital name is required'
                    : null,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── City ────────────────────────────────────────────────────
              CustomTextField(
                controller: _cityController,
                label: 'City *',
                hint: 'e.g. Mumbai',
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

              // ── Contact Phone (optional) ─────────────────────────────────
              CustomTextField(
                controller: _contactController,
                label: 'Emergency Contact (optional)',
                hint: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Case ID (optional) ───────────────────────────────────────
              CustomTextField(
                controller: _caseIdController,
                label: 'Case ID / Reference (optional)',
                hint: 'e.g. BB-9012',
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
                child: Text(
                  'By publishing, you confirm this is a genuine emergency. Do not include sensitive medical details beyond what is necessary for coordination.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),
              PrimaryButton(
                label: 'Publish Emergency Request',
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

