import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:algo_playground/features/games/puzzle_solver/puzzle_logic.dart';

void main() {
  test('Generated boards are solvable', () {
    final rng = Random(1);
    for (var size = 3; size <= 4; size++) {
      final board = shuffledSolvableBoard(size, rng);
      expect(isSolvable(board, size), isTrue);
    }
  });

  test('Manhattan distance lower bound is zero for solved board', () {
    final board = generateSolvedBoard(3);
    expect(manhattanDistance(board, 3), 0);
    expect(inversionCount(board), 0);
  });
}
