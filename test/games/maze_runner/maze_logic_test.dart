import 'package:flutter_test/flutter_test.dart';

import 'package:algo_playground/features/games/maze_runner/maze_logic.dart';

void main() {
  test('BFS computes expected path length on simple grid', () {
    final size = 5;
    final start = const MazeNode(0, 0);
    final goal = const MazeNode(4, 4);
    final walls = {
      const MazeNode(1, 0),
      const MazeNode(1, 1),
      const MazeNode(3, 2),
    };
    final result = bfsShortestPath(size, start, goal, walls);
    expect(result.optimalPath.first, start);
    expect(result.optimalPath.last, goal);
    for (final node in result.optimalPath) {
      expect(walls.contains(node), isFalse);
    }
    expect(result.optimalPath.length, greaterThan(0));
  });

  test('Generated mazes always have a valid path', () {
    for (var level = 1; level < 5; level++) {
      final result = generateMaze(level);
      expect(result.optimalPath.isNotEmpty, isTrue);
    }
  });
}
