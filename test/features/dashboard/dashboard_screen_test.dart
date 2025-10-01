import 'package:algo_playground/app_router.dart';
import 'package:algo_playground/core/models/game_id.dart';
import 'package:algo_playground/core/models/score_entry.dart';
import 'package:algo_playground/core/models/user_profile.dart';
import 'package:algo_playground/data/repositories/profile_repo.dart';
import 'package:algo_playground/data/repositories/score_repo.dart';
import 'package:algo_playground/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeScoreRepo implements ScoreRepositoryBase {
  @override
  Future<void> addScore(ScoreEntry entry) async {}

  @override
  Future<List<ScoreEntry>> getScores() async => const [];

  @override
  Future<ScoreEntry?> lastScoreFor(GameId game) async => null;

  @override
  Future<void> reset() async {}
}

void main() {
  testWidgets('Dashboard navigation to scores screen works', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/scores',
          builder: (context, state) => const Scaffold(body: Text('Scores view')),
        ),
      ],
      initialLocation: '/dashboard',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWithValue(const AsyncValue.data(UserProfile(name: 'Test', studentNumber: '1'))),
          profileRepositoryProvider.overrideWithValue(_NoopProfileRepo()),
          scoreRepositoryProvider.overrideWithValue(FakeScoreRepo()),
          scoreListProvider.overrideWithValue(const AsyncValue.data(<ScoreEntry>[])),
          appRouterProvider.overrideWithValue(router),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome'), findsOneWidget);

    await tester.tap(find.text('Scores'));
    await tester.pumpAndSettle();

    expect(find.text('Scores view'), findsOneWidget);
  });
}

class _NoopProfileRepo implements ProfileRepositoryBase {
  @override
  Future<UserProfile?> getProfile() async => const UserProfile(name: 'Test', studentNumber: '1');

  @override
  Future<void> saveProfile(UserProfile profile) async {}
}
