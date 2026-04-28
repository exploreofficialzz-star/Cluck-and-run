# 🐔 Cluck & Run — Flutter Endless Runner

Vertical lane-based endless runner (Subway Surfers style).
The chicken runs toward you — swipe lanes, jump obstacles, escape the angry farmer!

## Stack
- Flutter 3.22 (Portrait, vertical runner)
- Canvas + real photo/cartoon assets
- Google AdMob (Banner + Interstitial + Rewarded)
- flutter_local_notifications (daily reminders, device default sound)
- audioplayers (cock crow, cluck, jump, coin, die, revive, bg music)
- shared_preferences (high score, coins, streak)

## Quick Start
```bash
flutter pub get
flutter run
```

## Build
```bash
# APK
flutter build apk --release

# Play Store bundle
flutter build appbundle --release

# iOS
flutter build ios --release --no-codesign
```

## Replace AdMob IDs (before release)
Edit `lib/utils/constants.dart` — replace all `kBannerId*`, `kInterId*`, `kRewardedId*`
and update `android/app/src/main/AndroidManifest.xml` GAD APPLICATION_ID.

## GitHub CI/CD
Push to `main` → auto builds signed APK + AAB.
Tag `v1.0.0` → creates GitHub Release with download links.

Required secrets: KEY_JKS, KEY_ALIAS, KEY_PASSWORD, STORE_PASSWORD

## Controls
| Action    | Touch         | Description              |
|-----------|---------------|--------------------------|
| Jump      | Tap / Swipe ↑ | Hop over hay bales       |
| Slide     | Swipe ↓       | Duck under fences        |
| Lane Left | Swipe ←       | Move to left lane        |
| Lane Right| Swipe →       | Move to right lane       |

## Monetisation Flow
Cold Start → Splash → Menu (Banner visible)
Play → Die → Game Over:
  ├─ Rewarded: "Watch Ad → Keep Running" (1 revive/run)
  ├─ Rewarded: "Watch Ad → 2× Coins"
  └─ Interstitial: fires every 3rd death (no revive taken)

Built by ChasTech Group
