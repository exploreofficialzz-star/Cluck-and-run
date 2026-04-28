// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static int  get highScore    => _p?.getInt(kPrefHighScore)    ?? 0;
  static int  get totalCoins   => _p?.getInt(kPrefTotalCoins)   ?? 0;
  static int  get totalRuns    => _p?.getInt(kPrefTotalRuns)    ?? 0;
  static int  get streakDays   => _p?.getInt(kPrefStreakDays)   ?? 0;
  static bool get soundEnabled => _p?.getBool(kPrefSoundEnabled) ?? true;
  static bool get notifEnabled => _p?.getBool(kPrefNotifEnabled) ?? true;

  static Future<bool> saveHighScore(int s) async {
    if (s > highScore) { await _p?.setInt(kPrefHighScore, s); return true; }
    return false;
  }
  static Future<void> addCoins(int n)         async => _p?.setInt(kPrefTotalCoins, totalCoins + n);
  static Future<void> incrementRuns()         async => _p?.setInt(kPrefTotalRuns,  totalRuns  + 1);
  static Future<void> setSoundEnabled(bool v) async => _p?.setBool(kPrefSoundEnabled, v);
  static Future<void> setNotifEnabled(bool v) async => _p?.setBool(kPrefNotifEnabled, v);

  static Future<void> updateStreak() async {
    final last = _p?.getString(kPrefLastPlayed);
    final today = DateTime.now();
    final ts = '${today.year}-${today.month}-${today.day}';
    if (last == null) {
      await _p?.setInt(kPrefStreakDays, 1);
    } else {
      final diff = today.difference(DateTime.parse(last)).inDays;
      if (diff == 1)     await _p?.setInt(kPrefStreakDays, streakDays + 1);
      else if (diff > 1) await _p?.setInt(kPrefStreakDays, 1);
    }
    await _p?.setString(kPrefLastPlayed, ts);
  }

  static Future<void> clearAll() async => _p?.clear();
}
