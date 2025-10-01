import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/game_id.dart';
import '../../core/models/score_entry.dart';
import '../../core/widgets/score_badge.dart';
import '../../data/repositories/score_repo.dart';

class ScoresScreen extends ConsumerStatefulWidget {
  const ScoresScreen({super.key});

  @override
  ConsumerState<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends ConsumerState<ScoresScreen> {
  GameId? _filter;

  @override
  Widget build(BuildContext context) {
    final scoresAsync = ref.watch(scoreListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Scores'),
                    content: const Text('Clear all stored scores?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final repo = ref.read(scoreRepositoryProvider);
                  await repo.reset();
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'reset', child: Text('Reset scores')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                ...GameId.values.map(
                  (game) => FilterChip(
                    label: Text(game.label.split(' – ').first),
                    selected: _filter == game,
                    onSelected: (_) => setState(() => _filter = game),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: scoresAsync.when(
                data: (scores) {
                  final sorted = scores.toList()
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  final filtered = _filter == null
                      ? sorted
                      : sorted.where((s) => s.gameId == _filter).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No scores yet'));
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            switch (entry.gameId) {
                              GameId.mazeRunner => Icons.route,
                              GameId.towerLogic => Icons.memory,
                              GameId.matchingPairs => Icons.device_hub,
                              GameId.puzzleSolver => Icons.extension,
                            },
                          ),
                          title: Text('${entry.gameId.label} — Level ${entry.level}'),
                          subtitle: Text('Played on ${entry.timestamp.toLocal()}'),
                          trailing: ScoreBadge(
                            points: entry.points,
                            durationSec: entry.durationSec,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
