import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/donors/presentation/donor_search_screen.dart';
import '../../features/emergency_requests/presentation/create_request_screen.dart';
import '../../features/emergency_requests/presentation/request_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/hospitals_banks/presentation/hospitals_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.createRequestPath,
        name: RouteNames.createRequest,
        builder: (context, state) => const CreateRequestScreen(),
      ),

      // Stateful Shell Route for Bottom Navigation Bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.homePath,
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Emergency Requests Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.requestsPath,
                name: RouteNames.requests,
                builder: (context, state) => const RequestListScreen(),
              ),
            ],
          ),
          // Donors Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.donorsPath,
                name: RouteNames.donors,
                builder: (context, state) => const DonorSearchScreen(),
              ),
            ],
          ),
          // Hospitals Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.hospitalsPath,
                name: RouteNames.hospitals,
                builder: (context, state) => const HospitalsScreen(),
              ),
            ],
          ),
          // Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
