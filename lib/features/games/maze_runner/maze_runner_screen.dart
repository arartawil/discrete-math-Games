import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/info_dialog.dart';
import '../../../core/widgets/score_badge.dart';
import 'maze_logic.dart';
import 'maze_runner_controller.dart';

class MazeRunnerScreen extends ConsumerStatefulWidget {
  const MazeRunnerScreen({super.key});

  @override
  ConsumerState<MazeRunnerScreen> createState() => _MazeRunnerScreenState();
}

class _MazeRunnerScreenState extends ConsumerState<MazeRunnerScreen> {
  Timer? _timer;
  bool _scoreRecorded = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(mazeRunnerControllerProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final controller = ref.read(mazeRunnerControllerProvider.notifier);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      controller.movePlayer(0, -1);
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      controller.movePlayer(0, 1);
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      controller.movePlayer(1, 0);
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      controller.movePlayer(-1, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mazeRunnerControllerProvider);
    if (state.completed && !_scoreRecorded) {
      _scoreRecorded = true;
      ref.read(mazeRunnerControllerProvider.notifier).recordScore();
    } else if (!state.completed) {
      _scoreRecorded = false;
    }

    final optimal = state.optimalLength;
    final steps = state.steps;
    final points = state.completed
        ? (1000 - 10 * (steps - optimal).clamp(0, 1000) - 2 * state.elapsedSeconds).clamp(0, 1000)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maze Runner – Graph Theory'),
        actions: [
          IconButton(
            onPressed: () {
              InfoDialog.show(
                context,
                title: 'Maze Runner Help',
                markdownText:
                    'Use arrow keys or WASD to move the runner from Start to Goal. Avoid walls and aim to match the optimal BFS path length.\n\nScore = 1000 − 10 × (extra steps) − 2 × seconds. Pause the timer to strategize, reset to regenerate the maze, and show the optimal path after you finish.',
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKey: _handleKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Level ${state.level}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 16),
                  Text('Steps: $steps'),
                  const SizedBox(width: 16),
                  Text('Optimal: ${optimal == 0 ? 'N/A' : optimal}'),
                  const Spacer(),
                  Text('Time: ${state.elapsedSeconds}s'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = (constraints.biggest.shortestSide - 40) / state.size;
                    return Center(
                      child: SizedBox(
                        width: cellSize * state.size,
                        height: cellSize * state.size,
                        child: Stack(
                          children: [
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: state.size,
                              ),
                              itemBuilder: (context, index) {
                                final x = index % state.size;
                                final y = index ~/ state.size;
                                final node = MazeNode(x, y);
                                final isOptimal = state.showOptimal && state.optimalPath.contains(node);
                                Color color;
                                if (node == state.start) {
                                  color = Colors.green.shade300;
                                } else if (node == state.goal) {
                                  color = Colors.red.shade300;
                                } else if (state.walls.contains(node)) {
                                  color = Colors.grey.shade700;
                                } else if (node == state.player) {
                                  color = Colors.blue.shade300;
                                } else if (isOptimal) {
                                  color = Colors.purple.shade200;
                                } else {
                                  color = Colors.white;
                                }
                                return Container(
                                  margin: const EdgeInsets.all(1),
                                  color: color,
                                );
                              },
                              itemCount: state.size * state.size,
                            ),
                            if (state.completed)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Level Complete!', style: TextStyle(color: Colors.white, fontSize: 20)),
                                      const SizedBox(height: 12),
                                      ScoreBadge(points: points ?? 0, durationSec: state.elapsedSeconds),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => ref.read(mazeRunnerControllerProvider.notifier).togglePause(),
                    icon: Icon(state.paused ? Icons.play_arrow : Icons.pause),
                    label: Text(state.paused ? 'Resume' : 'Pause'),
                  ),
                  FilledButton.icon(
                    onPressed: () => ref.read(mazeRunnerControllerProvider.notifier).resetLevel(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                  FilledButton.icon(
                    onPressed: () => ref.read(mazeRunnerControllerProvider.notifier).toggleOptimal(),
                    icon: const Icon(Icons.visibility),
                    label: Text(state.showOptimal ? 'Hide Optimal' : 'Show Optimal'),
                  ),
                  FilledButton.icon(
                    onPressed: state.completed
                        ? () => ref.read(mazeRunnerControllerProvider.notifier).nextLevel()
                        : null,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Next Level'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: Text('Adjacency edges: ${state.adjacencySize}')),
                      Expanded(child: Text('BFS expanded nodes: ${state.nodesExpanded}')),
                      Expanded(child: Text('Player path length: $steps')),
                      Expanded(child: Text('Optimal path length: ${optimal == 0 ? 'N/A' : optimal}')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
