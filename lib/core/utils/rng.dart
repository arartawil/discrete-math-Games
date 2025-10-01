import 'dart:math';

class SeededRandom {
  SeededRandom(int seed) : _random = Random(seed);

  final Random _random;

  int nextInt(int max) => _random.nextInt(max);

  double nextDouble() => _random.nextDouble();

  bool nextBool() => _random.nextBool();
}
