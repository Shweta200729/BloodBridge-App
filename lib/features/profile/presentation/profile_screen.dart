import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_preference_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/blood_group_chip.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';

final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final Ref _ref;
  ThemeModeNotifier(this._ref) : super(false);

  void toggleTheme() {
    state = !state;
    _ref.read(storagePreferenceServiceProvider).setDarkMode(state);
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'BD';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  void _openEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserModel? userModel,
    User? currentUser,
  ) {
    if (currentUser == null) return;

    final nameController = TextEditingController(
      text: userModel?.fullName ?? currentUser.displayName ?? '',
    );
    final phoneController = TextEditingController(
      text: userModel?.phone ?? '',
    );
    final cityController = TextEditingController(
      text: userModel?.city ?? '',
    );
    String selectedBloodGroup = userModel?.bloodGroup.isNotEmpty == true
        ? userModel!.bloodGroup
        : 'O+';
    bool isAvailable = userModel?.isDonorAvailable ?? false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppDimensions.spaceLG,
                top: AppDimensions.spaceLG,
                left: AppDimensions.spaceLG,
                right: AppDimensions.spaceLG,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLG),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Edit Profile', style: AppTypography.titleLarge),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      CustomTextField(
                        controller: nameController,
                        label: 'Full Name',
                        hint: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            Validators.validateRequired(v, 'Full Name'),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      CustomTextField(
                        controller: phoneController,
                        label: 'Phone Number',
                        hint: '+1 234 567 8900',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      CustomTextField(
                        controller: cityController,
                        label: 'City / Region (Optional)',
                        hint: 'e.g. New York, NY',
                        prefixIcon: Icons.location_city_rounded,
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(
                        'Blood Group',
                        style: AppTypography.titleMedium.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppStrings.bloodGroups.map((group) {
                          final isSelected = selectedBloodGroup == group;
                          return BloodGroupChip(
                            bloodGroup: group,
                            isSelected: isSelected,
                            onTap: () {
                              setModalState(() {
                                selectedBloodGroup = group;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available for Emergency Donations'),
                        subtitle: const Text(
                          'Allows other verified users to find and contact you during blood shortages.',
                        ),
                        value: isAvailable,
                        activeThumbColor: AppColors.donorGreen,
                        onChanged: (val) {
                          setModalState(() => isAvailable = val);
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      // Notice regarding verification
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceSM),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: AppColors.primaryRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                userModel?.isVerified == true
                                    ? 'Account is medically verified.'
                                    : 'Account is pending medical review. Verification is managed by certified administrators.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),
                      PrimaryButton(
                        label: 'Save Changes',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (isSaving) return;
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            await ref.read(authServiceProvider).updateUserProfile(
                                  uid: currentUser.uid,
                                  fullName: nameController.text,
                                  phone: phoneController.text,
                                  bloodGroup: selectedBloodGroup,
                                  city: cityController.text,
                                  isDonorAvailable: isAvailable,
                                );

                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            final msg = AuthService.getReadableErrorMessage(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setModalState(() => isSaving = false);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeNotifierProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    final userModel = userProfileAsync.value;
    final fullName = (userModel != null && userModel.fullName.isNotEmpty)
        ? userModel.fullName
        : (currentUser?.displayName ?? 'Blood Donor');
    final email = (userModel != null && userModel.email.isNotEmpty)
        ? userModel.email
        : (currentUser?.email ?? 'No email provided');
    final phone = (userModel != null && userModel.phone.isNotEmpty)
        ? userModel.phone
        : 'No phone provided';
    final city = (userModel != null && userModel.city.isNotEmpty)
        ? userModel.city
        : '';
    final bloodGroup = (userModel != null && userModel.bloodGroup.isNotEmpty)
        ? userModel.bloodGroup
        : 'O+';
    final isVerified = userModel?.isVerified ?? false;
    final isDonorAvailable = userModel?.isDonorAvailable ?? false;
    final donationsCount = userModel?.donationsCount ?? 0;
    final livesSaved = userModel?.livesSaved ?? 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Donor Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryRed),
            tooltip: 'Edit Profile',
            onPressed: () => _openEditProfileSheet(
              context,
              ref,
              userModel,
              currentUser,
            ),
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? AppIcons.lightMode : AppIcons.darkMode,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.spaceMD),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarXL / 2,
                    backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                    child: Text(
                      _getInitials(fullName),
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  BloodTypeBadge(
                    bloodType: bloodGroup,
                    size: BloodBadgeSize.small,
                    isSelected: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    fullName,
                    style: AppTypography.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                StatusChip(
                  label: isVerified ? 'Verified Donor' : 'Pending Verification',
                  type: isVerified ? StatusType.verified : StatusType.pending,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              city.isNotEmpty
                  ? '$city • $email • $phone'
                  : '$email • $phone',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceMD),

            // Prominent Donor Availability Switch Card (Task 1)
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceSM,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDonorAvailable
                            ? AppColors.donorGreen
                            : AppColors.textSecondary)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.bloodDrop,
                    color: isDonorAvailable
                        ? AppColors.donorGreen
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Available to Donate Blood',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  isDonorAvailable
                      ? 'You are active and visible in emergency donor searches.'
                      : 'You are currently not listed in emergency donor searches.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                value: isDonorAvailable,
                activeThumbColor: AppColors.donorGreen,
                onChanged: (newVal) async {
                  if (currentUser == null) return;
                  try {
                    await ref
                        .read(authServiceProvider)
                        .updateDonorAvailability(
                          uid: currentUser.uid,
                          isAvailable: newVal,
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(newVal
                            ? 'You are now marked as available to donate.'
                            : 'You are now marked as unavailable.'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AuthService.getReadableErrorMessage(e)),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfileStat('Donations', '$donationsCount Times'),
                  Container(height: 30, width: 1, color: AppColors.borderLight),
                  _buildProfileStat('Lives Saved', '$livesSaved Lives'),
                  Container(height: 30, width: 1, color: AppColors.borderLight),
                  _buildProfileStat(
                    'Eligibility',
                    isDonorAvailable ? 'Available' : 'Unavailable',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppColors.primaryRed),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(AppIcons.forward, size: 16),
                    onTap: () => _openEditProfileSheet(
                      context,
                      ref,
                      userModel,
                      currentUser,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.donor, color: AppColors.primaryRed),
                    title: const Text('Donation History'),
                    trailing: const Icon(AppIcons.forward, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.settings, color: AppColors.healthcareBlue),
                    title: const Text('Account Settings'),
                    trailing: const Icon(AppIcons.forward, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.signOut, color: AppColors.error),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final shouldSignOut = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text(
                              'Are you sure you want to sign out from BloodBridge?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldSignOut == true) {
                        await ref.read(authServiceProvider).signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(color: AppColors.primaryRed),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
      ],
    );
  }
}
