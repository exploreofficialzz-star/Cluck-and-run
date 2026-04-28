// lib/utils/constants.dart
import 'package:flutter/material.dart';

const kAppName   = 'Cluck & Run';
const kVersion   = '1.0.0';

// ── Lane system (vertical Subway-Surfers-style runner) ───────────────────────
const int    kLaneCount      = 3;
const List<double> kLaneFracs = [0.18, 0.50, 0.82];

// ── Physics ──────────────────────────────────────────────────────────────────
const double kGravity         = 2200.0;
const double kJumpVelocity    = -820.0;
const double kInitialSpeed    = 420.0;
const double kMaxSpeed        = 1400.0;
const double kSpeedGrowth     = 0.018;
const double kLaneSwitchSpeed = 0.14;

// ── Farmer ───────────────────────────────────────────────────────────────────
const double kFarmerInitScale  = 0.22;
const double kFarmerMaxScale   = 0.72;
const double kFarmerGrowthRate = 0.000028;

// ── Spawn ─────────────────────────────────────────────────────────────────────
const double kObsMinInterval  = 0.85;
const double kObsMaxInterval  = 2.20;
const double kCoinInterval    = 0.55;
const double kBirdInterval    = 4.50;
const int    kInvincibleMs    = 2400;
const int    kBonusBirdCoins  = 10;

// ── AdMob test IDs ────────────────────────────────────────────────────────────
const kBannerIdAndroid    = 'ca-app-pub-3940256099942544/6300978111';
const kBannerIdIOS        = 'ca-app-pub-3940256099942544/2934735716';
const kInterIdAndroid     = 'ca-app-pub-3940256099942544/1033173712';
const kInterIdIOS         = 'ca-app-pub-3940256099942544/4411468910';
const kRewardedIdAndroid  = 'ca-app-pub-3940256099942544/5224354917';
const kRewardedIdIOS      = 'ca-app-pub-3940256099942544/1712485313';
const kInterEveryNDeaths  = 3;

// ── Notification ─────────────────────────────────────────────────────────────
const kNotifChannelId   = 'cluck_run_reminders';
const kNotifChannelName = 'Daily Run Reminders';
const kNotifChannelDesc = 'Daily reminders to beat your high score!';
const kNotifDailyId     = 1001;
const kNotifStreakId    = 1002;

// ── Storage keys ─────────────────────────────────────────────────────────────
const kPrefHighScore    = 'high_score';
const kPrefTotalCoins   = 'total_coins';
const kPrefTotalRuns    = 'total_runs';
const kPrefLastPlayed   = 'last_played_date';
const kPrefStreakDays   = 'streak_days';
const kPrefSoundEnabled = 'sound_enabled';
const kPrefNotifEnabled = 'notif_enabled';
const kPrefOnboarded    = 'onboarding_done';

// ── Brand colours ─────────────────────────────────────────────────────────────
const kColYolk  = Color(0xFFFFD600);
const kColBlaze = Color(0xFFFF6D00);
const kColRed   = Color(0xFFE53935);
const kColSky   = Color(0xFF4FC3F7);
const kColGreen = Color(0xFF43A047);
const kColDark  = Color(0xFF0D1117);
const kColSoil  = Color(0xFF3E2723);
const kColCream = Color(0xFFFFF8E7);
const kColGold  = Color(0xFFFFB300);

// ── Assets ───────────────────────────────────────────────────────────────────
const kImgChicken   = 'assets/images/chicken_sprite.png';
const kImgFarmer    = 'assets/images/farmer_sprite.png';
const kImgFarmBg    = 'assets/images/farm_bg_tile.jpg';
const kImgCoin      = 'assets/images/coin.png';
const kImgBonusBird = 'assets/images/bonus_bird.png';

const kSndCockCrow  = 'audio/cock_crow.mp3';
const kSndCluck     = 'audio/cluck.mp3';
const kSndJump      = 'audio/jump.mp3';
const kSndCoin      = 'audio/coin.mp3';
const kSndDie       = 'audio/die.mp3';
const kSndRevive    = 'audio/revive.mp3';
const kSndBonus     = 'audio/bonus.mp3';
const kSndBgMusic   = 'audio/bg_music.mp3';
