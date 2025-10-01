using System.Collections.Generic;
using AlgoPlayground.Services;
using Xunit;

namespace AlgoPlayground.Tests;

public class RelationFunctionValidatorTests
{
    private readonly RelationFunctionValidator _validator = new();

    [Fact]
    public void AllowsSingleMappingPerDomainInFunction()
    {
        var pairs = new List<(string, string)>
        {
            ("d1", "c1"),
            ("d2", "c2"),
        };

        Assert.True(_validator.IsValidFunction(pairs));
    }

    [Fact]
    public void DetectsInvalidFunction()
    {
        var pairs = new List<(string, string)>
        {
            ("d1", "c1"),
            ("d1", "c2"),
        };

        Assert.False(_validator.IsValidFunction(pairs));
    }

    [Fact]
    public void DetectsSurjectiveMapping()
    {
        var pairs = new List<(string, string)>
        {
            ("d1", "c1"),
            ("d2", "c2"),
        };
        var codomain = new[] { "c1", "c2" };
        Assert.True(_validator.IsSurjective(pairs, codomain));
    }
}
