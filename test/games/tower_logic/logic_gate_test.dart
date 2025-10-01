import 'package:flutter_test/flutter_test.dart';

import 'package:algo_playground/features/games/tower_logic/logic_gate.dart';

void main() {
  test('Logic gates evaluate correct truth tables', () {
    final inputs = [
      (a: false, b: false),
      (a: false, b: true),
      (a: true, b: false),
      (a: true, b: true),
    ];
    for (final input in inputs) {
      expect(evaluateGate(LogicGateType.and, input), input.a && input.b);
      expect(evaluateGate(LogicGateType.or, input), input.a || input.b);
      expect(evaluateGate(LogicGateType.xor, input), input.a ^ input.b);
      expect(evaluateGate(LogicGateType.notA, input), !input.a);
      expect(evaluateGate(LogicGateType.notB, input), !input.b);
    }
  });
}
