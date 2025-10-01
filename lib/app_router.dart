import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/repositories/profile_repo.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/games/matching_pairs/matching_pairs_screen.dart';
import 'features/games/maze_runner/maze_runner_screen.dart';
import 'features/games/puzzle_solver/puzzle_solver_screen.dart';
import 'features/games/tower_logic/tower_logic_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/scores/scores_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(profileNotifierProvider.future).asStream(),
    ),
    redirect: (context, state) async {
      final profile = await ref.read(profileNotifierProvider.future);
      final loggingIn = state.matchedLocation == '/';
      if (profile == null) {
        return loggingIn ? null : '/';
      }
      if (loggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/scores',
        builder: (context, state) => const ScoresScreen(),
      ),
      GoRoute(
        path: '/game/maze-runner',
        builder: (context, state) => const MazeRunnerScreen(),
      ),
      GoRoute(
        path: '/game/tower-logic',
        builder: (context, state) => const TowerLogicScreen(),
      ),
      GoRoute(
        path: '/game/matching-pairs',
        builder: (context, state) => const MatchingPairsScreen(),
      ),
      GoRoute(
        path: '/game/puzzle-solver',
        builder: (context, state) => const PuzzleSolverScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
