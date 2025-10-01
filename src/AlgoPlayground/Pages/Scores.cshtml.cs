using System.Linq;
using AlgoPlayground.Domain;
using AlgoPlayground.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AlgoPlayground.Pages;

public class ScoresModel : PageModel
{
    private readonly IProfileService _profileService;
    private readonly IScoreService _scoreService;

    public ScoresModel(IProfileService profileService, IScoreService scoreService)
    {
        _profileService = profileService;
        _scoreService = scoreService;
        GameOptions = Enum.GetValues<GameId>()
            .Select(g => new Option(g.ToString(), g.ToString()))
            .ToList();
    }

    public UserProfile? Profile { get; private set; }
    public List<Option> GameOptions { get; }
    public List<ScoreEntry> Scores { get; private set; } = new();
    public string? SelectedGame { get; private set; }

    public async Task<IActionResult> OnGetAsync(string? gameId)
    {
        Profile = await _profileService.GetActiveProfileAsync();
        if (Profile == null)
        {
            return RedirectToPage("/Index");
        }

        SelectedGame = gameId;
        var filter = new ScoreFilter(ParseGameId(gameId));
        Scores = (await _scoreService.GetScoresAsync(Profile.Id, filter)).ToList();
        return Page();
    }

    public async Task<IActionResult> OnGetListAsync(string? gameId)
    {
        var profile = await _profileService.GetActiveProfileAsync();
        if (profile == null)
        {
            return Unauthorized();
        }

        var filter = new ScoreFilter(ParseGameId(gameId));
        var results = await _scoreService.GetScoresAsync(profile.Id, filter);
        return new JsonResult(results.Select(r => new
        {
            r.GameId,
            r.Level,
            r.Points,
            r.DurationSec,
            Timestamp = r.Timestamp
        }));
    }

    public async Task<IActionResult> OnPostAddAsync([FromBody] ScoreRequest request)
    {
        var profileId = _profileService.GetActiveProfileId();
        if (profileId == null)
        {
            return Unauthorized();
        }

        if (!Enum.TryParse<GameId>(request.GameId, true, out var gameId))
        {
            return BadRequest("Invalid game id");
        }

        var score = await _scoreService.AddScoreAsync(profileId.Value, gameId, request.Level, request.Points, request.DurationSec);
        return new JsonResult(new { score.Id, score.GameId, score.Level, score.Points, score.DurationSec, score.Timestamp });
    }

    public async Task<IActionResult> OnGetExportAsync(string? gameId)
    {
        var profile = await _profileService.GetActiveProfileAsync();
        if (profile == null)
        {
            return RedirectToPage("/Index");
        }

        var filter = new ScoreFilter(ParseGameId(gameId));
        var csv = await _scoreService.ExportCsvAsync(profile.Id, filter);
        var bytes = System.Text.Encoding.UTF8.GetBytes(csv);
        return File(bytes, "text/csv", $"scores_{DateTime.UtcNow:yyyyMMddHHmmss}.csv");
    }

    private static GameId? ParseGameId(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return Enum.TryParse<GameId>(value, true, out var game) ? game : null;
    }

    public record Option(string Label, string Value);

    public record ScoreRequest
    {
        public string GameId { get; init; } = string.Empty;
        public int Level { get; init; }
        public int Points { get; init; }
        public int DurationSec { get; init; }
    }
}
