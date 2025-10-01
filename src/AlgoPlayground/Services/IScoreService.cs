using AlgoPlayground.Domain;

namespace AlgoPlayground.Services;

public record ScoreFilter(GameId? GameId);

public interface IScoreService
{
    Task<ScoreEntry> AddScoreAsync(int profileId, GameId gameId, int level, int points, int durationSec, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ScoreEntry>> GetScoresAsync(int profileId, ScoreFilter filter, CancellationToken cancellationToken = default);
    Task<string> ExportCsvAsync(int profileId, ScoreFilter filter, CancellationToken cancellationToken = default);
}
