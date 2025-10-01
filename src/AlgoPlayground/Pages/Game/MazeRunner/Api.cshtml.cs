using AlgoPlayground.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AlgoPlayground.Pages.Game.MazeRunner;

public class ApiModel : PageModel
{
    private readonly GraphBfs _graphBfs;

    public ApiModel(GraphBfs graphBfs)
    {
        _graphBfs = graphBfs;
    }

    public IActionResult OnPostComputeBfs([FromBody] MazeRequest request)
    {
        if (request.Grid == null || request.Grid.Length == 0)
        {
            return BadRequest("Grid is required");
        }

        var rows = request.Grid.Length;
        var cols = request.Grid[0].Length;
        var grid = new bool[rows, cols];
        for (var r = 0; r < rows; r++)
        {
            if (request.Grid[r].Length != cols)
            {
                return BadRequest("Invalid grid row length");
            }

            for (var c = 0; c < cols; c++)
            {
                grid[r, c] = request.Grid[r][c] != 0;
            }
        }

        var result = _graphBfs.Compute(grid, (request.Start.Row, request.Start.Col), (request.Goal.Row, request.Goal.Col));
        return new JsonResult(new
        {
            optimal = result.Distance,
            nodesExpanded = result.NodesExpanded,
            path = result.Path.Select(p => new { row = p.Row, col = p.Col })
        });
    }

    public record MazeRequest
    {
        public int[][] Grid { get; init; } = Array.Empty<int[]>();
        public MazePosition Start { get; init; } = new();
        public MazePosition Goal { get; init; } = new();
    }

    public record struct MazePosition
    {
        public int Row { get; init; }
        public int Col { get; init; }
    }
}
