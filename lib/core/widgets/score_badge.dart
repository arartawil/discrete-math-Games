import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    super.key,
    required this.points,
    required this.durationSec,
  });

  final int points;
  final int durationSec;

  @override
  Widget build(BuildContext context) {
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, size: 18),
          const SizedBox(width: 4),
          Text('$points pts'),
          const SizedBox(width: 8),
          const Icon(Icons.timer, size: 18),
          const SizedBox(width: 4),
          Text(timeText),
        ],
      ),
    );
  }
}
