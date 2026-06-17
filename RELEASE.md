# PDF Toolkit — Production Release Guide

This document covers preparing, configuring, and building **PDF Toolkit** for a
Google Play release (Android App Bundle / AAB).

---

## 1. One-time native scaffolding

The repository contains `lib/` and `pubspec.yaml` but not the native platform
folders. Generate them once (this preserves existing Dart code):

```bash
cd pdf-app
flutter create .
flutter pub get
```

---

## 2. Required native configuration

### 2.1 AdMob App ID — **mandatory** (app crashes on launch without it)

`android/app/src/main/AndroidManifest.xml`, inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

Use your real AdMob **App ID** for release. For testing, Google's sample App ID
is `ca-app-pub-3940256099942544~3347511713`.

### 2.2 App identity

- Set the application ID in `android/app/build.gradle`:
  `applicationId "com.yourcompany.pdftoolkit"`
- Set `minSdkVersion` to **23** or higher (required by `google_mobile_ads`).
- Update the app label in `AndroidManifest.xml` (`android:label="PDF Toolkit"`).

---

## 3. Build-time configuration (no secrets in source)

Ad unit IDs and the Syncfusion license are injected via `--dart-define`. With
none provided, the app uses test ads and shows the Syncfusion trial banner.

| Define | Purpose |
| --- | --- |
| `ADMOB_BANNER_ID` | Real banner unit ID |
| `ADMOB_INTERSTITIAL_ID` | Real interstitial unit ID |
| `ADMOB_REWARDED_ID` | Real rewarded unit ID |
| `SYNCFUSION_LICENSE_KEY` | Removes the PDF trial watermark/banner |

> Real ad IDs are only used in **release** builds; debug builds always use test
> ads (see `AdService._resolve`).

### Syncfusion license

`syncfusion_flutter_pdf` requires a license key in production, otherwise
generated PDFs carry a trial notice. A **free Community License** is available
for qualifying individuals/small businesses at
<https://www.syncfusion.com/products/communitylicense>. Register the key with
`--dart-define=SYNCFUSION_LICENSE_KEY=...`; `main.dart` registers it at startup.

---

## 4. Signing

Create a keystore and reference it from Gradle.

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` (do **not** commit):

```properties
storePassword=********
keyPassword=********
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Wire it into `android/app/build.gradle` (`signingConfigs.release` reading
`key.properties`) and set `buildTypes.release.signingConfig signingConfigs.release`.

---

## 5. Build the App Bundle (AAB)

```bash
flutter clean
flutter pub get

flutter build appbundle --release \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-..../.... \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-..../.... \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-..../.... \
  --dart-define=SYNCFUSION_LICENSE_KEY=YOUR_KEY
```

Output: `build/app/outputs/bundle/release/app-release.aab` — upload this to the
Play Console.

To test the release build on a device first:

```bash
flutter build apk --release --dart-define=...   # same defines
flutter install
```

---

## 6. Pre-submission checklist (already handled in code)

- [x] No `print` / unguarded `debugPrint` (ad logs are wrapped in `kDebugMode`).
- [x] No `TODO` / `FIXME` / mock logic in `lib/`.
- [x] Sound null safety (Dart SDK `^3.5`); no unchecked force-unwraps.
- [x] All feature work runs offline; PDFs saved to app documents dir (no runtime
      storage permission needed).
- [x] `const` constructors and `ListView/GridView.builder` used for lists.
- [x] Rewarded-ad gating before export/merge/save; banner on home screen only.

Still verify before shipping:

- [ ] Real AdMob App ID + unit IDs configured.
- [ ] Syncfusion license key supplied.
- [ ] App icon and splash set (`flutter_launcher_icons` / `flutter_native_splash`).
- [ ] Version bumped in `pubspec.yaml` (`version: 1.0.0+1`).
- [ ] `flutter analyze` clean and `flutter test` passing.
- [ ] Play Store privacy policy mentions AdMob (advertising ID) usage.

---

## 7. Common issues & fixes

| Symptom | Cause | Fix |
| --- | --- | --- |
| App crashes immediately on launch | Missing AdMob `APPLICATION_ID` meta-data | Add it to `AndroidManifest.xml` (§2.1). |
| Generated PDFs show a Syncfusion trial banner | No license registered | Provide `SYNCFUSION_LICENSE_KEY` via `--dart-define`. |
| `file_picker` build error or missing files | Plugin needs platform setup | Re-run `flutter create .`, then `flutter clean && flutter pub get`. |
| Ads never show in release | Using test IDs / new AdMob account warming up | Confirm real IDs are passed; new units can take hours to fill. |
| `Execution failed ... minSdkVersion` | `google_mobile_ads` needs SDK 23+ | Set `minSdkVersion 23` in `android/app/build.gradle`. |
| `MissingPluginException` after adding a package | Stale build | `flutter clean && flutter pub get`, full rebuild. |
| Release APK installs but white screen | Tree-shaking/obfuscation or missing init | Test with `flutter build apk --release`; check `flutter logs`. |
| R8/ProGuard strips a plugin class | Aggressive minification | Add keep rules in `android/app/proguard-rules.pro` if a release-only crash appears. |
| `image_picker` returns nothing on Android 13+ | Photo Picker permissions | No action needed — the OS Photo Picker grants scoped access automatically. |
| Large PDFs/many images briefly freeze UI | Heavy work on the UI isolate | Acceptable for typical files; for very large jobs move generation to a background isolate (`compute`). |

---

## 8. Performance notes

- Lists use lazy builders; widgets are `const` where possible.
- PDF generation, merging and compression are CPU-bound and currently run on the
  main isolate behind a progress indicator. For unusually large inputs, the
  service classes (`ImageToPdfService`, `PdfMergeService`, `PdfCompressService`)
  are isolated enough to be moved onto `compute()` without UI changes.
- Release builds are AOT-compiled and tree-shaken automatically by
  `flutter build appbundle --release`.
