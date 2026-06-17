You are a senior Flutter engineer.

I already have a Flutter app called "PDF Toolkit" with 3 features:
1. Image → PDF
2. Merge PDF
3. Compress PDF

Now I want to integrate Google Mobile Ads (AdMob) into the app in a production-ready way.

========================================================
REQUIREMENTS
========================================================

1. Add AdMob integration using google_mobile_ads package.

2. Create a clean AdService class with:
   - Rewarded Ads
   - Interstitial Ads
   - Banner Ads
   - Proper loading, caching, retry logic
   - Null safety handling

3. Use TEST AD UNIT IDS (Google test IDs), not real ones.

4. Initialize AdMob in main.dart properly.

========================================================
MONETIZATION LOGIC (VERY IMPORTANT)
========================================================

Rewarded Ads MUST be shown before unlocking these actions:

- Export Image → PDF
- Merge PDF
- Compress PDF

Flow:
User clicks action → Show rewarded ad → If user watches → execute action → generate file → save locally

If ad is not ready, allow fallback execution but still log it.

========================================================
INTERSTITIAL ADS

Show interstitial ads:
- When user returns to home screen
- After completing a PDF operation (optional cooldown to avoid spam)
- On feature switching

Must not break UX.

========================================================
BANNER ADS

- Show banner ad ONLY on Home screen bottom
- Do not block UI
- Must be safe and not crash if ad fails

========================================================
ARCHITECTURE

Create a reusable structure:

/lib/core/ads/ad_service.dart
/lib/core/ads/ad_widgets.dart (optional)
/main.dart initialization

Keep code clean and production-ready.

========================================================
INTEGRATION RULE

You MUST modify existing feature code so that:

ImageToPdfService.export()
MergePdfService.merge()
CompressPdfService.compress()

are wrapped with Rewarded Ad logic.

========================================================
QUALITY REQUIREMENTS

- No mock code
- No pseudo logic
- Handle all null / loading / failed ad cases
- Must be ready to run on Android
- Clean, maintainable code
- Follow Flutter best practices

========================================================
OUTPUT

Give me:
1. Full AdService class
2. main.dart initialization changes
3. Example integration for 3 features
4. Banner widget implementation for Home screen