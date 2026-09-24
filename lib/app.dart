import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/auth_service.dart';
import 'core/services/messaging_service.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/profile_screen.dart'
    show themeModeNotifierProvider;

class BloodBridgeApp extends ConsumerStatefulWidget {
  const BloodBridgeApp({super.key});

  @override
  ConsumerState<BloodBridgeApp> createState() => _BloodBridgeAppState();
}

class _BloodBridgeAppState extends ConsumerState<BloodBridgeApp> {
  bool _notificationsInitialised = false;

  @override
  void initState() {
    super.initState();
    // Defer to post-frame so router is ready before any navigation attempt
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMessaging());
  }

  Future<void> _initMessaging() async {
    if (_notificationsInitialised) return;
    _notificationsInitialised = true;

    final messagingService = ref.read(messagingServiceProvider);
    final router = ref.read(routerProvider);

    await messagingService.initNotifications(
      onNotificationTap: (requestId) {
        // Navigate to the request detail screen
        router.push(RouteNames.requestDetailRoute(requestId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(themeModeNotifierProvider);

    // Save FCM token whenever the authenticated user changes
    ref.listen(authStateChangesProvider, (prev, next) {
      final uid = next.value?.uid;
      if (uid != null) {
        ref.read(messagingServiceProvider).saveTokenForUser(uid);
      }
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
