import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
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
        title: const Text(AppStrings.appName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spaceMD),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.bloodDrop,
                      size: AppDimensions.iconXL,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                Text(
                  AppStrings.loginTitle,
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  AppStrings.loginSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXL),
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
                  controller: _passwordController,
                  label: AppStrings.passwordLabel,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                PrimaryButton(
                  label: AppStrings.signInBtn,
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(RouteNames.registerPath),
                    child: Text(
                      AppStrings.dontHaveAccount,
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
