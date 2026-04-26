// lib/services/ad_service.dart
// Central AdMob manager: Banner, Interstitial, Rewarded Video.
// All ads are pre-loaded in the background for zero-lag display.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

class AdService {
  // ── Singleton ────────────────────────────────────────────────────────────────
  AdService._();
  static final instance = AdService._();

  // ── Internal state ────────────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  RewardedAd?     _rewardedAd;
  BannerAd?       _bannerAd;
  bool _interstitialReady = false;
  bool _rewardedReady     = false;
  bool _bannerReady       = false;
  int  _deathCount        = 0;

  // ── IDs (platform-aware) ─────────────────────────────────────────────────────
  String get _bannerId        => Platform.isIOS ? kBannerIdIOS        : kBannerIdAndroid;
  String get _interstitialId  => Platform.isIOS ? kInterstitialIdIOS  : kInterstitialIdAndroid;
  String get _rewardedId      => Platform.isIOS ? kRewardedIdIOS      : kRewardedIdAndroid;

  // ── Init ──────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await MobileAds.instance.initialize();
    // Load all ad types at startup for instant display
    _loadInterstitial();
    _loadRewarded();
    _loadBanner();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BANNER
  // ─────────────────────────────────────────────────────────────────────────────
  BannerAd? get bannerAd => _bannerReady ? _bannerAd : null;

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerReady = true;
          debugPrint('[Ads] Banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerReady = false;
          debugPrint('[Ads] Banner failed: $error — retrying in 60s');
          Future.delayed(const Duration(seconds: 60), _loadBanner);
        },
      ),
    )..load();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERSTITIAL
  // ─────────────────────────────────────────────────────────────────────────────
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          debugPrint('[Ads] Interstitial ready');
          ad.setImmersiveMode(true);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              _interstitialReady = false;
              _loadInterstitial(); // pre-load next
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              a.dispose();
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialReady = false;
          debugPrint('[Ads] Interstitial failed: $error — retrying in 30s');
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Call on every player death. Shows interstitial every Nth death.
  void onPlayerDied() {
    _deathCount++;
    if (_deathCount % kInterstitialEveryNDeaths == 0 && _interstitialReady) {
      _interstitialAd?.show();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REWARDED
  // ─────────────────────────────────────────────────────────────────────────────
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          debugPrint('[Ads] Rewarded ready');
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _rewardedReady = false;
          debugPrint('[Ads] Rewarded failed: $error — retrying in 30s');
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedReady;

  /// Show rewarded ad. [onEarned] is called with the reward value when the user
  /// completes the ad. [onFailed] is called if the ad can't be shown.
  void showRewarded({
    required VoidCallback onEarned,
    required VoidCallback onFailed,
  }) {
    if (!_rewardedReady || _rewardedAd == null) {
      onFailed();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedReady = false;
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedReady = false;
        _loadRewarded();
        onFailed();
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) => onEarned(),
    );
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────────
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
