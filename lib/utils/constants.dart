// lib/utils/constants.dart
// ─────────────────────────────────────────────────────────────────────────────
// All game-wide constants, AdMob IDs, notification channel IDs, and colours.
// Replace kAdMob* with your real IDs before releasing to production.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── App ─────────────────────────────────────────────────────────────────────
const kAppName = 'Cluck & Run';
const kVersion  = '1.0.0';

// ── Game world ───────────────────────────────────────────────────────────────
const double kGroundY        = 0.80; // fraction of screen height
const double kPlayerXFrac    = 0.22; // fraction of screen width
const double kGravity        = 1800.0;  // px/s²
const double kJumpVelocity   = -780.0;  // px/s  (negative = up)
const double kInitialSpeed   = 340.0;   // px/s
const double kMaxSpeed       = 920.0;   // px/s
const double kSpeedIncrement = 0.012;   // per point scored
const double kFarmerInitGap  = 320.0;   // px behind player
const double kFarmerMinGap   = 64.0;
const double kFarmerCatchUp  = 0.014;   // gap shrink per px score
const int    kInvincibleMs   = 2200;    // ms after revive
const int    kSlideFrames    = 38;      // animation frames for slide

// ── Obstacle spawn ───────────────────────────────────────────────────────────
const double kObsMinIntervalSec = 0.80;
const double kObsMaxIntervalSec = 2.40;
const double kCoinIntervalSec   = 1.10;

// ── Monetisation ─────────────────────────────────────────────────────────────
// Replace with live IDs from https://apps.admob.com
const kAdMobAppIdAndroid  = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
const kAdMobAppIdIOS      = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

// Test IDs (safe to use during development)
const kBannerIdAndroid       = 'ca-app-pub-3940256099942544/6300978111';
const kBannerIdIOS           = 'ca-app-pub-3940256099942544/2934735716';
const kInterstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
const kInterstitialIdIOS     = 'ca-app-pub-3940256099942544/4411468910';
const kRewardedIdAndroid     = 'ca-app-pub-3940256099942544/5224354917';
const kRewardedIdIOS         = 'ca-app-pub-3940256099942544/1712485313';

const kInterstitialEveryNDeaths = 3;

// ── Notification channels ─────────────────────────────────────────────────────
const kNotifChannelId   = 'cluck_run_reminders';
const kNotifChannelName = 'Daily Run Reminders';
const kNotifChannelDesc = 'Reminds you to come back and beat your high score!';
const kNotifDailyId     = 1001;
const kNotifStreakId    = 1002;

// ── Storage keys ─────────────────────────────────────────────────────────────
const kPrefHighScore       = 'high_score';
const kPrefTotalCoins      = 'total_coins';
const kPrefTotalRuns       = 'total_runs';
const kPrefLastPlayedDate  = 'last_played_date';
const kPrefStreakDays      = 'streak_days';
const kPrefSoundEnabled    = 'sound_enabled';
const kPrefNotifEnabled    = 'notif_enabled';
const kPrefOnboardingDone  = 'onboarding_done';

// ── Brand colours ─────────────────────────────────────────────────────────────
const kColYolk    = Color(0xFFFFD600);
const kColBlaze   = Color(0xFFFF6D00);
const kColRed     = Color(0xFFE53935);
const kColSky     = Color(0xFF4FC3F7);
const kColGreen   = Color(0xFF43A047);
const kColDark    = Color(0xFF0D1117);
const kColSoil    = Color(0xFF3E2723);
const kColCream   = Color(0xFFFFF8E7);
const kColGold    = Color(0xFFFFB300);

// ── Typography ───────────────────────────────────────────────────────────────
const kFontDisplay = 'FredokaOne'; // loaded via Google Fonts fallback

// ── Animation ────────────────────────────────────────────────────────────────
const kRunFrameRate = 10.0; // frames per second for sprite cycle
const kRunFrameCount = 8;
