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
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/theme/app_typography.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

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
          'Mark this request as fulfilled? Only do this once the blood requirement has been met.',
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

  Future<void> _respondToRequest(EmergencyRequestModel request) async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to respond.')),
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Offer to Help',
      message:
          'By responding, you are expressing willingness to coordinate — not confirming medical eligibility or transfusion compatibility. A BloodBridge representative may contact you. Continue?',
      confirmLabel: 'Yes, I Want to Help',
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
                  'Thank you! Your willingness to help has been recorded. The requester will be notified.')),
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
      message: 'Withdraw your offer to help with this request?',
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
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
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
    final requestAsync =
        ref.watch(requestDetailProvider(widget.requestId));
    final responsesAsync =
        ref.watch(requestResponsesProvider(widget.requestId));
    final currentUid =
        ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Request Details',
        showBack: true,
      ),
      body: requestAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
          child: Padding(
            padding: AppDimensions.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppDimensions.spaceMD),
                Text(_errorMessage(e),
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
        ),
        data: (request) {
          if (request == null) {
            return const Center(
              child: Text('Request not found or has been removed.'),
            );
          }

          final isRequester = currentUid == request.requesterUid;
          final isOpen = request.status.isActive;

          return SingleChildScrollView(
            padding: AppDimensions.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status + Blood Group Header ──────────────────────────
                Row(
                  children: [
                    BloodTypeBadge(
                      bloodType: request.bloodGroup,
                      size: BloodBadgeSize.large,
                      isSelected: true,
                      showUrgencyRing:
                          request.urgency == UrgencyLevel.critical,
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.hospitalName,
                              style: AppTypography.titleLarge),
                          const SizedBox(height: 4),
                          Text(request.city,
                              style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: request.status.label,
                      type: _statusTypeFor(request.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // ── Request Info Card ─────────────────────────────────────
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Units Required',
                    value: '${request.units} unit${request.units > 1 ? 's' : ''}',
                  ),
                  _InfoRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Urgency',
                    value: request.urgency.label,
                    valueColor: request.urgency == UrgencyLevel.critical
                        ? AppColors.emergencyRed
                        : request.urgency == UrgencyLevel.urgent
                            ? AppColors.warning
                            : AppColors.textPrimary,
                  ),
                  if (request.patientCaseId != null &&
                      request.patientCaseId!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Case ID',
                      value: request.patientCaseId!,
                    ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Posted',
                    value: _formatDate(request.createdAt),
                  ),
                  if (request.updatedAt != null &&
                      request.updatedAt != request.createdAt)
                    _InfoRow(
                      icon: Icons.update_outlined,
                      label: 'Last Updated',
                      value: _formatDate(request.updatedAt),
                    ),
                ]),

                // ── Contact info (only if requester OR responding donor) ──
                if (request.contactPhone != null &&
                    request.contactPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceMD),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Emergency Contact',
                      value: request.contactPhone!,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: request.contactPhone!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Phone number copied.')),
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
                          'BloodBridge does not determine medical eligibility, transfusion compatibility, or guarantee fulfillment. Always consult qualified medical personnel before donation.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Donor Responses ───────────────────────────────────────
                if (isRequester || isOpen) ...[
                  const SizedBox(height: AppDimensions.spaceXL),
                  Text('Donor Responses', style: AppTypography.titleMedium),
                  const SizedBox(height: AppDimensions.spaceSM),
                  responsesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Could not load responses: ${_errorMessage(e)}'),
                    data: (responses) {
                      if (responses.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceLG),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppDimensions.borderRadiusMD,
                          ),
                          child: const Center(
                            child: Text('No donors have responded yet.'),
                          ),
                        );
                      }
                      return Column(
                        children: responses
                            .map((r) => _ResponseTile(response: r))
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
                    label: 'Cancel Request',
                    backgroundColor: AppColors.emergencyRed,
                    isLoading: _isActioning,
                    onPressed: _cancelRequest,
                    icon: Icons.cancel_outlined,
                  ),
                ] else if (!isRequester && isOpen) ...[
                  // Donor respond/withdraw
                  _DonorActionSection(
                    requestId: widget.requestId,
                    request: request,
                    currentUid: currentUid,
                    isActioning: _isActioning,
                    onRespond: () => _respondToRequest(request),
                    onWithdraw: _withdrawResponse,
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
          );
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
            Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const Spacer(),
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
  const _ResponseTile({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
            child: Text(
              response.donorBloodGroup,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response.donorName,
                    style: AppTypography.titleSmall),
                Text(
                  'Offered to coordinate',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const StatusChip(
            label: 'Willing',
            type: StatusType.available,
          ),
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

    final hasActiveResponse =
        _myResponse?.status == DonorResponseStatus.active;

    if (hasActiveResponse) {
      return PrimaryButton(
        label: 'Withdraw My Response',
        backgroundColor: AppColors.warning,
        isLoading: widget.isActioning,
        onPressed: widget.onWithdraw,
        icon: Icons.undo_rounded,
      );
    }

    return PrimaryButton(
      label: 'Offer to Help',
      backgroundColor: AppColors.primaryRed,
      isLoading: widget.isActioning,
      onPressed: widget.onRespond,
      icon: Icons.volunteer_activism_outlined,
    );
  }
}
