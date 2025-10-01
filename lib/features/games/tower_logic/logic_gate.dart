enum LogicGateType { and, or, xor, notA, notB }

typedef LogicInputs = ({bool a, bool b});

typedef LogicEnemyTarget = bool Function(bool a, bool b);

bool evaluateGate(LogicGateType type, LogicInputs inputs) {
  switch (type) {
    case LogicGateType.and:
      return inputs.a && inputs.b;
    case LogicGateType.or:
      return inputs.a || inputs.b;
    case LogicGateType.xor:
      return inputs.a ^ inputs.b;
    case LogicGateType.notA:
      return !inputs.a;
    case LogicGateType.notB:
      return !inputs.b;
  }
}

String gateLabel(LogicGateType type) {
  switch (type) {
    case LogicGateType.and:
      return 'AND';
    case LogicGateType.or:
      return 'OR';
    case LogicGateType.xor:
      return 'XOR';
    case LogicGateType.notA:
      return 'NOT A';
    case LogicGateType.notB:
      return 'NOT B';
  }
}

LogicEnemyTarget targetForLabel(String label) {
  switch (label) {
    case 'A AND B':
      return (a, b) => a && b;
    case 'A OR B':
      return (a, b) => a || b;
    case 'A XOR B':
      return (a, b) => a ^ b;
    case 'NOT A':
      return (a, b) => !a;
    case 'NOT B':
      return (a, b) => !b;
    default:
      return (a, b) => a ^ b;
  }
}

String descriptionForGate(LogicGateType type) {
  switch (type) {
    case LogicGateType.and:
      return 'Outputs true when both inputs are true.';
    case LogicGateType.or:
      return 'Outputs true when at least one input is true.';
    case LogicGateType.xor:
      return 'Outputs true when exactly one input is true.';
    case LogicGateType.notA:
      return 'Flips the A input.';
    case LogicGateType.notB:
      return 'Flips the B input.';
  }
}

List<String> logicTargets = [
  'A AND B',
  'A OR B',
  'A XOR B',
  'NOT A',
  'NOT B',
];
