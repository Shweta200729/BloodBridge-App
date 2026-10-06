import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/blood_group_chip.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Role: 'donor' vs 'hospital'
  String _selectedRole = 'donor';

  // Common controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();

  // Donor-specific
  final _nameController = TextEditingController();
  String? _selectedBloodGroup;

  // Hospital-specific
  final _hospitalNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _hospitalNameController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedRole == 'donor' && _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your blood type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      if (_selectedRole == 'hospital') {
        await authService.registerHospitalWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          hospitalName: _hospitalNameController.text,
          phone: _phoneController.text,
          city: _cityController.text,
          address: _addressController.text,
          licenseNumber: _licenseController.text.trim().isNotEmpty
              ? _licenseController.text.trim()
              : null,
        );
      } else {
        await authService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          phone: _phoneController.text,
          bloodGroup: _selectedBloodGroup!,
          city: _cityController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == 'hospital'
                ? 'Hospital account registered successfully!'
                : 'Donor account created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      context.go(RouteNames.homePath);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = AuthService.getReadableErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHospital = _selectedRole == 'hospital';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.registerTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.registerTitle,
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Join BloodBridge to connect donors with emergency hospital requests',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // ── Account Type Selector (Donor vs Hospital) ───────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AccountTypeTab(
                          label: 'Blood Donor',
                          icon: Icons.person_outline_rounded,
                          isSelected: !isHospital,
                          onTap: () => setState(() => _selectedRole = 'donor'),
                        ),
                      ),
                      Expanded(
                        child: _AccountTypeTab(
                          label: 'Hospital / Center',
                          icon: Icons.local_hospital_outlined,
                          isSelected: isHospital,
                          onTap: () => setState(() => _selectedRole = 'hospital'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Role Context Banner
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: isHospital
                        ? AppColors.healthcareBlue.withValues(alpha: 0.08)
                        : AppColors.primaryRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(
                      color: isHospital
                          ? AppColors.healthcareBlue.withValues(alpha: 0.25)
                          : AppColors.primaryRed.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isHospital
                            ? Icons.verified_user_rounded
                            : Icons.volunteer_activism_rounded,
                        color: isHospital
                            ? AppColors.healthcareBlue
                            : AppColors.primaryRed,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isHospital
                              ? 'Hospitals can initiate verified SOS blood requests and manage volunteer donor queues.'
                              : 'Donors receive live SOS blood alerts, apply to donate, and help save lives.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isHospital
                                ? AppColors.healthcareBlue
                                : AppColors.primaryRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // ── Conditional Form Fields ─────────────────────────────────
                if (!isHospital) ...[
                  // Individual Donor Fields
                  CustomTextField(
                    controller: _nameController,
                    label: AppStrings.fullNameLabel,
                    hint: 'e.g. John Doe',
                    prefixIcon: Icons.person_rounded,
                    validator: (v) =>
                        Validators.validateRequired(v, 'Full Name'),
                  ),
                ] else ...[
                  // Hospital / Medical Center Fields
                  CustomTextField(
                    controller: _hospitalNameController,
                    label: 'Hospital / Facility Name',
                    hint: 'e.g. City Care Multi-Speciality Hospital',
                    prefixIcon: Icons.local_hospital_rounded,
                    validator: (v) =>
                        Validators.validateRequired(v, 'Hospital Name'),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Hospital Address / Location',
                    hint: 'e.g. 102 Healthcare Avenue, Central Road',
                    prefixIcon: Icons.map_rounded,
                    validator: (v) =>
                        Validators.validateRequired(v, 'Hospital Address'),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  CustomTextField(
                    controller: _licenseController,
                    label: 'Medical Registration / License ID (Optional)',
                    hint: 'e.g. REG-HOSP-2024-9901',
                    prefixIcon: Icons.badge_rounded,
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceMD),

                // Common Email Field
                CustomTextField(
                  controller: _emailController,
                  label: isHospital ? 'Official Hospital Email' : AppStrings.emailLabel,
                  hint: isHospital ? 'emergency@hospital.org' : 'name@example.com',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Common Phone Field
                CustomTextField(
                  controller: _phoneController,
                  label: isHospital
                      ? 'Emergency Helpline / Desk Phone'
                      : AppStrings.phoneLabel,
                  hint: '+1 234 567 8900',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Common City Field
                CustomTextField(
                  controller: _cityController,
                  label: 'City / Region',
                  hint: 'e.g. Mumbai, New York, Chicago',
                  prefixIcon: Icons.location_city_rounded,
                  validator: (v) => Validators.validateRequired(v, 'City'),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.passwordLabel,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),

                // Blood Group selection (Only for individual donors)
                if (!isHospital) ...[
                  const SizedBox(height: AppDimensions.spaceLG),
                  Text(
                    AppStrings.selectBloodType,
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Wrap(
                    spacing: AppDimensions.spaceMD,
                    runSpacing: AppDimensions.spaceMD,
                    children: AppStrings.bloodGroups.map((group) {
                      final isSelected = _selectedBloodGroup == group;
                      return BloodGroupChip(
                        bloodGroup: group,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedBloodGroup = group;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceXL),
                PrimaryButton(
                  label: isHospital
                      ? 'Register Hospital Account'
                      : AppStrings.signUpBtn,
                  isLoading: _isLoading,
                  backgroundColor:
                      isHospital ? AppColors.healthcareBlue : AppColors.primaryRed,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      AppStrings.alreadyHaveAccount,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
