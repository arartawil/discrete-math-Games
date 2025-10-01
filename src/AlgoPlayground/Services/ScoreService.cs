using System.Globalization;
using System.Text;
using AlgoPlayground.Data;
using AlgoPlayground.Domain;
using Microsoft.EntityFrameworkCore;

namespace AlgoPlayground.Services;

public class ScoreService : IScoreService
{
    private readonly AppDbContext _context;

    public ScoreService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ScoreEntry> AddScoreAsync(int profileId, GameId gameId, int level, int points, int durationSec, CancellationToken cancellationToken = default)
    {
        var score = new ScoreEntry
        {
            UserProfileId = profileId,
            GameId = gameId,
            Level = level,
            Points = points,
            DurationSec = durationSec,
            Timestamp = DateTime.UtcNow
        };

        _context.ScoreEntries.Add(score);
        await _context.SaveChangesAsync(cancellationToken);
        return score;
    }

    public async Task<IReadOnlyList<ScoreEntry>> GetScoresAsync(int profileId, ScoreFilter filter, CancellationToken cancellationToken = default)
    {
        var query = _context.ScoreEntries
            .Where(s => s.UserProfileId == profileId)
            .OrderByDescending(s => s.Timestamp)
            .AsQueryable();

        if (filter.GameId.HasValue)
        {
            query = query.Where(s => s.GameId == filter.GameId.Value);
        }

        return await query.ToListAsync(cancellationToken);
    }

    public async Task<string> ExportCsvAsync(int profileId, ScoreFilter filter, CancellationToken cancellationToken = default)
    {
        var scores = await GetScoresAsync(profileId, filter, cancellationToken);
        var builder = new StringBuilder();
        builder.AppendLine("Game,Level,Points,DurationSec,Timestamp");
        foreach (var score in scores)
        {
            builder.AppendLine(string.Join(',',
                score.GameId,
                score.Level,
                score.Points,
                score.DurationSec,
                score.Timestamp.ToString("o", CultureInfo.InvariantCulture)));
        }

        return builder.ToString();
    }
}
