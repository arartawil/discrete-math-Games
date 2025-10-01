import 'dart:math';

List<int> generateSolvedBoard(int size) {
  return List<int>.generate(size * size, (i) => i == size * size - 1 ? 0 : i + 1);
}

int inversionCount(List<int> tiles) {
  int inversions = 0;
  for (var i = 0; i < tiles.length; i++) {
    for (var j = i + 1; j < tiles.length; j++) {
      if (tiles[i] == 0 || tiles[j] == 0) continue;
      if (tiles[i] > tiles[j]) {
        inversions++;
      }
    }
  }
  return inversions;
}

bool isSolvable(List<int> tiles, int size) {
  final inv = inversionCount(tiles);
  if (size.isOdd) {
    return inv.isEven;
  }
  final rowFromBottom = size - (tiles.indexOf(0) ~/ size);
  if (rowFromBottom.isEven) {
    return inv.isOdd;
  } else {
    return inv.isEven;
  }
}

int manhattanDistance(List<int> tiles, int size) {
  int distance = 0;
  for (var index = 0; index < tiles.length; index++) {
    final value = tiles[index];
    if (value == 0) continue;
    final targetRow = (value - 1) ~/ size;
    final targetCol = (value - 1) % size;
    final currentRow = index ~/ size;
    final currentCol = index % size;
    distance += (targetRow - currentRow).abs() + (targetCol - currentCol).abs();
  }
  return distance;
}

List<int> shuffledSolvableBoard(int size, Random rng) {
  final tiles = generateSolvedBoard(size);
  List<int> shuffled;
  do {
    shuffled = [...tiles];
    shuffled.shuffle(rng);
  } while (!isSolvable(shuffled, size) || _isSolved(shuffled));
  return shuffled;
}

bool _isSolved(List<int> tiles) {
  for (var i = 0; i < tiles.length - 1; i++) {
    if (tiles[i] != i + 1) {
      return false;
    }
  }
  return tiles.last == 0;
}

bool isSolved(List<int> tiles) => _isSolved(tiles);
