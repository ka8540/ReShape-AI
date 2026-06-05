import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';
import '../screens/screens.dart';
import '../state/auth_state.dart';
import '../widgets/design_system.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth status so the router re-evaluates redirects on sign-in/out.
  final auth = ref.watch(appAuthControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      // Auth gate is ALWAYS on. The only public route is /login (which itself
      // tells the user when Firebase isn't configured).
      final loggingIn = state.matchedLocation == '/login';
      switch (auth.status) {
        case AppAuthStatus.booting:
        case AppAuthStatus.unauthenticated:
        case AppAuthStatus.guest:
          return loggingIn ? null : '/login';
        case AppAuthStatus.authenticated:
          return loggingIn ? '/home' : null;
      }
    },
    // Transition policy (see ReSpaceApp.pageTransitionsTheme):
    //   • Bottom-tab pages and the login gate use NoTransitionPage so switching
    //     tabs is instant and never animates like a slideshow.
    //   • Every other route uses the default page, which inherits the single
    //     app-wide transition, so the whole flow animates the same way.
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainTabsShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SavedProjectsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/mode',
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CaptureInstructionsScreen(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadMediaScreen(),
      ),
      GoRoute(
        path: '/processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewItemsScreen(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: '/layout/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return LayoutDetailScreen(layoutId: id);
        },
      ),
      GoRoute(
        path: '/final',
        builder: (context, state) => const FinalPlanScreen(),
      ),
      GoRoute(
        path: '/redesign',
        builder: (context, state) => const RedesignComingSoonScreen(),
      ),
    ],
  );
});
