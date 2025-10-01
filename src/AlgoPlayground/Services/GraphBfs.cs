namespace AlgoPlayground.Services;

public record struct MazeBfsResult(int Distance, int NodesExpanded, IReadOnlyList<(int Row, int Col)> Path);

public class GraphBfs
{
    private static readonly (int dRow, int dCol)[] Directions =
    {
        (-1, 0), (1, 0), (0, -1), (0, 1)
    };

    public MazeBfsResult Compute(bool[,] grid, (int Row, int Col) start, (int Row, int Col) goal)
    {
        var rows = grid.GetLength(0);
        var cols = grid.GetLength(1);
        var queue = new Queue<(int Row, int Col)>();
        var visited = new bool[rows, cols];
        var parent = new (int Row, int Col)?[rows, cols];
        var distance = new int[rows, cols];

        queue.Enqueue(start);
        visited[start.Row, start.Col] = true;
        distance[start.Row, start.Col] = 0;

        var nodesExpanded = 0;

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            nodesExpanded++;
            if (current == goal)
            {
                break;
            }

            foreach (var (dRow, dCol) in Directions)
            {
                var nextRow = current.Row + dRow;
                var nextCol = current.Col + dCol;
                if (nextRow < 0 || nextCol < 0 || nextRow >= rows || nextCol >= cols)
                {
                    continue;
                }

                if (!grid[nextRow, nextCol] || visited[nextRow, nextCol])
                {
                    continue;
                }

                visited[nextRow, nextCol] = true;
                parent[nextRow, nextCol] = current;
                distance[nextRow, nextCol] = distance[current.Row, current.Col] + 1;
                queue.Enqueue((nextRow, nextCol));
            }
        }

        if (!visited[goal.Row, goal.Col])
        {
            return new MazeBfsResult(-1, nodesExpanded, Array.Empty<(int, int)>());
        }

        var path = new List<(int, int)>();
        var node = goal;
        while (true)
        {
            path.Add(node);
            if (node == start)
            {
                break;
            }

            var parentNode = parent[node.Row, node.Col];
            if (parentNode == null)
            {
                break;
            }

            node = parentNode.Value;
        }

        path.Reverse();

        return new MazeBfsResult(distance[goal.Row, goal.Col], nodesExpanded, path);
    }
}
