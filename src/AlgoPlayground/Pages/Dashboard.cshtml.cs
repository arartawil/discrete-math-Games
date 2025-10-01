using AlgoPlayground.Domain;
using AlgoPlayground.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AlgoPlayground.Pages;

public class DashboardModel : PageModel
{
    private readonly IProfileService _profileService;
    private readonly IScoreService _scoreService;

    public DashboardModel(IProfileService profileService, IScoreService scoreService)
    {
        _profileService = profileService;
        _scoreService = scoreService;
    }

    public UserProfile? Profile { get; private set; }
    public List<GameCardViewModel> GameCards { get; } = new();

    public async Task<IActionResult> OnGetAsync()
    {
        Profile = await _profileService.GetActiveProfileAsync();
        if (Profile == null)
        {
            return RedirectToPage("/Index");
        }

        var scores = await _scoreService.GetScoresAsync(Profile.Id, new ScoreFilter(null));
        foreach (var game in Enum.GetValues<GameId>())
        {
            var lastScore = scores.FirstOrDefault(s => s.GameId == game);
            GameCards.Add(new GameCardViewModel(game, lastScore));
        }

        return Page();
    }

    public record GameCardViewModel
    {
        public GameCardViewModel(GameId gameId, ScoreEntry? lastScore)
        {
            GameId = gameId;
            LastScore = lastScore;
            Title = gameId switch
            {
                GameId.MazeRunner => "Maze Runner – Graph Theory",
                GameId.TowerLogic => "Tower Defense – Logic Gates",
                GameId.MatchingPairs => "Matching Pairs – Relations & Functions",
                GameId.PuzzleSolver => "Puzzle Solver – Combinatorics",
                _ => gameId.ToString()
            };
            Description = gameId switch
            {
                GameId.MazeRunner => "Navigate mazes and compare your route with optimal BFS paths.",
                GameId.TowerLogic => "Place logic gates to stop enemies with correct truth values.",
                GameId.MatchingPairs => "Match domain and codomain pairs while respecting function rules.",
                GameId.PuzzleSolver => "Solve sliding puzzles with combinatorial reasoning.",
                _ => string.Empty
            };
            Page = gameId switch
            {
                GameId.MazeRunner => "/Game/MazeRunner/Index",
                GameId.TowerLogic => "/Game/TowerLogic/Index",
                GameId.MatchingPairs => "/Game/MatchingPairs/Index",
                GameId.PuzzleSolver => "/Game/PuzzleSolver/Index",
                _ => "/Dashboard"
            };
        }

        public GameId GameId { get; }
        public ScoreEntry? LastScore { get; }
        public string Title { get; }
        public string Description { get; }
        public string Page { get; }
    }
}
