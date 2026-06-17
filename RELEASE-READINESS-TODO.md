# PDF Toolkit — Release Readiness TODO

> Master action list from the production review (score: 58/100 — NOT READY).
> We solve these **one by one**. Tick `[x]` as we finish each.
> Legend: 🔴 blocker · 🟠 required before submit · 🟢 quality/nice-to-have.

**Progress:** 2 / 13 done

---

## 🔴 GROUP A — HARD BLOCKERS (app rejected / broken without these)

### A1. Change applicationId off `com.example.*`
- [x] Status: **DONE** — id = `com.dongpv.pdftoolkit`
- Problem: `applicationId = "com.example.pdf_toolkit"` — Google Play **rejects** any `com.example.*`.
- File: [android/app/build.gradle.kts](android/app/build.gradle.kts) (`namespace` + `applicationId`)
- Done: updated both fields → `com.dongpv.pdftoolkit`; moved `MainActivity.kt` to new package; removed old `com/example`; verified build + install on emulator.

### A2. Replace AdMob test IDs with real IDs
- [ ] Status: **TODO**
- Problem: test App ID in manifest + test unit IDs in code.
- Files: [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml), [ad_service.dart](lib/services/ad_service.dart)
- Action: create AdMob app + ad units → put real **App ID** in manifest; pass real **unit IDs** via `--dart-define` (ADMOB_BANNER_ID / ADMOB_INTERSTITIAL_ID / ADMOB_REWARDED_ID).
- ✅ Done when: release build serves real ads; debug still uses test ads.

### A3. Release signing (upload keystore)
- [ ] Status: **TODO**
- Problem: release currently signed with the debug key.
- Files: `android/app/build.gradle.kts`, `android/key.properties` (new, not committed)
- Action: create keystore (`keytool`), wire `signingConfigs.release` from `key.properties`.
- ✅ Done when: `flutter build appbundle --release` produces a properly signed AAB.

### A4. Custom app icon
- [x] Status: **DONE**
- Problem: still the default Flutter icon → looks unfinished, low Play CTR.
- Done: programmatic icon generator [tool/generate_icon.dart](tool/generate_icon.dart) (blue rounded bg + folded document + accent line); `flutter_launcher_icons` configured in [pubspec.yaml](pubspec.yaml) → default + adaptive icons generated; verified on emulator.
- Note: for the **512×512 Play Store listing icon**, reuse `assets/icon/icon.png` (upscale/export to 512).

---

## 🟠 GROUP B — COMPLIANCE & STORE (required before submitting)

### B1. GDPR / UMP consent for ads
- [ ] Status: **TODO**
- Problem: no consent flow; required for EEA/UK users with personalized ads (Europe is a target market).
- File: [ad_service.dart](lib/services/ad_service.dart) + `main.dart`
- Action: integrate Google UMP (`ConsentInformation` / `ConsentForm` via `google_mobile_ads`); request consent before loading ads.
- ✅ Done when: EEA users see a consent form; ads load only after consent resolved.

### B2. Host the Privacy Policy publicly
- [ ] Status: **TODO**
- Problem: policy drafted but not on a public URL.
- File: [PRIVACY-POLICY.md](PRIVACY-POLICY.md)
- Action: fill placeholders, host (GitHub Pages / Google Sites), get HTTPS URL.
- ✅ Done when: URL opens publicly; ready to paste into Console.

### B3. Design store screenshots + feature graphic
- [ ] Status: **TODO**
- Problem: captions written, but no actual images.
- Files: [ASO-PLAY-STORE-ASSETS.md](ASO-PLAY-STORE-ASSETS.md) (captions §5, slogan §6)
- Action: design 4–8 phone screenshots (1080×1920) + feature graphic (1024×500) in Canva/Figma.
- ✅ Done when: assets exported and meet Play specs.

### B4. Complete Play Console listing + forms
- [ ] Status: **TODO**
- Action: paste Title/Short/Full description; complete Data Safety, Content rating (IARC), Target audience (13+), Ads = yes, Privacy policy URL.
- Refs: [ASO-PLAY-STORE-ASSETS.md](ASO-PLAY-STORE-ASSETS.md), [PRIVACY-POLICY.md](PRIVACY-POLICY.md) Part 2, [PLAY-STORE-SUBMISSION-CHECKLIST.md](PLAY-STORE-SUBMISSION-CHECKLIST.md)
- ✅ Done when: all "App content" sections are green in Console.

---

## 🟢 GROUP C — QUALITY / RISK REDUCTION (recommended)

### C1. Move heavy PDF work off the main isolate
- [ ] Status: **TODO**
- Problem: image→PDF, merge, and compress (rasterize) run on the UI isolate → large files may jank/ANR.
- Files: [image_to_pdf_service.dart](lib/services/image_to_pdf_service.dart), [pdf_merge_service.dart](lib/services/pdf_merge_service.dart), [pdf_compress_service.dart](lib/services/pdf_compress_service.dart)
- Action: offload CPU-bound work via `compute()`/isolates where the libs allow; test with a 50–100 page PDF.
- ✅ Done when: large files process without ANR; UI stays responsive.

### C2. Compress quality tradeoff UX
- [ ] Status: **TODO**
- Problem: compress rasterizes pages → vector text becomes image (no text selection, blur on deep zoom).
- File: [compress_pdf_screen.dart](lib/screens/compress_pdf_screen.dart)
- Action: add a short note/hint in the UI ("best for scanned/photo PDFs"); optionally keep an original copy.
- ✅ Done when: user is informed of the tradeoff before compressing.

### C3. Test large / edge-case files end-to-end
- [ ] Status: **TODO**
- Action: test empty selection, cancel picker, corrupt PDF, very large PDF, no-app-to-open, on Android 7–15.
- ✅ Done when: no crashes; graceful messages everywhere.

### C4. (Optional) Crash & analytics reporting
- [ ] Status: **TODO**
- Action: consider Firebase Crashlytics for post-launch stability monitoring (affects Play ranking).
- ✅ Done when: crashes are visible in a dashboard.

### C5. Closed testing (new accounts only)
- [ ] Status: **TODO**
- Problem: new personal dev accounts must run closed test with **12+ testers for 14 days** before production.
- Action: set up internal/closed track early; recruit testers.
- ✅ Done when: 14-day requirement satisfied; production access granted.

---

## SUGGESTED ORDER
1. A1 → A2 → A3 → A4 (unblock build + identity)
2. B1 → B2 → B3 → B4 (compliance + store)
3. C1 → C2 → C3 (quality), then C4, C5

> We'll tackle them top-down. Tell me which to start with — recommended: **A1**.
