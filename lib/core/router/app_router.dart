import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/donors/presentation/donor_search_screen.dart';
import '../../features/emergency_requests/presentation/create_request_screen.dart';
import '../../features/emergency_requests/presentation/request_detail_screen.dart';
import '../../features/emergency_requests/presentation/request_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/hospitals_banks/presentation/hospitals_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../services/auth_service.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final refreshStream = GoRouterRefreshStream(auth.authStateChanges());
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final isLoggedIn = auth.currentUser != null;
      final location = state.matchedLocation;
      final isSplash = location == RouteNames.splashPath;
      final isAuthRoute =
          location == RouteNames.loginPath || location == RouteNames.registerPath;

      // Allow splash screen animation to finish
      if (isSplash) return null;

      // Redirect unauthenticated user trying to access protected screens
      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.loginPath;
      }

      // Redirect authenticated user away from login or register
      if (isLoggedIn && isAuthRoute) {
        return RouteNames.homePath;
      }

      return null;
    },
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
      GoRoute(
        path: RouteNames.requestDetailPath,
        name: RouteNames.requestDetail,
        builder: (context, state) {
          final requestId = state.pathParameters['requestId'] ?? '';
          return RequestDetailScreen(requestId: requestId);
        },
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
