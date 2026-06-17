# PDF Toolkit — Google Play Submission Checklist

> End-to-end checklist to take the app from code → live on Google Play.
> Order matters: do **Section A (blockers)** before anything else.
> Companion docs: [PRIVACY-POLICY.md](PRIVACY-POLICY.md) ·
> [RELEASE.md](RELEASE.md) · [ASO-PLAY-STORE-ASSETS.md](ASO-PLAY-STORE-ASSETS.md)

---

## 🔴 SECTION A — HARD BLOCKERS (app will be rejected without these)

- [ ] **Change application ID off `com.example.*`.**
      Currently `com.example.pdf_toolkit` — Play **rejects** `com.example.*`.
      In [android/app/build.gradle.kts](android/app/build.gradle.kts) set both
      `namespace` and `applicationId` to e.g. `com.yourcompany.pdftoolkit`.
      ⚠️ The package name is **permanent** once published — choose carefully.
- [ ] **Real AdMob App ID** in `AndroidManifest.xml` (replace the test
      `ca-app-pub-3940256099942544~3347511713`).
- [ ] **Real AdMob ad unit IDs** via `--dart-define` at build time
      (`ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`, `ADMOB_REWARDED_ID`) — see
      [ad_service.dart](lib/services/ad_service.dart) / [RELEASE.md](RELEASE.md).
- [ ] **Privacy Policy hosted at a public HTTPS URL** (see PRIVACY-POLICY.md).
- [ ] **Upload keystore created & app signed** (release signing config, not
      debug). See RELEASE.md §4.
- [ ] **Signed AAB builds** clean: `flutter build appbundle --release` with all
      dart-defines.

---

## 🟡 SECTION B — APP BUILD & QUALITY

- [ ] App ID, app name ("PDF Toolkit"), and icon finalized.
- [ ] `version` bumped in [pubspec.yaml](pubspec.yaml) (`1.0.0+1` → use code `1`).
- [ ] `flutter analyze` → no issues. (Currently ✅ clean.)
- [ ] `flutter test` passes.
- [ ] Test the **release** build on a real device: `flutter build apk --release` + install.
- [ ] Verify all 3 features work offline on a physical phone (Android 7–15).
- [ ] Verify ads load with **real** IDs (rewarded before export/merge/save; banner on home).
- [ ] No debug logs in release (✅ guarded with `kDebugMode`).
- [ ] `minSdk` ≥ 23 (✅), `targetSdk` = current Play requirement (35 for 2025).
- [ ] No prohibited permissions (✅ no MANAGE_EXTERNAL_STORAGE / camera / contacts).
- [ ] App icon: adaptive icon set (foreground + background); test on launcher.

---

## 🟢 SECTION C — STORE LISTING (copy from ASO docs)

- [ ] **App name:** `PDF Converter: Image to PDF` (≤30 chars).
- [ ] **Short description** (≤80) — from ASO-PLAY-STORE-ASSETS.md.
- [ ] **Full description** (≤4000) — from ASO-PLAY-STORE-ASSETS.md.
- [ ] **App icon:** 512×512 PNG, 32-bit, ≤1 MB.
- [ ] **Feature graphic:** 1024×500 PNG/JPG (slogan from ASO doc).
- [ ] **Phone screenshots:** min 2, recommended **4–8**; 16:9 or 9:16;
      1080×1920 ideal. Use the 6 captions from the ASO doc.
- [ ] (Optional) **7-inch & 10-inch tablet** screenshots if supporting tablets.
- [ ] (Optional) **Promo video** (YouTube URL).
- [ ] **Category:** Tools. **Tags:** PDF, Document, File converter.
- [ ] **Contact details:** email (required), website (optional), phone (optional).

---

## 🔵 SECTION D — POLICY & APP CONTENT (Console → App content)

- [ ] **Privacy policy URL** entered.
- [ ] **Ads:** "Yes, my app contains ads."
- [ ] **App access:** "All functionality available without restrictions"
      (no login required).
- [ ] **Content rating:** complete the IARC questionnaire (utility app, no
      objectionable content → expect "Everyone / PEGI 3"). Ads = yes.
- [ ] **Target audience & content:** select age groups **13+** (not children);
      confirm app is not designed for children → avoids Families Policy.
- [ ] **Data safety:** complete per [PRIVACY-POLICY.md](PRIVACY-POLICY.md) Part 2.
- [ ] **Government apps:** No. **Financial features:** No. **Health:** No.
- [ ] **News app:** No. **COVID-19 contact tracing:** No.
- [ ] **Data deletion:** no account → state managed via device ad-ID reset.
- [ ] **Advertising ID declaration:** Advertising (AD_ID permission present).

---

## ⚙️ SECTION E — RELEASE SETUP (Console → Release)

- [ ] **Play App Signing:** enabled (let Google manage the app signing key;
      you keep the upload key).
- [ ] **Pricing:** Free.
- [ ] **Countries/regions:** select target markets (US, India, SEA, Europe — or
      "All").
- [ ] **Internal testing track:** upload AAB, test with your own account first.
- [ ] **Closed testing → Production.**
      ⚠️ **New personal developer accounts** (created after Nov 2023) must run a
      **closed test with at least 12 testers for 14 continuous days** before they
      can apply for production access. Plan for this — it gates your launch date.
- [ ] **Pre-launch report:** review automated device test results & warnings.
- [ ] **Release notes ("What's New"):** from
      [ASO-LOCALIZED-LISTINGS.md](ASO-LOCALIZED-LISTINGS.md).
- [ ] **Roll out** to Production (consider staged rollout: 20% → 50% → 100%).

---

## 🧾 SECTION F — DEVELOPER ACCOUNT (one-time)

- [ ] Google Play Developer account registered (**$25 one-time fee**).
- [ ] Account identity verification completed (D-U-N-S/ID as prompted).
- [ ] Payments profile set up (even for free apps, required for account).
- [ ] Developer name & contact email verified.

---

## 📦 SECTION G — BUILD COMMAND (copy-paste)

```bash
flutter clean
flutter pub get

flutter build appbundle --release \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/XXXX \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXX/XXXX \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-XXXX/XXXX
```
Output → `build/app/outputs/bundle/release/app-release.aab` (upload this).

---

## ✅ FINAL PRE-SUBMIT SANITY PASS

- [ ] Installed the **exact AAB/APK** you're uploading on a clean device and
      opened every screen.
- [ ] Real ads showed (or non-personalized fallback) — no test ads in release.
- [ ] Privacy policy URL opens publicly (incognito test).
- [ ] App name, icon, screenshots match and look professional at thumbnail size.
- [ ] Data safety answers match actual app behavior (AdMob only).
- [ ] No crashes in the pre-launch report.
- [ ] Version code is higher than any previously uploaded build.

---

## CURRENT STATUS (this project)

| Item | Status |
|---|---|
| Code compiles / `flutter analyze` | ✅ clean |
| Runs on emulator | ✅ verified |
| AdMob integrated (test IDs) | ✅ |
| Privacy policy text | ✅ drafted (needs hosting) |
| Data safety answers | ✅ drafted |
| **applicationId off `com.example`** | ❌ TODO (blocker) |
| **Real AdMob IDs** | ❌ TODO (blocker) |
| **Upload keystore + signing** | ❌ TODO (blocker) |
| Store graphics (icon/feature/screens) | ❌ TODO (design) |
| Closed testing (12 testers/14 days) | ❌ TODO (if new account) |
