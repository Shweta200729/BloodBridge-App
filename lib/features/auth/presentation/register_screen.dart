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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedBloodGroup;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedBloodGroup == null) {
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
      await authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        phone: _phoneController.text,
        bloodGroup: _selectedBloodGroup!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
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
                  AppStrings.registerSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                CustomTextField(
                  controller: _nameController,
                  label: AppStrings.fullNameLabel,
                  hint: 'John Doe',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) => Validators.validateRequired(v, 'Full Name'),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.emailLabel,
                  hint: 'name@example.com',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneLabel,
                  hint: '+1 234 567 8900',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.passwordLabel,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),
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
                const SizedBox(height: AppDimensions.spaceXL),
                PrimaryButton(
                  label: AppStrings.signUpBtn,
                  isLoading: _isLoading,
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
