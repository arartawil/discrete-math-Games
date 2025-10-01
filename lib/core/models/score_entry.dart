import 'dart:convert';

import 'game_id.dart';

class ScoreEntry {
  const ScoreEntry({
    required this.gameId,
    required this.level,
    required this.points,
    required this.durationSec,
    required this.timestamp,
  });

  final GameId gameId;
  final int level;
  final int points;
  final int durationSec;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'gameId': gameId.name,
        'level': level,
        'points': points,
        'durationSec': durationSec,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      gameId: GameIdX.fromJson(json['gameId'] as String? ?? GameId.mazeRunner.name),
      level: json['level'] as int? ?? 1,
      points: json['points'] as int? ?? 0,
      durationSec: json['durationSec'] as int? ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static List<ScoreEntry> fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final dynamic data = jsonDecode(jsonString);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ScoreEntry.fromJson)
          .toList();
    }
    return [];
  }

  static String toJsonString(List<ScoreEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }
}
