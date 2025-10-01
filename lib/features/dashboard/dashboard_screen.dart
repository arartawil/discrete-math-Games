import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/game_id.dart';
import '../../core/models/score_entry.dart';
import '../../core/widgets/score_badge.dart';
import '../../data/repositories/profile_repo.dart';
import '../../data/repositories/score_repo.dart';
import '../../core/widgets/info_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final scoresAsync = ref.watch(scoreListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlgoPlayground'),
        actions: [
          IconButton(
            onPressed: () => context.go('/scores'),
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Scores',
          ),
          IconButton(
            onPressed: () {
              InfoDialog.show(
                context,
                title: 'About AlgoPlayground',
                markdownText:
                    'Explore discrete mathematics concepts through games. Track your progress and challenge yourself with each level!\n\nNavigate using the top bar to view your scores or jump directly into a game.',
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return const SizedBox.shrink();
                }
                return Text(
                  'Welcome ${profile.name} (#${profile.studentNumber})',
                  style: Theme.of(context).textTheme.titleLarge,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('Error loading profile: $error'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: scoresAsync.when(
                data: (scores) => _GameGrid(scores: scores),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.go('/scores');
          } else if (index == 2) {
            InfoDialog.show(
              context,
              title: 'Need Help?',
              markdownText:
                  'Each game includes a help panel explaining the rules and scoring. Use the pause button to take breaks and the reset button to try levels again.',
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Scores'),
          NavigationDestination(icon: Icon(Icons.help_center), label: 'Help'),
        ],
      ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.scores});

  final List<ScoreEntry> scores;

  ScoreEntry? _lastFor(GameId gameId) {
    for (final entry in scores.reversed) {
      if (entry.gameId == gameId) {
        return entry;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cards = GameId.values.map((game) {
      final last = _lastFor(game);
      return _GameCard(gameId: game, lastScore: last);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1000
            ? 4
            : width > 700
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.05,
          children: cards,
        );
      },
    );
  }
}

class _GameCard extends ConsumerWidget {
  const _GameCard({required this.gameId, this.lastScore});

  final GameId gameId;
  final ScoreEntry? lastScore;

  String get description {
    switch (gameId) {
      case GameId.mazeRunner:
        return 'Navigate mazes and compare your path with optimal BFS routes.';
      case GameId.towerLogic:
        return 'Deploy logic gate towers to defeat waves of binary enemies.';
      case GameId.matchingPairs:
        return 'Build relations and functions by pairing domain and codomain sets.';
      case GameId.puzzleSolver:
        return 'Solve sliding puzzles with combinatorial insights and hints.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(gameId.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                switch (gameId) {
                  GameId.mazeRunner => Icons.route,
                  GameId.towerLogic => Icons.memory,
                  GameId.matchingPairs => Icons.device_hub,
                  GameId.puzzleSolver => Icons.extension,
                },
                size: 36,
              ),
              const SizedBox(height: 16),
              Text(
                gameId.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(description),
              const Spacer(),
              if (lastScore != null)
                ScoreBadge(
                  points: lastScore!.points,
                  durationSec: lastScore!.durationSec,
                )
              else
                const Text('No score yet'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => context.go(gameId.route),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
