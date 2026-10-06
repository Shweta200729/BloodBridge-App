import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/emergency_request_service.dart';
import '../../../core/services/hospital_service.dart';
import '../../../core/services/messaging_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accepted_assignment_card.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/blood_request_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/hospital_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../hospitals_banks/presentation/widgets/hospital_details_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.valueOrNull;
    final isHospital = user?.isHospital == true;

    // Hospitals only see their own requests; Donors see open requests from all hospitals
    final requestsAsync = isHospital
        ? ref.watch(myRequestsProvider)
        : ref.watch(openRequestsProvider(null));

    // Only listen to notifications if user is logged in
    final uid = user?.uid;
    final notificationsAsync = uid != null
        ? ref.watch(myNotificationsProvider(uid))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    final unreadCount = notificationsAsync.valueOrNull?.length ?? 0;
    final hospitalsAsync = isHospital ? null : ref.watch(hospitalsStreamProvider);
    final userPos = isHospital ? null : ref.watch(userLocationProvider);
    final acceptedRequestsAsync =
        isHospital ? null : ref.watch(myAcceptedRequestsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.appName,
        subtitle: isHospital
            ? (user?.hospitalName ?? 'Hospital Emergency Portal')
            : 'Every Drop Saves Lives',
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(AppIcons.notification,
                    color: AppColors.textPrimary),
                onPressed: () => _showNotificationsPanel(context, ref, uid),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.emergencyRed,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Action Button based on Role
            EmergencyButton(
              label: isHospital
                  ? 'BROADCAST HOSPITAL SOS REQUEST'
                  : 'VIEW EMERGENCY BLOOD REQUESTS',
              onPressed: () {
                if (isHospital) {
                  context.push(RouteNames.createRequestPath);
                } else {
                  context.go(RouteNames.requestsPath);
                }
              },
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // ── Accepted Donor Assignment Banner (Shows when hospital selected this donor) ──
            if (!isHospital && acceptedRequestsAsync != null)
              acceptedRequestsAsync.when(
                data: (acceptedList) {
                  if (acceptedList.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.donorGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Your Accepted Assignment',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.donorGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      ...acceptedList.map((req) => AcceptedAssignmentCard(request: req)),
                      const SizedBox(height: AppDimensions.spaceMD),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

            // Statistics Section
            Text(
              isHospital ? 'Broadcast Overview' : 'Live Impact & Network',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            requestsAsync.when(
              data: (requests) => Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: isHospital ? 'Active Broadcasts' : 'Open Requests',
                      value: '${requests.length}',
                      icon: isHospital
                          ? Icons.campaign_rounded
                          : AppIcons.requests,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: StatCard(
                      title: isHospital ? 'Hospital Status' : 'My Donations',
                      value: isHospital
                          ? 'Verified'
                          : '${user?.donationsCount ?? 0}',
                      icon: isHospital
                          ? Icons.verified_user_rounded
                          : AppIcons.donor,
                      color: AppColors.donorGreen,
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: isHospital ? 'Active Broadcasts' : 'Open Requests',
                      value: '...',
                      icon: isHospital
                          ? Icons.campaign_rounded
                          : AppIcons.requests,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  StatCard(
                    title: isHospital ? 'Hospital Status' : 'My Donations',
                    value: '...',
                    icon: isHospital
                        ? Icons.verified_user_rounded
                        : AppIcons.donor,
                    color: AppColors.donorGreen,
                  ),
                ],
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Requests Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHospital
                      ? 'Your Active SOS Broadcasts'
                      : AppStrings.activeEmergencyRequests,
                  style: AppTypography.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.requestsPath),
                  child: Text(
                    'See All',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.healthcareBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSM),

            // Requests List Preview
            requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceMD),
                    child: Center(
                      child: Text(
                        isHospital
                            ? 'No active SOS broadcasts right now. Tap above to broadcast an emergency request.'
                            : 'No active emergency requests right now.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final preview = requests.take(3).toList();
                return Column(
                  children: preview
                      .map((req) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDimensions.spaceSM),
                            child: BloodRequestCard(
                              hospitalName: req.hospitalName,
                              bloodType: req.bloodGroup,
                              unitsRequired: '${req.units}',
                              urgencyLevel: req.urgency.label,
                              distance: req.city,
                              patientCaseId: req.patientCaseId ??
                                  (req.id.length >= 6
                                      ? req.id.substring(0, 6).toUpperCase()
                                      : req.id.toUpperCase()),
                              actionLabel:
                                  isHospital ? 'Manage Queue' : 'Respond',
                              actionColor: isHospital
                                  ? AppColors.healthcareBlue
                                  : AppColors.primaryRed,
                              onTap: () {
                                ref.read(selectedEmergencyRequestProvider.notifier).state = req;
                                context.push(
                                  RouteNames.requestDetailRoute(req.id),
                                  extra: req,
                                );
                              },
                              onRespondTap: () {
                                ref.read(selectedEmergencyRequestProvider.notifier).state = req;
                                context.push(
                                  RouteNames.requestDetailRoute(req.id),
                                  extra: req,
                                );
                              },
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.spaceLG),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Could not load requests.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            if (!isHospital && hospitalsAsync != null) ...[
              const SizedBox(height: AppDimensions.spaceLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Palghar District Hospitals',
                    style: AppTypography.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.hospitalsPath),
                    child: Text(
                      'View All (20)',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.healthcareBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              hospitalsAsync.when(
                data: (hospitals) {
                  final preview = hospitals.take(3).toList();
                  return Column(
                    children: preview
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDimensions.spaceSM),
                            child: HospitalCard(
                              hospital: h,
                              distanceText: h.formattedDistanceTo(
                                  userPos?.latitude, userPos?.longitude),
                              onTap: () =>
                                  HospitalDetailsSheet.show(context, h),
                              onCallTap: () => HospitalDetailsSheet.launchCall(
                                  context, h.phone),
                              onDirectionsTap: () =>
                                  HospitalDetailsSheet.launchDirections(
                                      context, h),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.spaceMD),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceLG),

            // Network / Hospital verification badge
            AppCard(
              backgroundColor:
                  AppColors.healthcareBlue.withValues(alpha: 0.08),
              border: Border.all(
                  color: AppColors.healthcareBlue.withValues(alpha: 0.3)),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.healthcareBlue,
                      size: AppDimensions.iconLG),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHospital
                              ? 'Verified Medical Partner Portal'
                              : 'Verified Medical Partner Network',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.healthcareBlue),
                        ),
                        Text(
                          isHospital
                              ? 'Emergency SOS broadcasts published from this portal are instantly pushed to nearby matching donors.'
                              : 'All blood banks and hospital requests are cross-verified by medical staff.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsPanel(
      BuildContext context, WidgetRef ref, String? uid) {
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NotificationSheet(uid: uid),
    );
  }
}

// ─── Notification Panel ───────────────────────────────────────────────────────

class _NotificationSheet extends ConsumerWidget {
  final String uid;
  const _NotificationSheet({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(myNotificationsProvider(uid));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceSM),
            child: Row(
              children: [
                Text('Notifications', style: AppTypography.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final notifs =
                        ref.read(myNotificationsProvider(uid)).valueOrNull ?? [];
                    final service = ref.read(messagingServiceProvider);
                    for (final n in notifs) {
                      await service.markNotificationRead(
                          uid, n['id'] as String);
                    }
                  },
                  child: Text('Mark all read',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.healthcareBlue)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifAsync.when(
              data: (notifs) {
                if (notifs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: AppDimensions.spaceSM),
                        Text('No new notifications',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: controller,
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final n = notifs[i];
                    final isRead = n['read'] as bool? ?? false;
                    final reqId = n['requestId'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (n['type'] == 'donor_selected')
                            ? AppColors.donorGreen.withValues(alpha: 0.15)
                            : AppColors.primaryRed.withValues(alpha: 0.12),
                        child: Icon(
                          (n['type'] == 'donor_selected')
                              ? Icons.celebration_rounded
                              : Icons.notification_important_rounded,
                          color: (n['type'] == 'donor_selected')
                              ? AppColors.donorGreen
                              : AppColors.primaryRed,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        n['title'] as String? ?? 'Notification',
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(n['body'] as String? ?? ''),
                      trailing: !isRead
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () async {
                        final notifId = n['id'] as String?;
                        if (notifId != null) {
                          await ref
                              .read(messagingServiceProvider)
                              .markNotificationRead(uid, notifId);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          if (reqId != null && reqId.isNotEmpty) {
                            context.push(RouteNames.requestDetailRoute(reqId));
                          }
                        }
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Could not load notifications')),
            ),
          ),
        ],
      ),
    );
  }
}
