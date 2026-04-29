// lib/services/ad_service.dart
// Aggressive but professional AdMob integration.
// Strategy: pre-load ads immediately, fire interstitial every 2 deaths,
// always have rewarded ready, banner shown on all non-gameplay screens + gameplay.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

class AdService {
  AdService._();
  static final instance = AdService._();

  InterstitialAd? _inter;
  RewardedAd?     _rewarded;
  BannerAd?       _banner;

  bool _interReady  = false;
  bool _rewardReady = false;
  bool _bannerReady = false;

  int  _deathCount   = 0;
  int  _interFreq    = 2;   // every 2 deaths (aggressive)
  bool _isLoadingInter   = false;
  bool _isLoadingRewarded= false;

  String get _bannerId   => Platform.isIOS ? kBannerIdIOS   : kBannerIdAndroid;
  String get _interId    => Platform.isIOS ? kInterIdIOS    : kInterIdAndroid;
  String get _rewardedId => Platform.isIOS ? kRewardedIdIOS : kRewardedIdAndroid;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    // Load all ad formats simultaneously at startup
    _loadBanner();
    _loadInter();
    _loadRewarded();
    debugPrint('[Ads] AdMob initialised — loading all formats');
  }

  // ── BANNER ─────────────────────────────────────────────────────────────────
  BannerAd? get bannerAd => _bannerReady ? _banner : null;

  void _loadBanner() {
    _banner = BannerAd(
      adUnitId: _bannerId,
      size:     AdSize.banner,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded:       (_) { _bannerReady = true;  debugPrint('[Ads] Banner ready'); },
        onAdFailedToLoad: (ad, e) {
          ad.dispose(); _bannerReady = false;
          debugPrint('[Ads] Banner failed: $e — retrying 45s');
          Future.delayed(const Duration(seconds: 45), _loadBanner);
        },
      ),
    )..load();
  }

  // ── INTERSTITIAL ───────────────────────────────────────────────────────────
  void _loadInter() {
    if (_isLoadingInter) return;
    _isLoadingInter = true;
    InterstitialAd.load(
      adUnitId: _interId,
      request:  const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _inter       = ad;
          _interReady  = true;
          _isLoadingInter = false;
          debugPrint('[Ads] Interstitial ready');
          ad.setImmersiveMode(true);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose(); _interReady = false; _loadInter();
            },
            onAdFailedToShowFullScreenContent: (a, e) {
              a.dispose(); _interReady = false; _isLoadingInter = false; _loadInter();
            },
          );
        },
        onAdFailedToLoad: (e) {
          _interReady = false; _isLoadingInter = false;
          debugPrint('[Ads] Interstitial failed: $e — retrying 25s');
          Future.delayed(const Duration(seconds: 25), _loadInter);
        },
      ),
    );
  }

  /// Called on every player death.
  /// Fires interstitial every [_interFreq] deaths automatically.
  void onPlayerDied() {
    _deathCount++;
    debugPrint('[Ads] Death #$_deathCount');
    if (_deathCount % _interFreq == 0 && _interReady) {
      debugPrint('[Ads] Firing interstitial (death #$_deathCount)');
      _inter?.show();
    }
  }

  // ── REWARDED ───────────────────────────────────────────────────────────────
  void _loadRewarded() {
    if (_isLoadingRewarded) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request:  const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded       = ad;
          _rewardReady    = true;
          _isLoadingRewarded = false;
          debugPrint('[Ads] Rewarded ready');
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (e) {
          _rewardReady = false; _isLoadingRewarded = false;
          debugPrint('[Ads] Rewarded failed: $e — retrying 25s');
          Future.delayed(const Duration(seconds: 25), _loadRewarded);
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardReady && _rewarded != null;

  void showRewarded({
    required VoidCallback onEarned,
    required VoidCallback onFailed,
  }) {
    if (!_rewardReady || _rewarded == null) { onFailed(); return; }
    _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose(); _rewardReady = false; _loadRewarded(); // immediately reload
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose(); _rewardReady = false; _isLoadingRewarded = false;
        _loadRewarded(); onFailed();
      },
    );
    _rewarded!.show(onUserEarnedReward: (_, __) => onEarned());
  }

  void dispose() {
    _banner?.dispose(); _inter?.dispose(); _rewarded?.dispose();
  }
}
