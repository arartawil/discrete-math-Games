import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/game_id.dart';
import '../../../core/models/score_entry.dart';
import '../../../data/repositories/score_repo.dart';
import 'puzzle_logic.dart';

final puzzleSolverControllerProvider = StateNotifierProvider.autoDispose<PuzzleSolverController, PuzzleSolverState>((ref) {
  final repo = ref.watch(scoreRepositoryProvider);
  return PuzzleSolverController(repo)..initialize();
});

class PuzzleSolverState {
  const PuzzleSolverState({
    required this.level,
    required this.size,
    required this.tiles,
    required this.moves,
    required this.seconds,
    required this.solved,
    required this.hintText,
    required this.paused,
  });

  final int level;
  final int size;
  final List<int> tiles;
  final int moves;
  final int seconds;
  final bool solved;
  final String hintText;
  final bool paused;

  int get score {
    final base = 1500 - 5 * moves - 2 * seconds;
    final bonus = max(0, 100 - inversionCount(tiles));
    return max(0, base + bonus);
  }

  PuzzleSolverState copyWith({
    int? level,
    int? size,
    List<int>? tiles,
    int? moves,
    int? seconds,
    bool? solved,
    String? hintText,
    bool? paused,
  }) {
    return PuzzleSolverState(
      level: level ?? this.level,
      size: size ?? this.size,
      tiles: tiles ?? this.tiles,
      moves: moves ?? this.moves,
      seconds: seconds ?? this.seconds,
      solved: solved ?? this.solved,
      hintText: hintText ?? this.hintText,
      paused: paused ?? this.paused,
    );
  }

  static PuzzleSolverState initial() {
    return PuzzleSolverState(
      level: 1,
      size: 3,
      tiles: generateSolvedBoard(3),
      moves: 0,
      seconds: 0,
      solved: false,
      hintText: '',
      paused: false,
    );
  }
}

class PuzzleSolverController extends StateNotifier<PuzzleSolverState> {
  PuzzleSolverController(this._repo) : super(PuzzleSolverState.initial());

  final ScoreRepositoryBase _repo;
  Timer? _timer;
  final Random _rng = Random(99);

  void initialize() {
    _loadLevel(state.level);
    _startTimer();
  }

  void _loadLevel(int level) {
    final size = level == 1 ? 3 : min(4, 2 + level);
    final tiles = shuffledSolvableBoard(size, _rng);
    state = PuzzleSolverState(
      level: level,
      size: size,
      tiles: tiles,
      moves: 0,
      seconds: 0,
      solved: false,
      hintText: '',
      paused: false,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.paused && !state.solved) {
        state = state.copyWith(seconds: state.seconds + 1);
      }
    });
  }

  void togglePause() {
    state = state.copyWith(paused: !state.paused);
  }

  void moveTile(int index) {
    if (state.solved || state.paused) return;
    final zeroIndex = state.tiles.indexOf(0);
    final size = state.size;
    final zeroRow = zeroIndex ~/ size;
    final zeroCol = zeroIndex % size;
    final tileRow = index ~/ size;
    final tileCol = index % size;
    final isAdjacent = (zeroRow == tileRow && (zeroCol - tileCol).abs() == 1) ||
        (zeroCol == tileCol && (zeroRow - tileRow).abs() == 1);
    if (!isAdjacent) return;
    final tiles = [...state.tiles];
    tiles[zeroIndex] = tiles[index];
    tiles[index] = 0;
    final moves = state.moves + 1;
    final solved = isSolved(tiles);
    state = state.copyWith(tiles: tiles, moves: moves, solved: solved);
    if (solved) {
      _recordScore();
    }
  }

  void shuffle() {
    _loadLevel(state.level);
  }

  void nextLevel() {
    _loadLevel(state.level + 1);
  }

  void hint() {
    final manhattan = manhattanDistance(state.tiles, state.size);
    final inversions = inversionCount(state.tiles);
    state = state.copyWith(
      hintText: 'Manhattan lower bound: $manhattan, inversions: $inversions',
    );
  }

  Future<void> _recordScore() async {
    await _repo.addScore(
      ScoreEntry(
        gameId: GameId.puzzleSolver,
        level: state.level,
        points: state.score,
        durationSec: state.seconds,
        timestamp: DateTime.now(),
      ),
    );
  }

  void reset() {
    _loadLevel(state.level);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
