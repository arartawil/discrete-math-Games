using AlgoPlayground.Services;
using Xunit;

namespace AlgoPlayground.Tests;

public class PuzzleSolverTests
{
    private readonly PuzzleSolver _solver = new();

    [Fact]
    public void CountsInversionsCorrectly()
    {
        var tiles = new[] { 1, 2, 3, 4, 5, 6, 7, 8, 0 };
        Assert.Equal(0, _solver.CountInversions(tiles));
    }

    [Fact]
    public void DetectsSolvablePuzzle()
    {
        var tiles = new[] { 1, 2, 3, 4, 5, 6, 0, 7, 8 };
        Assert.True(_solver.IsSolvable(tiles, 3));
    }

    [Fact]
    public void ManhattanDistanceMatchesExpected()
    {
        var tiles = new[] { 8, 1, 3, 4, 0, 2, 7, 6, 5 };
        var distance = _solver.ManhattanDistance(tiles, 3);
        Assert.Equal(10, distance);
    }
}
