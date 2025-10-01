import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/score_entry.dart';
import '../models/user_profile.dart';

class StorageService {
  StorageService(this._prefs);

  static const _profileKey = 'profile';
  static const _scoresKey = 'scores';

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  UserProfile? readProfile() {
    final raw = _prefs.getString(_profileKey);
    return UserProfile.fromJsonString(raw);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, profile.toJsonString());
  }

  List<ScoreEntry> readScores() {
    final raw = _prefs.getString(_scoresKey);
    return ScoreEntry.fromJsonString(raw);
  }

  Future<void> saveScores(List<ScoreEntry> scores) async {
    await _prefs.setString(_scoresKey, ScoreEntry.toJsonString(scores));
  }

  Future<void> clearAll() async {
    await _prefs.remove(_profileKey);
    await _prefs.remove(_scoresKey);
  }

  Map<String, dynamic> dumpAll() {
    return {
      'profile': jsonDecode(_prefs.getString(_profileKey) ?? '{}'),
      'scores': jsonDecode(_prefs.getString(_scoresKey) ?? '[]'),
    };
  }
}
