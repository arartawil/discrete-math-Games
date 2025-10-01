import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/game_id.dart';
import '../../../core/models/score_entry.dart';
import '../../../data/repositories/score_repo.dart';
import 'maze_logic.dart';

final mazeRunnerControllerProvider = StateNotifierProvider.autoDispose<MazeRunnerController, MazeGameState>((ref) {
  final scoreRepo = ref.watch(scoreRepositoryProvider);
  return MazeRunnerController(scoreRepo: scoreRepo)..initialize();
});

class MazeGameState {
  const MazeGameState({
    required this.level,
    required this.size,
    required this.walls,
    required this.start,
    required this.goal,
    required this.player,
    required this.steps,
    required this.completed,
    required this.optimalPath,
    required this.nodesExpanded,
    required this.showOptimal,
    required this.adjacencySize,
    required this.elapsedSeconds,
    required this.paused,
  });

  final int level;
  final int size;
  final Set<MazeNode> walls;
  final MazeNode start;
  final MazeNode goal;
  final MazeNode player;
  final int steps;
  final bool completed;
  final List<MazeNode> optimalPath;
  final int nodesExpanded;
  final bool showOptimal;
  final int adjacencySize;
  final int elapsedSeconds;
  final bool paused;

  int get optimalLength => optimalPath.isEmpty ? 0 : optimalPath.length - 1;

  MazeGameState copyWith({
    int? level,
    int? size,
    Set<MazeNode>? walls,
    MazeNode? start,
    MazeNode? goal,
    MazeNode? player,
    int? steps,
    bool? completed,
    List<MazeNode>? optimalPath,
    int? nodesExpanded,
    bool? showOptimal,
    int? adjacencySize,
    int? elapsedSeconds,
    bool? paused,
  }) {
    return MazeGameState(
      level: level ?? this.level,
      size: size ?? this.size,
      walls: walls ?? this.walls,
      start: start ?? this.start,
      goal: goal ?? this.goal,
      player: player ?? this.player,
      steps: steps ?? this.steps,
      completed: completed ?? this.completed,
      optimalPath: optimalPath ?? this.optimalPath,
      nodesExpanded: nodesExpanded ?? this.nodesExpanded,
      showOptimal: showOptimal ?? this.showOptimal,
      adjacencySize: adjacencySize ?? this.adjacencySize,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      paused: paused ?? this.paused,
    );
  }

  static MazeGameState initial() {
    return MazeGameState(
      level: 1,
      size: 7,
      walls: {},
      start: const MazeNode(0, 0),
      goal: const MazeNode(0, 0),
      player: const MazeNode(0, 0),
      steps: 0,
      completed: false,
      optimalPath: const [],
      nodesExpanded: 0,
      showOptimal: false,
      adjacencySize: 0,
      elapsedSeconds: 0,
      paused: false,
    );
  }
}

class MazeRunnerController extends StateNotifier<MazeGameState> {
  MazeRunnerController({required ScoreRepositoryBase scoreRepo})
      : _scoreRepo = scoreRepo,
        super(MazeGameState.initial());

  final ScoreRepositoryBase _scoreRepo;

  void initialize() {
    _loadLevel(state.level);
  }

  void _loadLevel(int level) {
    final result = generateMaze(level);
    final size = 7 + level - 1;
    final start = const MazeNode(0, 0);
    final goal = MazeNode(size - 1, size - 1);
    final adjacency = _computeAdjacencySize(size, result.walls);
    state = MazeGameState(
      level: level,
      size: size,
      walls: result.walls,
      start: start,
      goal: goal,
      player: start,
      steps: 0,
      completed: false,
      optimalPath: result.optimalPath,
      nodesExpanded: result.nodesExpanded,
      showOptimal: false,
      adjacencySize: adjacency,
      elapsedSeconds: 0,
      paused: false,
    );
  }

  int _computeAdjacencySize(int size, Set<MazeNode> walls) {
    int count = 0;
    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        final node = MazeNode(x, y);
        if (walls.contains(node)) continue;
        final neighbors = [
          MazeNode(x + 1, y),
          MazeNode(x - 1, y),
          MazeNode(x, y + 1),
          MazeNode(x, y - 1),
        ];
        for (final n in neighbors) {
          if (n.x >= 0 && n.y >= 0 && n.x < size && n.y < size && !walls.contains(n)) {
            count++;
          }
        }
      }
    }
    return count;
  }

  void movePlayer(int dx, int dy) {
    if (state.completed || state.paused) {
      return;
    }
    final next = MazeNode(state.player.x + dx, state.player.y + dy);
    if (next.x < 0 || next.y < 0 || next.x >= state.size || next.y >= state.size) {
      return;
    }
    if (state.walls.contains(next)) {
      return;
    }
    final steps = state.steps + 1;
    final completed = next == state.goal;
    state = state.copyWith(player: next, steps: steps, completed: completed);
  }

  void resetLevel() {
    _loadLevel(state.level);
  }

  void nextLevel() {
    _loadLevel(state.level + 1);
  }

  void toggleOptimal() {
    state = state.copyWith(showOptimal: !state.showOptimal);
  }

  void togglePause() {
    state = state.copyWith(paused: !state.paused);
  }

  void tick() {
    if (!state.completed && !state.paused) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    }
  }

  Future<void> recordScore() async {
    if (!state.completed) return;
    final optimal = max(state.optimalLength, 1);
    final penaltySteps = max(0, state.steps - optimal);
    var score = 1000 - 10 * penaltySteps - 2 * state.elapsedSeconds;
    if (score < 0) score = 0;
    await _scoreRepo.addScore(
      ScoreEntry(
        gameId: GameId.mazeRunner,
        level: state.level,
        points: score,
        durationSec: state.elapsedSeconds,
        timestamp: DateTime.now(),
      ),
    );
  }
}
