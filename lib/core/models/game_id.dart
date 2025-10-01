enum GameId {
  mazeRunner,
  towerLogic,
  matchingPairs,
  puzzleSolver,
}

extension GameIdX on GameId {
  String get label {
    switch (this) {
      case GameId.mazeRunner:
        return 'Maze Runner – Graph Theory';
      case GameId.towerLogic:
        return 'Tower Defense – Logic Gates';
      case GameId.matchingPairs:
        return 'Matching Pairs – Relations & Functions';
      case GameId.puzzleSolver:
        return 'Puzzle Solver – Combinatorics';
    }
  }

  String get route {
    switch (this) {
      case GameId.mazeRunner:
        return '/game/maze-runner';
      case GameId.towerLogic:
        return '/game/tower-logic';
      case GameId.matchingPairs:
        return '/game/matching-pairs';
      case GameId.puzzleSolver:
        return '/game/puzzle-solver';
    }
  }

  static GameId fromJson(String value) {
    return GameId.values.firstWhere(
      (g) => g.name == value,
      orElse: () => GameId.mazeRunner,
    );
  }
}
