import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/game_id.dart';
import '../../../core/models/score_entry.dart';
import '../../../data/repositories/score_repo.dart';
import 'logic_gate.dart';

final towerLogicControllerProvider = StateNotifierProvider.autoDispose<TowerLogicController, TowerLogicState>((ref) {
  final scoreRepo = ref.watch(scoreRepositoryProvider);
  return TowerLogicController(scoreRepo)..initialize();
});

class TowerLogicState {
  const TowerLogicState({
    required this.level,
    required this.wave,
    required this.hp,
    required this.score,
    required this.towers,
    required this.enemies,
    required this.paused,
    required this.speedMultiplier,
    required this.pending,
  });

  final int level;
  final int wave;
  final int hp;
  final int score;
  final Map<BoardCell, LogicGateType> towers;
  final List<Enemy> enemies;
  final bool paused;
  final double speedMultiplier;
  final List<Enemy> pending;

  TowerLogicState copyWith({
    int? level,
    int? wave,
    int? hp,
    int? score,
    Map<BoardCell, LogicGateType>? towers,
    List<Enemy>? enemies,
    bool? paused,
    double? speedMultiplier,
    List<Enemy>? pending,
  }) {
    return TowerLogicState(
      level: level ?? this.level,
      wave: wave ?? this.wave,
      hp: hp ?? this.hp,
      score: score ?? this.score,
      towers: towers ?? this.towers,
      enemies: enemies ?? this.enemies,
      paused: paused ?? this.paused,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      pending: pending ?? this.pending,
    );
  }

  static TowerLogicState initial() {
    return TowerLogicState(
      level: 1,
      wave: 1,
      hp: 100,
      score: 0,
      towers: {},
      enemies: const [],
      paused: false,
      speedMultiplier: 1,
      pending: const [],
    );
  }
}

class BoardCell {
  const BoardCell(this.lane, this.position);

  final int lane;
  final int position;

  @override
  bool operator ==(Object other) {
    return other is BoardCell && other.lane == lane && other.position == position;
  }

  @override
  int get hashCode => Object.hash(lane, position);
}

class Enemy {
  Enemy({
    required this.id,
    required this.lane,
    required this.position,
    required this.inputs,
    required this.targetLabel,
    this.alive = true,
    this.resolved = false,
  });

  final int id;
  final int lane;
  int position;
  final LogicInputs inputs;
  final String targetLabel;
  bool alive;
  bool resolved;
}

class TowerLogicController extends StateNotifier<TowerLogicState> {
  TowerLogicController(this._scoreRepo) : super(TowerLogicState.initial());

  final ScoreRepositoryBase _scoreRepo;
  Timer? _timer;
  final Random _rng = Random(131);

  void initialize() {
    _spawnWave();
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) => _tick());
  }

  void _tick() {
    if (state.paused || state.hp <= 0) return;
    final enemies = [...state.enemies];
    final towers = state.towers;
    for (final enemy in enemies) {
      if (!enemy.alive) {
        continue;
      }
      enemy.position += 1;
      final cell = BoardCell(enemy.lane, enemy.position);
      final tower = towers[cell];
      if (tower != null && !enemy.resolved) {
        final output = evaluateGate(tower, enemy.inputs);
        final target = targetForLabel(enemy.targetLabel)(enemy.inputs.a, enemy.inputs.b);
        if (output == target) {
          enemy.alive = false;
          enemy.resolved = true;
          _updateScore(50);
        } else {
          enemy.resolved = true;
          _updateScore(-25);
          _damageBase();
        }
      } else if (enemy.position >= 5) {
        enemy.alive = false;
        _damageBase();
      }
    }

    enemies.removeWhere((e) => !e.alive);

    if (enemies.isEmpty && state.pending.isEmpty) {
      _handleWaveComplete();
    }

    state = state.copyWith(enemies: enemies);

    if (state.pending.isNotEmpty) {
      final next = [...state.pending];
      final spawn = next.removeAt(0);
      state = state.copyWith(
        enemies: [...state.enemies, spawn],
        pending: next,
      );
    }
  }

  void _spawnWave() {
    final wave = state.wave;
    final count = 3 + wave;
    final pending = <Enemy>[];
    for (var i = 0; i < count; i++) {
      final inputs = (a: _rng.nextBool(), b: _rng.nextBool());
      final targetLabel = logicTargets[_rng.nextInt(logicTargets.length)];
      pending.add(
        Enemy(
          id: wave * 100 + i,
          lane: _rng.nextInt(3),
          position: -1,
          inputs: inputs,
          targetLabel: targetLabel,
        ),
      );
    }
    state = state.copyWith(pending: pending, enemies: const []);
  }

  void placeTower(BoardCell cell, LogicGateType type) {
    final towers = {...state.towers, cell: type};
    state = state.copyWith(towers: towers);
  }

  void removeTower(BoardCell cell) {
    final towers = {...state.towers}..remove(cell);
    state = state.copyWith(towers: towers);
  }

  void _updateScore(int delta) {
    state = state.copyWith(score: state.score + delta);
  }

  void _damageBase() {
    state = state.copyWith(hp: state.hp - 10);
  }

  void togglePause() {
    state = state.copyWith(paused: !state.paused);
  }

  void changeSpeed(double multiplier) {
    _timer?.cancel();
    final interval = Duration(milliseconds: (800 / multiplier).round());
    _timer = Timer.periodic(interval, (_) => _tick());
    state = state.copyWith(speedMultiplier: multiplier);
  }

  Future<void> _handleWaveComplete() async {
    final newWave = state.wave + 1;
    final bonus = newWave * 20;
    _updateScore(bonus);
    await _scoreRepo.addScore(
      ScoreEntry(
        gameId: GameId.towerLogic,
        level: state.wave,
        points: state.score,
        durationSec: newWave * 10,
        timestamp: DateTime.now(),
      ),
    );
    state = state.copyWith(wave: newWave);
    _spawnWave();
  }

  void reset() {
    state = TowerLogicState.initial();
    initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
