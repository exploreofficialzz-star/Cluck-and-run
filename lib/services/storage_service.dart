// lib/services/storage_service.dart
// Handles all local persistence via SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── High Score ──────────────────────────────────────────────────────────────
  static int get highScore => _prefs?.getInt(kPrefHighScore) ?? 0;

  static Future<bool> saveHighScore(int score) async {
    if (score > highScore) {
      await _prefs?.setInt(kPrefHighScore, score);
      return true; // new record
    }
    return false;
  }

  // ── Coins ────────────────────────────────────────────────────────────────────
  static int get totalCoins => _prefs?.getInt(kPrefTotalCoins) ?? 0;

  static Future<void> addCoins(int amount) async {
    await _prefs?.setInt(kPrefTotalCoins, totalCoins + amount);
  }

  // ── Run stats ────────────────────────────────────────────────────────────────
  static int get totalRuns => _prefs?.getInt(kPrefTotalRuns) ?? 0;

  static Future<void> incrementRuns() async {
    await _prefs?.setInt(kPrefTotalRuns, totalRuns + 1);
  }

  // ── Streak ───────────────────────────────────────────────────────────────────
  static int get streakDays => _prefs?.getInt(kPrefStreakDays) ?? 0;

  static Future<void> updateStreak() async {
    final lastPlayed = _prefs?.getString(kPrefLastPlayedDate);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastPlayed == null) {
      await _prefs?.setInt(kPrefStreakDays, 1);
    } else {
      final last = DateTime.parse(lastPlayed);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        await _prefs?.setInt(kPrefStreakDays, streakDays + 1);
      } else if (diff > 1) {
        await _prefs?.setInt(kPrefStreakDays, 1); // reset streak
      }
    }
    await _prefs?.setString(kPrefLastPlayedDate, todayStr);
  }

  // ── Settings ─────────────────────────────────────────────────────────────────
  static bool get soundEnabled  => _prefs?.getBool(kPrefSoundEnabled)  ?? true;
  static bool get notifEnabled  => _prefs?.getBool(kPrefNotifEnabled)  ?? true;
  static bool get onboardingDone => _prefs?.getBool(kPrefOnboardingDone) ?? false;

  static Future<void> setSoundEnabled(bool v)   async => _prefs?.setBool(kPrefSoundEnabled,   v);
  static Future<void> setNotifEnabled(bool v)   async => _prefs?.setBool(kPrefNotifEnabled,   v);
  static Future<void> setOnboardingDone()        async => _prefs?.setBool(kPrefOnboardingDone, true);
}
