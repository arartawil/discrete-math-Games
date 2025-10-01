import 'dart:async';

import 'package:flutter/foundation.dart';

class TimerService {
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isRunning = ValueNotifier(false);

  Timer? _timer;

  void start() {
    if (isRunning.value) {
      return;
    }
    isRunning.value = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed.value += const Duration(seconds: 1);
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    isRunning.value = false;
  }

  void reset() {
    pause();
    elapsed.value = Duration.zero;
  }

  void dispose() {
    pause();
    elapsed.dispose();
    isRunning.dispose();
  }
}
