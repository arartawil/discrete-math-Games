using AlgoPlayground.Services;
using Xunit;

namespace AlgoPlayground.Tests;

public class LogicGateEngineTests
{
    private readonly LogicGateEngine _engine = new();

    [Theory]
    [InlineData(LogicGateType.And, false, false, false)]
    [InlineData(LogicGateType.And, true, true, true)]
    [InlineData(LogicGateType.Or, false, true, true)]
    [InlineData(LogicGateType.Xor, true, true, false)]
    [InlineData(LogicGateType.NotA, true, false)]
    [InlineData(LogicGateType.NotB, false, true)]
    public void EvaluateGateReturnsExpected(LogicGateType gate, bool a, bool b, bool expected)
    {
        var result = _engine.EvaluateGate(gate, a, b);
        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData("A AND B", true, true, true)]
    [InlineData("A OR B", false, true, true)]
    [InlineData("A XOR B", true, true, false)]
    [InlineData("A NAND B", true, true, false)]
    [InlineData("A NOR B", false, false, true)]
    public void EvaluateTargetParsesExpressions(string expression, bool a, bool b, bool expected)
    {
        var result = _engine.EvaluateTarget(expression, a, b);
        Assert.Equal(expected, result);
    }
}
