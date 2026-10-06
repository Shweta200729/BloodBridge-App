import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/models/donor_response_model.dart';
import '../../../core/models/emergency_request_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/emergency_request_service.dart';
import '../../../core/widgets/blood_type_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/theme/app_typography.dart';
import '../../hospitals_banks/presentation/widgets/hospital_details_sheet.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  final EmergencyRequestModel? initialRequest;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _isActioning = false;

  StatusType _statusTypeFor(RequestStatus status) {
    switch (status) {
      case RequestStatus.open:
        return StatusType.available;
      case RequestStatus.fulfilled:
        return StatusType.success;
      case RequestStatus.cancelled:
      case RequestStatus.closed:
        return StatusType.pending;
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Request',
      message:
          'Are you sure you want to cancel this emergency request? This action cannot be undone.',
      confirmLabel: 'Cancel Request',
      confirmColor: AppColors.emergencyRed,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      await service.cancelRequest(widget.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _markFulfilled() async {
    final confirmed = await _showConfirmDialog(
      title: 'Mark as Fulfilled',
      message:
          'Mark this request as fulfilled? Only do this once the blood donation has been collected.',
      confirmLabel: 'Mark Fulfilled',
      confirmColor: AppColors.donorGreen,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      await service.markFulfilled(widget.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Request marked as fulfilled. Thank you for saving a life!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _selectDonor(DonorResponseModel response) async {
    final confirmed = await _showConfirmDialog(
      title: 'Select Donor',
      message:
          'Select ${response.donorName} (${response.donorBloodGroup}) as the primary donor for this emergency? They will receive an immediate in-app notification with hospital coordination details.',
      confirmLabel: 'Confirm Selection',
      confirmColor: AppColors.healthcareBlue,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      await service.selectDonor(
        requestId: widget.requestId,
        donorUid: response.donorUid,
        donorName: response.donorName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response.donorName} selected! Notification sent to donor.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _respondToRequest(EmergencyRequestModel request) async {
    final currentUser = ref.read(currentUserProfileProvider).valueOrNull;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to volunteer.')),
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Volunteer to Donate',
      message:
          'By volunteering, you are joining the hospital\'s donor queue. If selected by ${request.hospitalName}, you will receive a notification to coordinate donation. Continue?',
      confirmLabel: 'Join Donor Queue',
      confirmColor: AppColors.primaryRed,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      await service.respondToRequest(
        requestId: widget.requestId,
        donorName: currentUser.fullName,
        donorBloodGroup: currentUser.bloodGroup,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'You joined the donor queue! The hospital will review and notify selected donors.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _withdrawResponse() async {
    final confirmed = await _showConfirmDialog(
      title: 'Withdraw Response',
      message: 'Withdraw your volunteer application for this request?',
      confirmLabel: 'Withdraw',
      confirmColor: AppColors.warning,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      await service.withdrawResponse(requestId: widget.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your response has been withdrawn.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              minimumSize: const Size(0, 36),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _errorMessage(dynamic e) {
    if (e is StateError) return e.message;
    if (e is ArgumentError) return e.message.toString();
    return e?.toString() ?? 'An unexpected error occurred.';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('d MMM yyyy, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final selectedReq = ref.watch(selectedEmergencyRequestProvider);
    final requestAsync =
        ref.watch(requestDetailProvider(widget.requestId));
    final responsesAsync =
        ref.watch(requestResponsesProvider(widget.requestId));
    final currentUid =
        ref.watch(authStateChangesProvider).valueOrNull?.uid;
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isHospital = userProfile?.isHospital ?? false;

    // Multi-tier fallback guarantees request data is immediately available
    final EmergencyRequestModel? request = (selectedReq != null && (widget.requestId.isEmpty || selectedReq.id == widget.requestId) ? selectedReq : null)
        ?? widget.initialRequest
        ?? requestAsync.valueOrNull;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Request Details',
        showBack: true,
      ),
      body: Builder(
        builder: (context) {
          try {
            final currentRequest = request;
          if (currentRequest == null) {
            if (requestAsync.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryRed),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(
                      'Loading request details...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (requestAsync.hasError) {
              return Center(
                child: Padding(
                  padding: AppDimensions.screenPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(_errorMessage(requestAsync.error),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: AppDimensions.spaceMD),
                      ElevatedButton(
                        onPressed: () => ref
                            .refresh(requestDetailProvider(widget.requestId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: AppDimensions.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(
                      'Request not found or has been closed.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final isRequester = currentUid != null && (
            currentUid == currentRequest.requesterUid ||
            (isHospital &&
                userProfile?.hospitalName != null &&
                userProfile!.hospitalName!.trim().toLowerCase() ==
                    currentRequest.hospitalName.trim().toLowerCase())
          );
          final isOpen = currentRequest.status.isActive;
          final isSelectedDonor =
              currentUid != null && currentRequest.selectedDonorUid == currentUid;

          return SingleChildScrollView(
            padding: AppDimensions.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Selected Donor Celebratory Banner (for chosen donor) ────
                if (isSelectedDonor) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.donorGreen.withValues(alpha: 0.1),
                      borderRadius: AppDimensions.borderRadiusMD,
                      border: Border.all(color: AppColors.donorGreen, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.celebration_rounded,
                                color: AppColors.donorGreen, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You are the Selected Donor!',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.donorGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${currentRequest.hospitalName} has selected you for this ${currentRequest.bloodGroup} blood requirement. Please coordinate directly with the hospital desk.',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (currentRequest.contactPhone != null &&
                                currentRequest.contactPhone!.isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.donorGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 38),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusSM),
                                  ),
                                ),
                                icon: const Icon(Icons.phone_rounded, size: 16),
                                label: Text(
                                    'Call Hospital (${currentRequest.contactPhone})'),
                                onPressed: () => HospitalDetailsSheet.launchCall(
                                    context, currentRequest.contactPhone),
                              ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.healthcareBlue,
                                side: const BorderSide(
                                    color: AppColors.healthcareBlue),
                                minimumSize: const Size(0, 38),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSM),
                                ),
                              ),
                              icon: const Icon(Icons.directions_rounded, size: 16),
                              label: const Text('Directions to Hospital'),
                              onPressed: () =>
                                  HospitalDetailsSheet.launchDirections(
                                context,
                                HospitalModel(
                                  id: '',
                                  name: currentRequest.hospitalName,
                                  address: currentRequest.city,
                                  city: currentRequest.city,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (currentRequest.selectedDonorUid != null && !isRequester) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppDimensions.borderRadiusMD,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.donorGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A donor has been selected by ${currentRequest.hospitalName} for this emergency.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Status + Blood Group Header ──────────────────────────
                Row(
                  children: [
                    BloodTypeBadge(
                      bloodType: currentRequest.bloodGroup,
                      size: BloodBadgeSize.large,
                      isSelected: true,
                      showUrgencyRing:
                          currentRequest.urgency == UrgencyLevel.critical,
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded,
                                  size: 16, color: AppColors.healthcareBlue),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  currentRequest.hospitalName,
                                  style: AppTypography.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currentRequest.city,
                              style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: currentRequest.status.label,
                      type: _statusTypeFor(currentRequest.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // ── Request Info Card ─────────────────────────────────────
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Units Required',
                    value: '${currentRequest.units} unit${currentRequest.units > 1 ? 's' : ''}',
                  ),
                  _InfoRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Urgency',
                    value: currentRequest.urgency.label,
                    valueColor: currentRequest.urgency == UrgencyLevel.critical
                        ? AppColors.emergencyRed
                        : currentRequest.urgency == UrgencyLevel.urgent
                            ? AppColors.warning
                            : AppColors.textPrimary,
                  ),
                  if (currentRequest.patientCaseId != null &&
                      currentRequest.patientCaseId!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Case ID / Reference',
                      value: currentRequest.patientCaseId!,
                    ),
                  if (currentRequest.selectedDonorName != null &&
                      currentRequest.selectedDonorName!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.person_pin_rounded,
                      label: 'Selected Donor',
                      value: currentRequest.selectedDonorName!,
                      valueColor: AppColors.donorGreen,
                    ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Broadcast Posted',
                    value: _formatDate(currentRequest.createdAt),
                  ),
                  if (currentRequest.updatedAt != null &&
                      currentRequest.updatedAt != currentRequest.createdAt)
                    _InfoRow(
                      icon: Icons.update_outlined,
                      label: 'Last Updated',
                      value: _formatDate(currentRequest.updatedAt),
                    ),
                ]),

                // ── Contact info (Emergency Desk Helpline) ───────────────
                if (currentRequest.contactPhone != null &&
                    currentRequest.contactPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceMD),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Hospital Emergency Helpline',
                      value: currentRequest.contactPhone!,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: currentRequest.contactPhone!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Helpline phone copied.')),
                        );
                      },
                      trailingIcon: Icons.copy_outlined,
                    ),
                  ]),
                ],

                // ── Medical disclaimer ────────────────────────────────────
                const SizedBox(height: AppDimensions.spaceMD),
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
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Emergency requests are clinical broadcasts initiated by hospitals. Volunteer donors must meet hospital clinical donor criteria prior to transfusion.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Donor Queue & Responses Section ───────────────────────
                if (isRequester || isOpen) ...[
                  const SizedBox(height: AppDimensions.spaceXL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRequester
                            ? 'Volunteer Donor Queue'
                            : 'Registered Volunteers',
                        style: AppTypography.titleMedium,
                      ),
                      if (isRequester)
                        Text(
                          'Select 1 donor for coordination',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  responsesAsync.when(
                    loading: () => Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceLG),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppDimensions.borderRadiusMD,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (e, _) => Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppDimensions.borderRadiusMD,
                      ),
                      child: Center(
                        child: Text(
                          'No queue entries currently available.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    data: (responses) {
                      if (responses.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceLG),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppDimensions.borderRadiusMD,
                          ),
                          child: const Center(
                            child: Text(
                                'No donors in queue yet. Available donors are being notified.'),
                          ),
                        );
                      }
                      return Column(
                        children: responses
                            .map(
                              (r) => _ResponseTile(
                                response: r,
                                isRequester: isRequester,
                                isOpen: isOpen,
                                isSelectedDonor:
                                    r.donorUid == currentRequest.selectedDonorUid ||
                                        r.status == DonorResponseStatus.selected,
                                onSelectDonor: () => _selectDonor(r),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceXL),

                // ── Action Buttons ────────────────────────────────────────
                if (isRequester && isOpen) ...[
                  PrimaryButton(
                    label: 'Mark as Fulfilled',
                    backgroundColor: AppColors.donorGreen,
                    isLoading: _isActioning,
                    onPressed: _markFulfilled,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  PrimaryButton(
                    label: 'Cancel SOS Request',
                    backgroundColor: AppColors.emergencyRed,
                    isLoading: _isActioning,
                    onPressed: _cancelRequest,
                    icon: Icons.cancel_outlined,
                  ),
                ] else if (!isRequester && isOpen) ...[
                  // Donor respond/withdraw
                  _DonorActionSection(
                    requestId: widget.requestId,
                    request: currentRequest,
                    currentUid: currentUid,
                    isActioning: _isActioning,
                    onRespond: () => _respondToRequest(currentRequest),
                    onWithdraw: _withdrawResponse,
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
          );
        } catch (e, stack) {
          debugPrint('Error building RequestDetailScreen: $e\n$stack');
          return Center(
            child: Padding(
              padding: AppDimensions.screenPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Text(
                    'Could not display request details: $e',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    ),
  );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(height: 1, color: AppColors.borderLight);
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.borderRadiusMD,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 16, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final DonorResponseModel response;
  final bool isRequester;
  final bool isOpen;
  final bool isSelectedDonor;
  final VoidCallback onSelectDonor;

  const _ResponseTile({
    required this.response,
    required this.isRequester,
    required this.isOpen,
    required this.isSelectedDonor,
    required this.onSelectDonor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: isSelectedDonor
            ? AppColors.donorGreen.withValues(alpha: 0.05)
            : AppColors.surfaceWhite,
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(
          color: isSelectedDonor ? AppColors.donorGreen : AppColors.borderLight,
          width: isSelectedDonor ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isSelectedDonor
                ? AppColors.donorGreen.withValues(alpha: 0.15)
                : AppColors.primaryRed.withValues(alpha: 0.12),
            child: Text(
              response.donorBloodGroup,
              style: AppTypography.labelMedium.copyWith(
                color: isSelectedDonor ? AppColors.donorGreen : AppColors.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response.donorName, style: AppTypography.titleSmall),
                Text(
                  isSelectedDonor
                      ? 'Selected by Hospital Desk'
                      : 'In Volunteer Queue',
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelectedDonor
                        ? AppColors.donorGreen
                        : AppColors.textSecondary,
                    fontWeight: isSelectedDonor
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isSelectedDonor) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.donorGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.donorGreen),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: AppColors.donorGreen),
                  SizedBox(width: 4),
                  Text(
                    'Selected',
                    style: TextStyle(
                      color: AppColors.donorGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isRequester && isOpen) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.healthcareBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
              onPressed: onSelectDonor,
              child: const Text(
                'Select Donor',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            const StatusChip(
              label: 'In Queue',
              type: StatusType.available,
            ),
          ],
        ],
      ),
    );
  }
}

/// Async section that checks if the current donor has already responded.
class _DonorActionSection extends ConsumerStatefulWidget {
  final String requestId;
  final EmergencyRequestModel request;
  final String? currentUid;
  final bool isActioning;
  final VoidCallback onRespond;
  final VoidCallback onWithdraw;

  const _DonorActionSection({
    required this.requestId,
    required this.request,
    required this.currentUid,
    required this.isActioning,
    required this.onRespond,
    required this.onWithdraw,
  });

  @override
  ConsumerState<_DonorActionSection> createState() =>
      _DonorActionSectionState();
}

class _DonorActionSectionState extends ConsumerState<_DonorActionSection> {
  DonorResponseModel? _myResponse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyResponse();
  }

  Future<void> _loadMyResponse() async {
    if (widget.currentUid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      final response = await service.getMyResponse(widget.requestId);
      if (mounted) setState(() => _myResponse = response);
    } catch (_) {
      // ignore — show default respond button
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(_DonorActionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActioning && oldWidget.isActioning) {
      _loadMyResponse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2));
    }

    final hasActiveOrSelectedResponse =
        _myResponse?.status.isActiveOrSelected == true;

    if (hasActiveOrSelectedResponse) {
      final isSelected =
          _myResponse?.status == DonorResponseStatus.selected;

      if (isSelected) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          decoration: BoxDecoration(
            color: AppColors.donorGreen.withValues(alpha: 0.1),
            borderRadius: AppDimensions.borderRadiusMD,
            border: Border.all(color: AppColors.donorGreen),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.donorGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'You are selected for this donation',
                    style: TextStyle(
                      color: AppColors.donorGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Please coordinate with the hospital medical staff.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return PrimaryButton(
        label: 'Withdraw My Application',
        backgroundColor: AppColors.warning,
        isLoading: widget.isActioning,
        onPressed: widget.onWithdraw,
        icon: Icons.undo_rounded,
      );
    }

    return PrimaryButton(
      label: 'Volunteer to Donate (Join Queue)',
      backgroundColor: AppColors.primaryRed,
      isLoading: widget.isActioning,
      onPressed: widget.onRespond,
      icon: Icons.volunteer_activism_outlined,
    );
  }
}
