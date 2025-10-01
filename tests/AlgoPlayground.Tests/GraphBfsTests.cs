using System.Linq;
using AlgoPlayground.Services;
using Xunit;

namespace AlgoPlayground.Tests;

public class GraphBfsTests
{
    [Fact]
    public void FindsShortestPathOnOpenGrid()
    {
        var grid = new bool[5, 5];
        for (var r = 0; r < 5; r++)
        {
            for (var c = 0; c < 5; c++)
            {
                grid[r, c] = true;
            }
        }

        var bfs = new GraphBfs();
        var result = bfs.Compute(grid, (0, 0), (4, 4));

        Assert.Equal(8, result.Distance);
        Assert.True(result.NodesExpanded > 0);
        Assert.Equal((0, 0), result.Path.First());
        Assert.Equal((4, 4), result.Path.Last());
    }
}
