import 'package:flutter_test/flutter_test.dart';

import 'package:algo_playground/core/models/game_id.dart';
import 'package:algo_playground/core/models/score_entry.dart';
import 'package:algo_playground/data/repositories/score_repo.dart';
import 'package:algo_playground/features/games/matching_pairs/matching_pairs_controller.dart';

class FakeScoreRepo implements ScoreRepositoryBase {
  final List<ScoreEntry> entries = [];

  @override
  Future<void> addScore(ScoreEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<List<ScoreEntry>> getScores() async => entries;

  @override
  Future<ScoreEntry?> lastScoreFor(GameId game) async => entries.lastOrNull;

  @override
  Future<void> reset() async {
    entries.clear();
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

void main() {
  test('Function mode prevents multiple codomain selections', () {
    final repo = FakeScoreRepo();
    final controller = MatchingPairsController(repo);
    controller.initialize();
    controller.toggleMode(); // switch to function mode
    final domainItem = controller.state.domain.first;
    final codomain = controller.state.codomain.first;
    final otherCodomain = controller.state.codomain.last;

    controller.selectDomain(domainItem);
    controller.selectCodomain(codomain);
    expect(controller.state.valid, 1);

    controller.selectDomain(domainItem);
    controller.selectCodomain(otherCodomain);
    expect(controller.state.valid, 1); // no new valid mapping
    expect(controller.state.attempts, 2);
    expect(controller.state.warning, isNotNull);
  });
}
