// lib/services/ad_service.dart
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
  bool _interReady   = false;
  bool _rewardReady  = false;
  bool _bannerReady  = false;
  int  _deathCount   = 0;

  String get _bannerId   => Platform.isIOS ? kBannerIdIOS   : kBannerIdAndroid;
  String get _interId    => Platform.isIOS ? kInterIdIOS    : kInterIdAndroid;
  String get _rewardedId => Platform.isIOS ? kRewardedIdIOS : kRewardedIdAndroid;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadBanner(); _loadInter(); _loadRewarded();
  }

  // ── Banner ──────────────────────────────────────────────────────────────────
  BannerAd? get bannerAd => _bannerReady ? _banner : null;
  void _loadBanner() {
    _banner = BannerAd(
      adUnitId: _bannerId, size: AdSize.banner, request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { _bannerReady = true; debugPrint('[Ads] Banner loaded'); },
        onAdFailedToLoad: (ad, e) { ad.dispose(); _bannerReady = false;
          Future.delayed(const Duration(seconds: 60), _loadBanner); },
      ),
    )..load();
  }

  // ── Interstitial ────────────────────────────────────────────────────────────
  void _loadInter() {
    InterstitialAd.load(
      adUnitId: _interId, request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _inter = ad; _interReady = true;
          ad.setImmersiveMode(true);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) { a.dispose(); _interReady = false; _loadInter(); },
            onAdFailedToShowFullScreenContent: (a, e) { a.dispose(); _interReady = false; _loadInter(); },
          );
        },
        onAdFailedToLoad: (_) { _interReady = false;
          Future.delayed(const Duration(seconds: 30), _loadInter); },
      ),
    );
  }

  void onPlayerDied() {
    _deathCount++;
    if (_deathCount % kInterEveryNDeaths == 0 && _interReady) _inter?.show();
  }

  // ── Rewarded ────────────────────────────────────────────────────────────────
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId, request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _rewarded = ad; _rewardReady = true; ad.setImmersiveMode(true); },
        onAdFailedToLoad: (_) { _rewardReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewarded); },
      ),
    );
  }

  bool get isRewardedReady => _rewardReady;

  void showRewarded({required VoidCallback onEarned, required VoidCallback onFailed}) {
    if (!_rewardReady || _rewarded == null) { onFailed(); return; }
    _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) { a.dispose(); _rewardReady = false; _loadRewarded(); },
      onAdFailedToShowFullScreenContent: (a, e) { a.dispose(); _rewardReady = false; _loadRewarded(); onFailed(); },
    );
    _rewarded!.show(onUserEarnedReward: (_, __) => onEarned());
  }

  void dispose() { _banner?.dispose(); _inter?.dispose(); _rewarded?.dispose(); }
}
