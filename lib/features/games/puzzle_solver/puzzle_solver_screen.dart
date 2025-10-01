import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/info_dialog.dart';
import '../../../core/widgets/score_badge.dart';
import 'puzzle_solver_controller.dart';

class PuzzleSolverScreen extends ConsumerWidget {
  const PuzzleSolverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(puzzleSolverControllerProvider);
    final controller = ref.read(puzzleSolverControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Solver – Combinatorics'),
        actions: [
          IconButton(
            onPressed: () {
              InfoDialog.show(
                context,
                title: 'Puzzle Solver Help',
                markdownText:
                    'Arrange the numbered tiles into the target order. Only tiles adjacent to the blank may move. Use the **Hint** button to view the Manhattan distance lower bound and inversion count.\n\nScore = 1500 − 5 × moves − 2 × seconds + inversion bonus. Fewer moves and faster solutions earn higher scores!',
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Level ${state.level}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                Text('Moves: ${state.moves}'),
                const SizedBox(width: 16),
                Text('Time: ${state.seconds}s'),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: controller.togglePause,
                  icon: Icon(state.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(state.paused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = state.size;
                  final boardSize = constraints.biggest.shortestSide * 0.8;
                  final tileSize = boardSize / size;
                  return Center(
                    child: SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                        ),
                        itemCount: size * size,
                        itemBuilder: (context, index) {
                          final value = state.tiles[index];
                          final isBlank = value == 0;
                          return GestureDetector(
                            onTap: () => controller.moveTile(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isBlank ? Colors.grey.shade300 : Colors.indigo.shade200,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  if (!isBlank)
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isBlank ? '' : '$value',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: controller.hint,
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('Hint'),
                ),
                FilledButton.icon(
                  onPressed: controller.shuffle,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle'),
                ),
                FilledButton.icon(
                  onPressed: controller.nextLevel,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next Level'),
                ),
              ],
            ),
            if (state.hintText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(state.hintText),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ScoreBadge(points: state.score, durationSec: state.seconds),
            ),
          ],
        ),
      ),
    );
  }
}
