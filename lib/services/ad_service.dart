import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Central AdMob manager.
///
/// Exposes [loadAds], [showRewardedAd] and [showInterstitialAd] plus a
/// [createBannerAd] factory for the home screen banner. Production ad unit IDs
/// are injected at build time via `--dart-define`; debug builds and missing
/// IDs fall back to Google's official **test** ad units.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _initialized = false;

  // --- Ad unit IDs ----------------------------------------------------------
  //
  // Real unit IDs are injected at build time via --dart-define so no secret or
  // production ID lives in source. When a real ID is not provided we fall back
  // to Google's official **test** IDs, which are also forced in debug builds to
  // avoid serving (and accidentally clicking) live ads during development.

  static const _realBannerId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _realInterstitialId =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const _realRewardedId = String.fromEnvironment('ADMOB_REWARDED_ID');

  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIdIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIdIos = 'ca-app-pub-3940256099942544/1712485313';

  static String _resolve(String real, String testAndroid, String testIos) {
    if (!kDebugMode && real.isNotEmpty) return real;
    return Platform.isIOS ? testIos : testAndroid;
  }

  static String get _bannerUnitId =>
      _resolve(_realBannerId, _testBannerId, _testBannerIdIos);

  static String get _interstitialUnitId => _resolve(
      _realInterstitialId, _testInterstitialId, _testInterstitialIdIos);

  static String get _rewardedUnitId =>
      _resolve(_realRewardedId, _testRewardedId, _testRewardedIdIos);

  // --- Lifecycle ------------------------------------------------------------

  /// Initializes the Mobile Ads SDK. Call once from `main()`.
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Preloads a rewarded and an interstitial ad so they are ready on demand.
  void loadAds() {
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          if (kDebugMode) debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          if (kDebugMode) debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // --- Rewarded -------------------------------------------------------------

  /// Shows a rewarded ad before a gated action.
  ///
  /// Returns `true` if the user earned the reward **or** no ad was available
  /// (so functionality is never blocked by ad-loading issues), and `false`
  /// only if the ad was shown but dismissed before the reward was earned.
  Future<bool> showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      // No ad ready — don't block the user, just preload for next time.
      _loadRewardedAd();
      return true;
    }
    _rewardedAd = null;

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) => earned = true,
    );
    return earned;
  }

  // --- Interstitial ---------------------------------------------------------

  static const int _interstitialEvery = 2;
  int _opsSinceInterstitial = 0;

  /// Call after a successful gated operation (export/merge/compress). Shows an
  /// interstitial only once every [_interstitialEvery] operations, because a
  /// rewarded ad already runs *before* each operation — this avoids ad fatigue.
  Future<void> maybeShowInterstitial() async {
    _opsSinceInterstitial++;
    if (_opsSinceInterstitial < _interstitialEvery) return;
    _opsSinceInterstitial = 0;
    await showInterstitialAd();
  }

  /// Shows an interstitial ad if one is ready; no-op otherwise.
  Future<void> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitialAd();
      return;
    }
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    await ad.show();
  }

  // --- Banner ---------------------------------------------------------------

  /// Creates (but does not load) a banner ad for the home screen.
  BannerAd createBannerAd({
    void Function()? onLoaded,
    void Function()? onFailed,
  }) {
    return BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) debugPrint('Banner ad failed to load: $error');
          onFailed?.call();
        },
      ),
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}
