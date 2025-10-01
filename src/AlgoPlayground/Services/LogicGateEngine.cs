namespace AlgoPlayground.Services;

public enum LogicGateType
{
    And,
    Or,
    Xor,
    NotA,
    NotB
}

public class LogicGateEngine
{
    public bool EvaluateGate(LogicGateType gate, bool a, bool b)
    {
        return gate switch
        {
            LogicGateType.And => a && b,
            LogicGateType.Or => a || b,
            LogicGateType.Xor => a ^ b,
            LogicGateType.NotA => !a,
            LogicGateType.NotB => !b,
            _ => false
        };
    }

    public bool EvaluateTarget(string expression, bool a, bool b)
    {
        return expression.Trim().ToUpperInvariant() switch
        {
            "A AND B" => a && b,
            "A OR B" => a || b,
            "A XOR B" => a ^ b,
            "A NAND B" => !(a && b),
            "A NOR B" => !(a || b),
            "A XNOR B" => !(a ^ b),
            "NOT A" => !a,
            "NOT B" => !b,
            _ => false
        };
    }
}
