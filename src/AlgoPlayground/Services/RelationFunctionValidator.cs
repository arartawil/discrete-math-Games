namespace AlgoPlayground.Services;

public class RelationFunctionValidator
{
    public bool IsValidFunction(IEnumerable<(string Domain, string Codomain)> pairs)
    {
        var map = new Dictionary<string, string>();
        foreach (var (domain, codomain) in pairs)
        {
            if (map.TryGetValue(domain, out var existing))
            {
                if (!string.Equals(existing, codomain, StringComparison.Ordinal))
                {
                    return false;
                }
            }
            else
            {
                map[domain] = codomain;
            }
        }

        return true;
    }

    public bool IsInjective(IEnumerable<(string Domain, string Codomain)> pairs)
    {
        var seen = new HashSet<string>();
        foreach (var (_, codomain) in pairs)
        {
            if (!seen.Add(codomain))
            {
                return false;
            }
        }

        return true;
    }

    public bool IsSurjective(IEnumerable<(string Domain, string Codomain)> pairs, IEnumerable<string> codomainSet)
    {
        var mapped = pairs.Select(p => p.Codomain).ToHashSet(StringComparer.Ordinal);
        return codomainSet.All(mapped.Contains);
    }
}
