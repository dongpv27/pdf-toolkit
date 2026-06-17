Add Google AdMob integration to Flutter app.

Requirements:
- Rewarded Ads
- Interstitial Ads
- Banner Ads (home screen only)

Rules:
- Rewarded Ad must be shown before:
  - exporting PDF
  - merging PDF
  - saving compressed PDF

Create:
- AdService class
- reusable functions:
  - showRewardedAd()
  - showInterstitialAd()
  - loadAds()

Use google_mobile_ads package.

Ensure ads are properly initialized in main.dart.