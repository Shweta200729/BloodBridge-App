import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _unitsController = TextEditingController();
  final _contactController = TextEditingController();
  String? _selectedBloodGroup;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalController.dispose();
    _unitsController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedBloodGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select required blood group')),
        );
        return;
      }
      setState(() => _isSubmitting = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency request published successfully!')),
          );
          context.pop();
        }
      });
    }
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
                'Broadcast emergency requirements directly to nearest verified donors and hospitals.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              Text('Required Blood Group', style: AppTypography.labelLarge),
              const SizedBox(height: AppDimensions.spaceSM),
              Wrap(
                spacing: AppDimensions.spaceMD,
                runSpacing: AppDimensions.spaceMD,
                children: AppStrings.bloodGroups.map((group) {
                  return BloodTypeBadge(
                    bloodType: group,
                    isSelected: _selectedBloodGroup == group,
                    showUrgencyRing: _selectedBloodGroup == group,
                    onTap: () => setState(() => _selectedBloodGroup = group),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              CustomTextField(
                controller: _patientNameController,
                label: 'Patient Name / Case ID',
                hint: 'e.g. John Doe',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              CustomTextField(
                controller: _hospitalController,
                label: 'Hospital Name & Ward',
                hint: 'e.g. City General Hospital, Ward 4B',
                prefixIcon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              CustomTextField(
                controller: _unitsController,
                label: 'Blood Units Required',
                hint: 'e.g. 2',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              CustomTextField(
                controller: _contactController,
                label: 'Emergency Phone Number',
                hint: '+1 234 567 8900',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              PrimaryButton(
                label: 'Publish Emergency Request',
                backgroundColor: AppColors.emergencyRed,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
