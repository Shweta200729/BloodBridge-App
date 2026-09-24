import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/emergency_request_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/blood_request_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_widget.dart';

class RequestListScreen extends ConsumerStatefulWidget {
  const RequestListScreen({super.key});

  @override
  ConsumerState<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends ConsumerState<RequestListScreen> {
  String? _selectedBloodGroup; // null = all groups

  @override
  Widget build(BuildContext context) {
    final requestsAsync =
        ref.watch(openRequestsProvider(_selectedBloodGroup));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Emergency Requests',
        subtitle: 'Real-time blood requirement feed',
        actions: [
          if (_selectedBloodGroup != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined,
                  color: AppColors.emergencyRed),
              tooltip: 'Clear filter',
              onPressed: () =>
                  setState(() => _selectedBloodGroup = null),
            )
          else
            IconButton(
              icon: const Icon(AppIcons.filter, color: AppColors.textPrimary),
              tooltip: 'Filter by blood group',
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emergencyRed,
        icon: const Icon(AppIcons.add, color: Colors.white),
        label: const Text('New SOS Request',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push(RouteNames.createRequestPath),
      ),
      body: Column(
        children: [
          // ── Active filter indicator ──────────────────────────────────
          if (_selectedBloodGroup != null)
            Container(
              width: double.infinity,
              color: AppColors.emergencyRed.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMD, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 16, color: AppColors.emergencyRed),
                  const SizedBox(width: 6),
                  Text(
                    'Filtering: $_selectedBloodGroup blood group',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.emergencyRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedBloodGroup = null),
                    child: const Text('Clear',
                        style: TextStyle(
                            color: AppColors.emergencyRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // ── Request List ──────────────────────────────────────────────
          Expanded(
            child: requestsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, stack) => Center(
                child: Padding(
                  padding: AppDimensions.screenPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(
                        'Could not load requests.\nPlease check your connection.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        onPressed: () => ref.refresh(
                            openRequestsProvider(_selectedBloodGroup)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.bloodtype_outlined,
                    title: _selectedBloodGroup != null
                        ? 'No open requests for $_selectedBloodGroup'
                        : 'No open requests right now',
                    message: _selectedBloodGroup != null
                        ? 'Try clearing the filter or check back later.'
                        : 'When someone posts an emergency blood request, it will appear here.',
                    buttonLabel:
                        _selectedBloodGroup != null ? 'Clear Filter' : null,
                    onButtonPressed: _selectedBloodGroup != null
                        ? () => setState(() => _selectedBloodGroup = null)
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        openRequestsProvider(_selectedBloodGroup));
                  },
                  child: ListView.separated(
                    padding: AppDimensions.screenPadding.copyWith(
                        bottom: AppDimensions.spaceXXL + 56),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.spaceMD),
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return BloodRequestCard(
                        hospitalName: req.hospitalName,
                        bloodType: req.bloodGroup,
                        unitsRequired: '${req.units}',
                        urgencyLevel: req.urgency.label,
                        distance: req.city,
                        patientCaseId: req.patientCaseId ?? req.id.substring(0, 6).toUpperCase(),
                        onTap: () => context
                            .push(RouteNames.requestDetailRoute(req.id)),
                        onRespondTap: () => context
                            .push(RouteNames.requestDetailRoute(req.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: AppDimensions.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Blood Group',
                style: AppTypography.titleMedium),
            const SizedBox(height: AppDimensions.spaceMD),
            Wrap(
              spacing: AppDimensions.spaceSM,
              runSpacing: AppDimensions.spaceSM,
              children: AppStrings.bloodGroups.map((group) {
                final isSelected = _selectedBloodGroup == group;
                return FilterChip(
                  label: Text(group),
                  selected: isSelected,
                  selectedColor:
                      AppColors.emergencyRed.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.emergencyRed,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.emergencyRed
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.emergencyRed
                        : AppColors.borderLight,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedBloodGroup =
                        isSelected ? null : group);
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
          ],
        ),
      ),
    );
  }
}

