import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/game_id.dart';
import '../../core/models/score_entry.dart';
import '../../core/services/storage_service.dart';

abstract class ScoreRepositoryBase {
  Future<List<ScoreEntry>> getScores();
  Future<void> addScore(ScoreEntry entry);
  Future<ScoreEntry?> lastScoreFor(GameId game);
  Future<void> reset();
}

final scoreRepositoryProvider = Provider<ScoreRepositoryBase>((ref) {
  final storage = ref.watch(storageServiceProvider.future);
  return ScoreRepository(ref, storage);
});

final scoreListProvider = FutureProvider<List<ScoreEntry>>((ref) async {
  final repo = ref.watch(scoreRepositoryProvider);
  return repo.getScores();
});

class ScoreRepository implements ScoreRepositoryBase {
  ScoreRepository(this._ref, this._storageFuture);

  final Ref _ref;
  final Future<StorageService> _storageFuture;

  @override
  Future<List<ScoreEntry>> getScores() async {
    final storage = await _storageFuture;
    return storage.readScores();
  }

  @override
  Future<void> addScore(ScoreEntry entry) async {
    final storage = await _storageFuture;
    final scores = storage.readScores();
    scores.add(entry);
    await storage.saveScores(scores);
    _ref.invalidate(scoreListProvider);
  }

  @override
  Future<ScoreEntry?> lastScoreFor(GameId game) async {
    final scores = await getScores();
    for (final score in scores.reversed) {
      if (score.gameId == game) {
        return score;
      }
    }
    return null;
  }

  @override
  Future<void> reset() async {
    final storage = await _storageFuture;
    await storage.saveScores([]);
    _ref.invalidate(scoreListProvider);
  }
}
