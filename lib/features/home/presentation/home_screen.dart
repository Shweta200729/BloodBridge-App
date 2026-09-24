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
import '../../../core/services/messaging_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/blood_request_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final openRequestsAsync = ref.watch(openRequestsProvider(null));

    // Only listen to notifications if user is logged in
    final uid = userAsync.value?.uid;
    final notificationsAsync = uid != null
        ? ref.watch(myNotificationsProvider(uid))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    final unreadCount = notificationsAsync.value?.length ?? 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.appName,
        subtitle: 'Every Drop Saves Lives',
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
            // High Visibility Emergency SOS Button
            EmergencyButton(
              onPressed: () => context.push(RouteNames.createRequestPath),
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Live Statistics
            Text('Live Impact & Network', style: AppTypography.titleMedium),
            const SizedBox(height: AppDimensions.spaceSM),
            openRequestsAsync.when(
              data: (requests) => Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Open Requests',
                      value: '${requests.length}',
                      icon: AppIcons.requests,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: userAsync.when(
                      data: (user) => StatCard(
                        title: 'My Donations',
                        value: '${user?.donationsCount ?? 0}',
                        icon: AppIcons.donor,
                        color: AppColors.donorGreen,
                      ),
                      loading: () => const StatCard(
                        title: 'My Donations',
                        value: '—',
                        icon: AppIcons.donor,
                        color: AppColors.donorGreen,
                      ),
                      error: (_, __) => const StatCard(
                        title: 'My Donations',
                        value: '—',
                        icon: AppIcons.donor,
                        color: AppColors.donorGreen,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Open Requests',
                      value: '...',
                      icon: AppIcons.requests,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: StatCard(
                      title: 'My Donations',
                      value: '...',
                      icon: AppIcons.donor,
                      color: AppColors.donorGreen,
                    ),
                  ),
                ],
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Active Emergency Requests Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.activeEmergencyRequests,
                    style: AppTypography.titleMedium),
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

            // Real requests from Firestore (show top 3)
            openRequestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
                    child: Center(
                      child: Text(
                        'No active emergency requests right now.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
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
                              urgencyLevel: req.urgency.name.toUpperCase(),
                              distance: req.city,
                              patientCaseId: req.patientCaseId ?? req.id.substring(0, 6).toUpperCase(),
                              onRespondTap: () => context
                                  .push(RouteNames.requestDetailRoute(req.id)),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(AppDimensions.spaceLG),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => Text(
                'Could not load requests.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Healthcare disclaimer card
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
                          'Verified Medical Partner Network',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.healthcareBlue),
                        ),
                        Text(
                          'All blood banks and hospital requests are cross-verified by medical staff.',
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
    final router = GoRouter.of(context);

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
                horizontal: AppDimensions.spaceMD, vertical: AppDimensions.spaceSM),
            child: Row(
              children: [
                Text('Notifications', style: AppTypography.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final notifs = ref.read(myNotificationsProvider(uid)).value ?? [];
                    final service = ref.read(messagingServiceProvider);
                    for (final n in notifs) {
                      await service.markNotificationRead(uid, n['id'] as String);
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
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    final title = n['title'] as String? ?? 'Notification';
                    final body = n['body'] as String? ?? '';
                    final requestId = n['requestId'] as String?;
                    final type = n['type'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: type == 'emergency_request'
                            ? AppColors.emergencyRed.withValues(alpha: 0.15)
                            : AppColors.donorGreen.withValues(alpha: 0.15),
                        child: Icon(
                          type == 'emergency_request'
                              ? Icons.emergency
                              : Icons.volunteer_activism,
                          color: type == 'emergency_request'
                              ? AppColors.emergencyRed
                              : AppColors.donorGreen,
                          size: 20,
                        ),
                      ),
                      title: Text(title, style: AppTypography.labelLarge),
                      subtitle: Text(body, style: AppTypography.bodyMedium),
                      onTap: () async {
                        // Mark as read
                        await ref
                            .read(messagingServiceProvider)
                            .markNotificationRead(uid, n['id'] as String);
                        // Navigate if there's a request
                        if (requestId != null && requestId.isNotEmpty) {
                          if (context.mounted) Navigator.of(context).pop();
                          router.push(RouteNames.requestDetailRoute(requestId));
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text('Could not load notifications.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
