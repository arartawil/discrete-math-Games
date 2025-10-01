using System.Collections.Generic;

namespace AlgoPlayground.Services;

public class PuzzleSolver
{
    public int CountInversions(IReadOnlyList<int> tiles)
    {
        var count = 0;
        for (var i = 0; i < tiles.Count; i++)
        {
            if (tiles[i] == 0)
            {
                continue;
            }

            for (var j = i + 1; j < tiles.Count; j++)
            {
                if (tiles[j] == 0)
                {
                    continue;
                }

                if (tiles[i] > tiles[j])
                {
                    count++;
                }
            }
        }

        return count;
    }

    public int ManhattanDistance(IReadOnlyList<int> tiles, int dimension)
    {
        var distance = 0;
        for (var index = 0; index < tiles.Count; index++)
        {
            var value = tiles[index];
            if (value == 0)
            {
                continue;
            }

            var currentRow = index / dimension;
            var currentCol = index % dimension;
            var targetRow = (value - 1) / dimension;
            var targetCol = (value - 1) % dimension;
            distance += Math.Abs(currentRow - targetRow) + Math.Abs(currentCol - targetCol);
        }

        return distance;
    }

    public bool IsSolvable(IReadOnlyList<int> tiles, int dimension)
    {
        var inversions = CountInversions(tiles);
        if (dimension % 2 == 1)
        {
            return inversions % 2 == 0;
        }

        var blankIndex = 0;
        for (var i = 0; i < tiles.Count; i++)
        {
            if (tiles[i] == 0)
            {
                blankIndex = i;
                break;
            }
        }

        var rowFromBottom = dimension - (blankIndex / dimension);
        if (rowFromBottom % 2 == 0)
        {
            return inversions % 2 == 1;
        }

        return inversions % 2 == 0;
    }
}
