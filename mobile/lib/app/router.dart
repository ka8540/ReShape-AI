import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/saved',
        builder: (context, state) => const SavedProjectsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
        builder: (context, state) => const UploadVideoScreen(),
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
