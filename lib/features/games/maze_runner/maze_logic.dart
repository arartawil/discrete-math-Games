import 'dart:collection';
import 'dart:math';

import '../../../core/utils/rng.dart';

class MazeNode {
  const MazeNode(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is MazeNode && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class MazeResult {
  const MazeResult({
    required this.walls,
    required this.optimalPath,
    required this.nodesExpanded,
  });

  final Set<MazeNode> walls;
  final List<MazeNode> optimalPath;
  final int nodesExpanded;
}

MazeResult generateMaze(int level, {int baseSize = 7}) {
  final size = baseSize + level - 1;
  final start = const MazeNode(0, 0);
  final goal = MazeNode(size - 1, size - 1);
  final seed = level * 7919;
  final rng = SeededRandom(seed);

  for (var attempt = 0; attempt < 50; attempt++) {
    final walls = <MazeNode>{};
    final density = 0.18 + (level * 0.01);
    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        if ((x == start.x && y == start.y) || (x == goal.x && y == goal.y)) {
          continue;
        }
        if (rng.nextDouble() < density) {
          walls.add(MazeNode(x, y));
        }
      }
    }
    final bfs = bfsShortestPath(size, start, goal, walls);
    if (bfs.optimalPath.isNotEmpty) {
      return bfs;
    }
  }
  return bfsShortestPath(size, start, goal, {});
}

MazeResult bfsShortestPath(int size, MazeNode start, MazeNode goal, Set<MazeNode> walls) {
  final queue = Queue<MazeNode>();
  final cameFrom = <MazeNode, MazeNode?>{};
  final visited = <MazeNode>{};
  queue.add(start);
  cameFrom[start] = null;
  var nodesExpanded = 0;

  bool isWalkable(int x, int y) {
    if (x < 0 || y < 0 || x >= size || y >= size) {
      return false;
    }
    return !walls.contains(MazeNode(x, y));
  }

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    nodesExpanded++;
    if (current == goal) {
      break;
    }
    final neighbors = [
      MazeNode(current.x + 1, current.y),
      MazeNode(current.x - 1, current.y),
      MazeNode(current.x, current.y + 1),
      MazeNode(current.x, current.y - 1),
    ];
    for (final next in neighbors) {
      if (!isWalkable(next.x, next.y) || visited.contains(next)) {
        continue;
      }
      if (!cameFrom.containsKey(next)) {
        queue.add(next);
        cameFrom[next] = current;
      }
    }
    visited.add(current);
  }

  if (!cameFrom.containsKey(goal)) {
    return MazeResult(walls: walls, optimalPath: const [], nodesExpanded: nodesExpanded);
  }

  final path = <MazeNode>[];
  MazeNode? current = goal;
  while (current != null) {
    path.add(current);
    current = cameFrom[current];
  }
  return MazeResult(
    walls: walls,
    optimalPath: path.reversed.toList(),
    nodesExpanded: nodesExpanded,
  );
}
