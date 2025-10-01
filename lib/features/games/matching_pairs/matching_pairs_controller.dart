import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/game_id.dart';
import '../../../core/models/score_entry.dart';
import '../../../data/repositories/score_repo.dart';

final matchingPairsControllerProvider = StateNotifierProvider.autoDispose<MatchingPairsController, MatchingPairsState>((ref) {
  final repo = ref.watch(scoreRepositoryProvider);
  return MatchingPairsController(repo)..initialize();
});

class MatchingPairsState {
  const MatchingPairsState({
    required this.level,
    required this.domain,
    required this.codomain,
    required this.relation,
    required this.attempts,
    required this.valid,
    required this.functionMode,
    required this.seconds,
    required this.warning,
    required this.paused,
    required this.roundOver,
  });

  final int level;
  final List<String> domain;
  final List<String> codomain;
  final Map<String, Set<String>> relation;
  final int attempts;
  final int valid;
  final bool functionMode;
  final int seconds;
  final String? warning;
  final bool paused;
  final bool roundOver;

  int get invalid => attempts - valid;
  int get score => valid * 20 - invalid * 5 + (max(0, 60 - seconds));

  MatchingPairsState copyWith({
    int? level,
    List<String>? domain,
    List<String>? codomain,
    Map<String, Set<String>>? relation,
    int? attempts,
    int? valid,
    bool? functionMode,
    int? seconds,
    String? warning,
    bool? paused,
    bool? roundOver,
  }) {
    return MatchingPairsState(
      level: level ?? this.level,
      domain: domain ?? this.domain,
      codomain: codomain ?? this.codomain,
      relation: relation ?? this.relation,
      attempts: attempts ?? this.attempts,
      valid: valid ?? this.valid,
      functionMode: functionMode ?? this.functionMode,
      seconds: seconds ?? this.seconds,
      warning: warning,
      paused: paused ?? this.paused,
      roundOver: roundOver ?? this.roundOver,
    );
  }

  static MatchingPairsState initial() {
    return MatchingPairsState(
      level: 1,
      domain: const [],
      codomain: const [],
      relation: const {},
      attempts: 0,
      valid: 0,
      functionMode: false,
      seconds: 0,
      warning: null,
      paused: false,
      roundOver: false,
    );
  }
}

class MatchingPairsController extends StateNotifier<MatchingPairsState> {
  MatchingPairsController(this._repo) : super(MatchingPairsState.initial());

  final ScoreRepositoryBase _repo;
  Timer? _timer;
  String? _selectedDomain;
  final Random _rng = Random(42);

  void initialize() {
    _generateLevel(state.level);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.paused && !state.roundOver) {
        final seconds = state.seconds + 1;
        var roundOver = false;
        if (seconds >= 60) {
          roundOver = true;
        }
        state = state.copyWith(seconds: seconds, roundOver: roundOver, warning: state.warning);
        if (roundOver) {
          _recordScore();
        }
      }
    });
  }

  void _generateLevel(int level) {
    final domainSize = 3 + level;
    final codomainSize = 3 + level;
    final domain = List<String>.generate(domainSize, (i) => 'd${i + 1}')..shuffle(_rng);
    final codomain = List<String>.generate(codomainSize, (i) => 'c${i + 1}')..shuffle(_rng);
    state = MatchingPairsState(
      level: level,
      domain: domain,
      codomain: codomain,
      relation: {for (final d in domain) d: <String>{}},
      attempts: 0,
      valid: 0,
      functionMode: state.functionMode,
      seconds: 0,
      warning: null,
      paused: false,
      roundOver: false,
    );
  }

  void selectDomain(String value) {
    if (state.roundOver) return;
    _selectedDomain = value;
    state = state.copyWith(warning: null);
  }

  void selectCodomain(String value) {
    if (state.roundOver) return;
    if (_selectedDomain == null) {
      state = state.copyWith(warning: 'Select a domain element first.');
      return;
    }
    final relation = {for (final entry in state.relation.entries) entry.key: {...entry.value}};
    final targetSet = relation[_selectedDomain!] ?? <String>{};
    if (state.functionMode && targetSet.isNotEmpty && !targetSet.contains(value)) {
      state = state.copyWith(warning: 'Functions map to exactly one codomain value.');
      _incrementAttempts(valid: false);
      return;
    }
    final alreadyExists = targetSet.contains(value);
    if (!alreadyExists) {
      targetSet.add(value);
      relation[_selectedDomain!] = targetSet;
      state = state.copyWith(relation: relation, warning: null);
      _incrementAttempts(valid: true);
    } else {
      state = state.copyWith(warning: 'Pair already created.');
    }
  }

  void _incrementAttempts({required bool valid}) {
    final attempts = state.attempts + 1;
    final validCount = state.valid + (valid ? 1 : 0);
    state = state.copyWith(attempts: attempts, valid: validCount);
    if (state.functionMode) {
      final allMapped = state.relation.values.every((set) => set.isNotEmpty);
      if (allMapped) {
        state = state.copyWith(roundOver: true);
        _recordScore();
      }
    }
  }

  void toggleMode() {
    state = state.copyWith(functionMode: !state.functionMode, warning: null);
  }

  bool get isInjective {
    final used = <String>{};
    for (final set in state.relation.values) {
      for (final value in set) {
        if (used.contains(value)) {
          return false;
        }
        used.add(value);
      }
    }
    return true;
  }

  bool get isSurjective {
    final used = <String>{};
    for (final set in state.relation.values) {
      used.addAll(set);
    }
    return used.length == state.codomain.length;
  }

  Future<void> _recordScore() async {
    await _repo.addScore(
      ScoreEntry(
        gameId: GameId.matchingPairs,
        level: state.level,
        points: state.score,
        durationSec: state.seconds,
        timestamp: DateTime.now(),
      ),
    );
  }

  void nextLevel() {
    final newLevel = state.level + 1;
    _generateLevel(newLevel);
  }

  void reset() {
    _generateLevel(state.level);
  }

  void pauseToggle() {
    state = state.copyWith(paused: !state.paused);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
